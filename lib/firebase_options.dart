// File generated manually from GoogleService-Info.plist and google-services.json.
// Regenerate with: dart run flutterfire_configure (if FlutterFire CLI is set up).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported. Use Android or iOS.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzVepjShaCDbgeWlz6mJTNyHGjMsmNT3M',
    appId: '1:538360665929:android:04b1a4f32785631b4fac98',
    messagingSenderId: '538360665929',
    projectId: 'personal-construction-manager',
    storageBucket: 'personal-construction-manager.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDsqOMP0hA8kyciI_zXlPkFa2Z6pnOMUEU',
    appId: '1:538360665929:ios:41bfc461d5875f634fac98',
    messagingSenderId: '538360665929',
    projectId: 'personal-construction-manager',
    storageBucket: 'personal-construction-manager.firebasestorage.app',
    iosBundleId: 'com.example.personalConstructionManager',
  );
}
