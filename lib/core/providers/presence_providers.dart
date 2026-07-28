import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/providers/settings_providers.dart';
import '../constants/firestore_paths.dart';
import 'firebase_providers.dart';

/// Heartbeats `lastActiveAt` onto the signed-in user's own profile doc
/// every 60s while the authenticated shell is mounted and notifications
/// are enabled, plus once immediately on every foreground resume (see
/// `pingPresenceNow`, called from `app.dart`'s `didChangeAppLifecycleState`).
///
/// This is the client half of the FCM push-notification dedup mechanism:
/// Cloud Functions treat a recent `lastActiveAt` as "the local notification
/// listener is presumably still running" and skip sending a redundant push
/// (see `functions/src/lib/presence.ts`). A stale or missing value means
/// the app is closed, so a crossing needs a push instead.
class _PresenceHeartbeat extends Notifier<void> {
  Timer? _timer;

  @override
  void build() {
    ref.onDispose(() => _timer?.cancel());

    final enabled =
        ref.watch(userPreferencesProvider).value?.notificationsEnabled ?? false;
    _timer?.cancel();
    _timer = null;
    if (!enabled) return;

    _writeHeartbeat(
      readAuth: () => ref.read(firebaseAuthProvider),
      readFirestore: () => ref.read(firestoreProvider),
    );
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _writeHeartbeat(
        readAuth: () => ref.read(firebaseAuthProvider),
        readFirestore: () => ref.read(firestoreProvider),
      ),
    );
  }
}

final _presenceHeartbeatProvider = NotifierProvider<_PresenceHeartbeat, void>(
  _PresenceHeartbeat.new,
);

/// Call once from `HomeShellScreen.build`, alongside the existing alert
/// watchers — starts (or stops) the periodic heartbeat as
/// `notificationsEnabled` changes.
void watchPresenceHeartbeat(WidgetRef ref) =>
    ref.watch(_presenceHeartbeatProvider);

/// Call on every app-resume (see `app.dart`) so presence looks fresh the
/// instant the user reopens the app, rather than waiting up to 60s for the
/// next periodic tick — closes the gap where a Cloud Function could fire a
/// redundant push in the brief window right after resume.
void pingPresenceNow(WidgetRef ref) {
  if (kIsWeb) return;
  final enabled =
      ref.read(userPreferencesProvider).value?.notificationsEnabled ?? false;
  if (!enabled) return;
  _writeHeartbeat(
    readAuth: () => ref.read(firebaseAuthProvider),
    readFirestore: () => ref.read(firestoreProvider),
  );
}

/// Takes closures rather than a `ref` directly for two reasons: `Ref` (used
/// by the `Notifier` above) and `WidgetRef` (used by `pingPresenceNow`,
/// called from a plain widget) share no common assignable type in this
/// Riverpod version — same reason `core/utils/analytics_logger.dart`'s
/// `logAnalyticsEvent` takes a closure. It also means the provider reads
/// happen *inside* this function's own try/catch: `FirebaseAuth.instance`/
/// `FirebaseFirestore.instance` throw synchronously with no Firebase app
/// (e.g. in a test), and that has to be caught here, not left to whatever
/// (if anything) wraps the call site.
void _writeHeartbeat({
  required FirebaseAuth Function() readAuth,
  required FirebaseFirestore Function() readFirestore,
}) {
  try {
    final uid = readAuth().currentUser?.uid;
    if (uid == null) return;
    readFirestore()
        .collection(FirestorePaths.users)
        .doc(uid)
        .set({
          FirestorePaths.lastActiveAtField: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((_) {
          // Fire-and-forget — a dropped heartbeat just means the next
          // periodic tick (or resume) tries again; never worth surfacing.
        });
  } catch (_) {
    // Best-effort — see this function's doc comment.
  }
}
