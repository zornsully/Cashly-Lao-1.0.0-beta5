// Generated configuration for the Cashly Firebase project ("cashly-lao").
// Regenerate with `flutterfire configure` if the Firebase project changes.
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the current platform.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for '
          '$defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCgKyPNQpWTFuyh4ahf4r7TaTsIulxd010',
    appId: '1:406428434702:web:f877e99ac9093b1f36d75f',
    messagingSenderId: '406428434702',
    projectId: 'cashly-lao',
    authDomain: 'cashly-lao.firebaseapp.com',
    storageBucket: 'cashly-lao.firebasestorage.app',
    measurementId: 'G-7WNB047S5Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD__2UQZZGP8_kzhiWkI9PZBH4VNpqeReQ',
    appId: '1:406428434702:android:1debebd15d366fee36d75f',
    messagingSenderId: '406428434702',
    projectId: 'cashly-lao',
    storageBucket: 'cashly-lao.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyNuMU2ZMn5p3gPwD36vqXto1ggwPXiG4',
    appId: '1:406428434702:ios:80f12cf24f39ce4b36d75f',
    messagingSenderId: '406428434702',
    projectId: 'cashly-lao',
    storageBucket: 'cashly-lao.firebasestorage.app',
    iosBundleId: 'com.cashlylao.app',
  );

  /// macOS uses the registered Cashly Lao Apple application configuration.
  /// The bundle identifier intentionally matches iOS so the same secure
  /// Firebase project, Firestore rules, and user data are used on both Apple
  /// platforms.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCyNuMU2ZMn5p3gPwD36vqXto1ggwPXiG4',
    appId: '1:406428434702:ios:80f12cf24f39ce4b36d75f',
    messagingSenderId: '406428434702',
    projectId: 'cashly-lao',
    storageBucket: 'cashly-lao.firebasestorage.app',
    iosBundleId: 'com.cashlylao.app',
  );

  /// Windows uses the project's browser-style Firebase application config.
  /// It provides the same Auth and Firestore backend as the web app while
  /// keeping credentials and user records in one Cashly Lao project.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCgKyPNQpWTFuyh4ahf4r7TaTsIulxd010',
    appId: '1:406428434702:web:f877e99ac9093b1f36d75f',
    messagingSenderId: '406428434702',
    projectId: 'cashly-lao',
    authDomain: 'cashly-lao.firebaseapp.com',
    storageBucket: 'cashly-lao.firebasestorage.app',
    measurementId: 'G-7WNB047S5Z',
  );
}
