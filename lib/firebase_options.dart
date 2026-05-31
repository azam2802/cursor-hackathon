// Placeholder file — replaced when you run: flutterfire configure
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
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
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux — '
          're-run FlutterFire CLI and include the linux platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAswwakUecoiV4fvJBof5xCsf0LmZ1RSGA',
    appId: '1:892051670753:web:74011e8f06ec46e32799a0',
    messagingSenderId: '892051670753',
    projectId: 'cursor-hackat',
    storageBucket: 'cursor-hackat.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLN_5e9ZKWZf9ourd-FtKOIFan9X_8gmk',
    appId: '1:892051670753:android:54619dcc195f25b32799a0',
    messagingSenderId: '892051670753',
    projectId: 'cursor-hackat',
    storageBucket: 'cursor-hackat.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCiaQSSjXnZAmnkn0aN6_qxnbnjoPHOi0A',
    appId: '1:892051670753:ios:de8f4b233fbbcca32799a0',
    messagingSenderId: '892051670753',
    projectId: 'cursor-hackat',
    storageBucket: 'cursor-hackat.firebasestorage.app',
    iosBundleId: 'com.example.summerActivity',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyAswwakUecoiV4fvJBof5xCsf0LmZ1RSGA",
    authDomain: "cursor-hackat.firebaseapp.com",
    projectId: "cursor-hackat",
    storageBucket: "cursor-hackat.firebasestorage.app",
    messagingSenderId: "892051670753",
    appId: "1:892051670753:web:74011e8f06ec46e32799a0",
    iosBundleId: 'com.example.summerActivity',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "AIzaSyAswwakUecoiV4fvJBof5xCsf0LmZ1RSGA",
    authDomain: "cursor-hackat.firebaseapp.com",
    projectId: "cursor-hackat",
    storageBucket: "cursor-hackat.firebasestorage.app",
    messagingSenderId: "892051670753",
    appId: "1:892051670753:web:74011e8f06ec46e32799a0",
  );
}
