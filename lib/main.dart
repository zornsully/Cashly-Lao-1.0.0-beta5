import 'dart:async';

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
import 'core/startup/cashly_startup_app.dart';
import 'core/utils/platform_capabilities.dart';
import 'core/utils/url_strategy.dart';
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
  // Public pages use real paths (`/features`, `/download`) rather than hash
  // fragments. Firebase Hosting rewrites those paths to the Flutter shell.
  configureWebUrlStrategy();
  // Preserve Flutter's existing handler. In production it writes the error
  // to the console; in widget and integration tests it records the error so
  // the test fails at the original assertion rather than timing out later.
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    debugPrint('Cashly Flutter error: ${details.exceptionAsString()}');
    previousFlutterErrorHandler?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('Cashly uncaught error: ${_sanitizeStartupError(error)}');
    debugPrintStack(stackTrace: stackTrace);
    return true;
  };
  if (kIsWeb) {
    // The public website must remain usable even when a Firebase service is
    // slow or unavailable. Begin Firebase setup before the router subscribes
    // to Auth, but do not await it before rendering the public shell.
    final webServicesReady = initializeRequiredServices();
    runApp(ProviderScope(child: CashlyApp(webServicesReady: webServicesReady)));
    unawaited(_reportWebServiceInitialization(webServicesReady));
    return;
  }
  runApp(
    ProviderScope(
      child: CashlyStartupApp(
        initialize: initializeRequiredServices,
        appBuilder: (_) => const CashlyApp(),
      ),
    ),
  );
}

Future<void> _reportWebServiceInitialization(
  Future<void> initialization,
) async {
  try {
    await initialization;
  } catch (error, stackTrace) {
    debugPrint(
      'FAILED: web Firebase services — ${_sanitizeStartupError(error)}',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// Initializes the minimum services needed to render and authenticate.
///
/// Optional integrations deliberately start after this completes. In
/// particular, browser analytics may wait on a remote configuration request;
/// waiting for it before [runApp] previously produced a blank web page.
Future<void> initializeRequiredServices() async {
  await _runStartupStep(
    'firebase-initialization',
    () => Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15)),
  );
  debugPrint('START: firestore-offline-cache');
  _configureFirestoreOfflineCache();
  debugPrint('SUCCESS: firestore-offline-cache');
  if (_useFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  // Browser builds use Firebase Auth/Firestore but don't share Android's
  // local-notification channels or background-isolate delivery model.
  if (AppPlatformCapabilities.supportsCurrentNotificationBridge) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    unawaited(_initializeOptionalNotifications());
  }

  // Debug builds run on developer machines, not real users — collecting
  // from them would just add noise to the dashboard.
  // Crashlytics has no Flutter web implementation, so its native error hooks
  // must stay off the browser startup path.
  if (AppPlatformCapabilities.supportsCrashReporting) {
    unawaited(_initializeOptionalCrashReporting());
    final previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      previousFlutterErrorHandler?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  if (AppPlatformCapabilities.supportsFirebaseAnalytics) {
    unawaited(_initializeOptionalAnalytics());
  }
}

Future<T> _runStartupStep<T>(String stage, Future<T> Function() action) async {
  debugPrint('START: $stage');
  try {
    final result = await action();
    debugPrint('SUCCESS: $stage');
    return result;
  } catch (error, stackTrace) {
    final failure = StartupFailure(stage, _sanitizeStartupError(error));
    debugPrint('FAILED: $stage — ${failure.message}');
    debugPrintStack(stackTrace: stackTrace);
    Error.throwWithStackTrace(failure, stackTrace);
  }
}

String _sanitizeStartupError(Object error) {
  if (error is TimeoutException) {
    return 'Timed out while waiting for the service.';
  }
  // Firebase error codes are essential diagnostics, but a raw exception may
  // contain an API key or session token. Preserve the useful message while
  // redacting those credential-shaped values before it reaches the console.
  return error
      .toString()
      .replaceAll(RegExp(r'AIza[0-9A-Za-z_-]{20,}'), '[redacted-api-key]')
      .replaceAll(
        RegExp(r'Bearer\\s+[^\\s]+', caseSensitive: false),
        'Bearer [redacted]',
      )
      .replaceAll(
        RegExp(r'(token|idToken|accessToken)=([^&\\s]+)', caseSensitive: false),
        r'$1=[redacted]',
      );
}

class StartupFailure implements Exception {
  const StartupFailure(this.stage, this.message);
  final String stage;
  final String message;
  @override
  String toString() => 'StartupFailure($stage)';
}

Future<void> _initializeOptionalNotifications() async {
  try {
    await initializeLocalNotifications();
  } catch (error, stackTrace) {
    debugPrint('Optional local notifications unavailable: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeOptionalCrashReporting() async {
  try {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  } catch (error, stackTrace) {
    debugPrint('Optional crash reporting unavailable: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeOptionalAnalytics() async {
  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
  } catch (error, stackTrace) {
    debugPrint('Optional analytics unavailable: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
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
  } catch (error) {
    debugPrint('Firestore persistent cache unavailable: $error');
  }
}
