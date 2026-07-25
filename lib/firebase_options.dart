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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Run `flutterfire configure` to add web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for '
          '$defaultTargetPlatform.',
        );
    }
  }

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
}
