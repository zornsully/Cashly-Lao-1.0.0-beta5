import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../constants/firestore_paths.dart';
import 'firebase_providers.dart';

/// Whether the signed-in user's own `users/{uid}` document — already
/// listened to elsewhere (Settings/Profile) so this adds no new Firestore
/// read pattern — was just served from the local cache or a live server
/// round-trip. `cloud_firestore` has no direct "online/offline" stream of
/// its own; [SnapshotMetadata.isFromCache] on any listened document is the
/// documented way to observe it, and it flips back to `false` the moment
/// connectivity is restored and this listener resyncs.
///
/// Explicitly watches [authStateChangesProvider] first, same reasoning as
/// `userPreferencesProvider`'s fix: this provider can be built before
/// sign-in resolves, and without watching auth state it would permanently
/// cache whatever it saw at that first build.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(true);

  return ref
      .watch(firestoreProvider)
      .collection(FirestorePaths.users)
      .doc(user.uid)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) => !snapshot.metadata.isFromCache);
});
