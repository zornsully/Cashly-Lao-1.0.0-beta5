import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The notification channels Cashly uses. `FlutterLocalNotificationsPlugin()`
/// is itself a singleton (the package's own factory constructor always
/// returns the same instance), so calling [initializeLocalNotifications] once
/// in `main()` before `runApp` is enough — this provider and that call share
/// the identical plugin instance without needing a `ProviderContainer`
/// pre-`runApp`.
const _budgetAlertsChannelId = 'budget_alerts';
const _budgetAlertsChannelName = 'Budget & balance alerts';
const _budgetAlertsChannelDescription =
    'Warns when a budget is exceeded or an account balance goes negative.';

const budgetAlertsChannel = AndroidNotificationChannel(
  _budgetAlertsChannelId,
  _budgetAlertsChannelName,
  description: _budgetAlertsChannelDescription,
  importance: Importance.high,
);

const _goalRemindersChannelId = 'goal_reminders';
const _goalRemindersChannelName = 'Savings goal reminders';
const _goalRemindersChannelDescription =
    'Reminds you when a savings goal\'s auto-contribution is due.';

const goalRemindersChannel = AndroidNotificationChannel(
  _goalRemindersChannelId,
  _goalRemindersChannelName,
  description: _goalRemindersChannelDescription,
  importance: Importance.high,
);

final localNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

/// Deterministic tray-notification ID for a given alert type + entity ID.
/// Shared by every local-alert call site *and* by FCM push display
/// (`fcm_background_handler.dart`/`fcm_message_providers.dart`) so a local
/// alert and a push for the same underlying crossing collapse into one
/// notification (Android replaces-by-ID) rather than stacking two.
int notificationIdFor(String type, String id) => '$type-$id'.hashCode;

/// Called once from `main()`, before `runApp` — sets up the platform
/// integration and the one channel this app uses. Does not request the
/// Android 13+ POST_NOTIFICATIONS runtime permission; that's requested
/// separately, only when the user actually turns the Settings toggle on
/// (see [requestNotificationPermission]), not unprompted at every launch.
Future<void> initializeLocalNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings: settings);
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(budgetAlertsChannel);
  await android?.createNotificationChannel(goalRemindersChannel);
}

/// Requests the Android 13+ runtime notification permission. Returns `true`
/// on platforms with no such explicit runtime prompt (older Android, or
/// where the plugin has no Android implementation to resolve — e.g. running
/// in a widget test).
Future<bool> requestNotificationPermission(
  FlutterLocalNotificationsPlugin plugin,
) async {
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (android == null) return true;
  return await android.requestNotificationsPermission() ?? false;
}

/// Shows a notification on [channel] (one of the constants above).
Future<void> showLocalNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String title,
  required String body,
  required AndroidNotificationChannel channel,
}) {
  final androidDetails = AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.high,
    priority: Priority.high,
  );
  final details = NotificationDetails(android: androidDetails);
  return plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
  );
}
