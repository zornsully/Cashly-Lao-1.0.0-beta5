import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_language.dart';
import '../utils/fcm_notification_content.dart';
import 'local_notifications_providers.dart';

Locale _resolveLocaleFor(String? langName) {
  for (final language in AppLanguage.values) {
    if (language.name == langName) return language.locale;
  }
  return AppLanguage.english.locale;
}

/// Required top-level background message handler, registered via
/// `FirebaseMessaging.onBackgroundMessage` in `main.dart`. Runs in a
/// **separate isolate** with its own singleton space — unlike every other
/// use of `flutter_local_notifications` in this app, it needs its own
/// `initialize()` call (harmless, idempotent) rather than relying on
/// `main()`'s having already done it, since that happened in a different
/// isolate entirely.
///
/// `@pragma('vm:entry-point')` is required, not decorative: without it,
/// Android release builds can tree-shake this function away and silently
/// never invoke it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidSettings),
  );
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(budgetAlertsChannel);
  await android?.createNotificationChannel(goalRemindersChannel);

  final locale = _resolveLocaleFor(message.data['lang'] as String?);
  final l10n = await AppLocalizations.delegate.load(locale);
  final content = buildPushNotificationContent(l10n, message.data);
  if (content == null) return;

  await showLocalNotification(
    plugin,
    id: notificationIdFor(
      message.data['type'] as String? ?? '',
      message.data['id'] as String? ?? '',
    ),
    title: content.title,
    body: content.body,
    channel: content.channel,
  );
}
