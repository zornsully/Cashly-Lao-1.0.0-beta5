import 'package:flutter/foundation.dart';

/// Platform checks shared by startup, authentication, and the app shell.
///
/// Cashly's core finance features (Firestore, Auth, dashboard, calculations)
/// run on every supported target. These checks only protect optional plugins
/// whose native SDKs are not available on a particular desktop platform.
abstract final class AppPlatformCapabilities {
  static bool get supportsGoogleSignIn =>
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.macOS => true,
        _ => false,
      };

  static bool get supportsFirebaseAnalytics =>
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.macOS => true,
        _ => false,
      };

  static bool get supportsCrashReporting =>
      !kIsWeb &&
      switch (defaultTargetPlatform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.macOS => true,
        _ => false,
      };

  /// Cashly's current local-alert channels are Android-native. Finance data
  /// continues to synchronize everywhere else; unsupported optional alerts
  /// are simply not started there.
  static bool get supportsCurrentNotificationBridge =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
