import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/fcm_background_handler.dart';
import 'core/providers/local_notifications_providers.dart';
import 'core/utils/platform_capabilities.dart';
import 'firebase_options.dart';

/// Redirects Auth/Firestore to the local Firebase Emulator Suite instead of
/// the real `cashly-lao` production project. Off by default in every normal
/// `flutter run`/`flutter build` — only `integration_test/` ever passes
/// this, via `--dart-define=USE_FIREBASE_EMULATOR=true`, so a plain build
/// can never accidentally touch a local emulator, and a test run can never
/// accidentally touch production. See `integration_test/README.md`.
const bool _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _configureFirestoreOfflineCache();
  if (_useFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  // Browser builds use Firebase Auth/Firestore but don't share Android's
  // local-notification channels or background-isolate delivery model.
  if (AppPlatformCapabilities.supportsCurrentNotificationBridge) {
    await initializeLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Debug builds run on developer machines, not real users — collecting
  // from them would just add noise to the dashboard.
  // Crashlytics has no Flutter web implementation, so its native error hooks
  // must stay off the browser startup path.
  if (AppPlatformCapabilities.supportsCrashReporting) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  if (AppPlatformCapabilities.supportsFirebaseAnalytics) {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
  }
  // Errors outside Flutter's own error zone (e.g. in async callbacks) don't
  // go through FlutterError.onError, so they need their own hook.

  runApp(const ProviderScope(child: CashlyApp()));
}

/// Keeps a signed-in person's finance data available while their connection
/// drops and lets Firestore safely send queued writes once they are back
/// online. On web the multiple-tab manager also prevents one Cashly tab from
/// evicting another tab's local cache.
///
/// This must run before the app creates Firestore listeners or writes. If a
/// browser does not allow persistent storage (for example private browsing),
/// Firestore remains usable with its normal in-memory cache instead of
/// preventing the person from opening Cashly.
void _configureFirestoreOfflineCache() {
  try {
    FirebaseFirestore.instance.settings = kIsWeb
        ? const Settings(
            persistenceEnabled: true,
            webPersistentTabManager: WebPersistentMultipleTabManager(),
          )
        : const Settings(persistenceEnabled: true);
  } on FirebaseException catch (error) {
    debugPrint('Firestore persistent cache unavailable: ${error.code}');
  }
}
