import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../utils/fcm_notification_content.dart';
import 'local_notifications_providers.dart';

final _onMessageStreamProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessage;
});

final _onMessageOpenedAppStreamProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessageOpenedApp;
});

/// Wires up push-notification display/reaction for the current app
/// session. Call once from `HomeShellScreen.build`, alongside the existing
/// local-alert watchers (`watchBudgetAndBalanceAlerts`/
/// `watchGoalReminders`) — `ref.listen` calls are safe here for the same
/// reason they are there: this runs during that widget's own build, with
/// its own `WidgetRef`.
///
/// Covers the two points at which this *running* session ever sees an
/// incoming push:
/// - Foreground (`onMessage`): FCM never auto-displays while the app is in
///   the foreground, so this builds the content itself and shows it
///   through the exact same local-notification display path local alerts
///   already use (see `fcm_notification_content.dart` for why this needs
///   zero new ARB strings).
/// - Background-tap (`onMessageOpenedApp`): the user already tapped the
///   tray notification to bring the app back to the foreground — this only
///   navigates, it never redisplays what they just tapped.
///
/// Deliberately does **not** call `getInitialMessage()` (the cold-launch-
/// by-tap case): the router's own existing redirect already lands a
/// signed-in user on the Dashboard by default, so there is nothing left to
/// do with that result once the "which screen to open" question is
/// answered the same way regardless. A cheap improvement was considered —
/// pre-seeding the relevant local alert-provider's dedup set from the
/// tapped message's `id`, closing the "tap-to-open re-alerts locally" edge
/// case — but that's explicitly out of scope for this pass (see the FCM
/// plan's dedup-mechanism section) rather than an oversight.
void watchPushNotifications(WidgetRef ref, AppLocalizations l10n) {
  ref.listen(_onMessageStreamProvider, (previous, next) {
    final message = next.value;
    if (message == null) return;
    _displayForeground(ref, l10n, message);
  });

  ref.listen(_onMessageOpenedAppStreamProvider, (previous, next) {
    if (next.value == null) return;
    ref.read(appRouterProvider).go(AppRoutes.home);
  });
}

void _displayForeground(
  WidgetRef ref,
  AppLocalizations l10n,
  RemoteMessage message,
) {
  final content = buildPushNotificationContent(l10n, message.data);
  if (content == null) return;
  showLocalNotification(
    ref.read(localNotificationsPluginProvider),
    id: notificationIdFor(
      message.data['type'] as String? ?? '',
      message.data['id'] as String? ?? '',
    ),
    title: content.title,
    body: content.body,
    channel: content.channel,
  );
}
