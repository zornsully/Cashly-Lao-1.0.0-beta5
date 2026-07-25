import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/presentation/providers/fcm_token_providers.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';
import 'firebase_providers.dart';

/// Registers this device's FCM token whenever notifications are (or
/// become) enabled — one reactive hook covers both "the user just flipped
/// the Settings toggle on" and "returning user, already on from a previous
/// session," exactly like `budget_alert_providers.dart`/
/// `goal_reminder_providers.dart` trust the same flag without a check of
/// their own. Also subscribes to `onTokenRefresh` for as long as
/// notifications stay enabled (FCM can rotate a device's token at any
/// time), and unregisters on toggle-off.
///
/// Every failure here is unconditionally swallowed, never surfaced to the
/// user: a failed *register* just leaves this session local-only-covered
/// (identical to today's behavior for every user — no regression); a
/// failed *unregister* is cleanup only, made safe by the fact that Cloud
/// Functions gate every send on `notificationsEnabled` before ever reading
/// a token (see `functions/src/lib/evaluateAndNotify.ts`), so a stray
/// leftover token can never cause a wrongly-delivered push.
class _FcmTokenRegistration extends Notifier<void> {
  StreamSubscription<String>? _refreshSubscription;
  bool _wasEnabled = false;

  @override
  void build() {
    ref.onDispose(() => _refreshSubscription?.cancel());

    final enabled =
        ref.watch(userPreferencesProvider).value?.notificationsEnabled ??
        false;
    if (enabled == _wasEnabled) return;
    _wasEnabled = enabled;

    if (enabled) {
      unawaited(_registerCurrentToken());
      _refreshSubscription = ref
          .read(messagingProvider)
          .onTokenRefresh
          .listen((token) => unawaited(_registerToken(token)));
    } else {
      unawaited(_refreshSubscription?.cancel());
      _refreshSubscription = null;
      unawaited(_unregisterCurrentToken());
    }
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await ref.read(messagingProvider).getToken();
      if (token == null) return;
      await _registerToken(token);
    } catch (_) {
      // Best-effort — see class doc comment.
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await ref
          .read(registerFcmTokenUseCaseProvider)
          .call(token: token, platform: Platform.isIOS ? 'ios' : 'android');
    } catch (_) {
      // Best-effort — see class doc comment.
    }
  }

  Future<void> _unregisterCurrentToken() async {
    try {
      final token = await ref.read(messagingProvider).getToken();
      if (token == null) return;
      await ref.read(unregisterFcmTokenUseCaseProvider).call(token: token);
    } catch (_) {
      // Best-effort — see class doc comment.
    }
  }
}

final _fcmTokenRegistrationProvider =
    NotifierProvider<_FcmTokenRegistration, void>(_FcmTokenRegistration.new);

void watchFcmTokenRegistration(WidgetRef ref) =>
    ref.watch(_fcmTokenRegistrationProvider);
