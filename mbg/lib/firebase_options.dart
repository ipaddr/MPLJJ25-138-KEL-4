import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCCwOjNL7TeZ73jO-2jwPRY8091Tgftz2E',
    appId: '1:985024552380:web:bf13e3f70a466bcee35fb9',
    messagingSenderId: '985024552380',
    projectId: 'makangizigratisapp',
    authDomain: 'makangizigratisapp.firebaseapp.com',
    storageBucket: 'makangizigratisapp.firebasestorage.app',
    measurementId: 'G-V85HQCTLE5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBxaEJSvAZTcGn3Du_tWkDTJ0desdILwo4',
    appId: '1:985024552380:android:9c6f49c070cd5a5ae35fb9',
    messagingSenderId: '985024552380',
    projectId: 'makangizigratisapp',
    storageBucket: 'makangizigratisapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjsn5T7p3fKh0Jw2mWnKI24_SqnnajsRY',
    appId: '1:985024552380:ios:c6d0a85d2d430c73e35fb9',
    messagingSenderId: '985024552380',
    projectId: 'makangizigratisapp',
    storageBucket: 'makangizigratisapp.firebasestorage.app',
    iosBundleId: 'com.example.mbg',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDjsn5T7p3fKh0Jw2mWnKI24_SqnnajsRY',
    appId: '1:985024552380:ios:c6d0a85d2d430c73e35fb9',
    messagingSenderId: '985024552380',
    projectId: 'makangizigratisapp',
    storageBucket: 'makangizigratisapp.firebasestorage.app',
    iosBundleId: 'com.example.mbg',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCCwOjNL7TeZ73jO-2jwPRY8091Tgftz2E',
    appId: '1:985024552380:web:886d2ba4b5b2b866e35fb9',
    messagingSenderId: '985024552380',
    projectId: 'makangizigratisapp',
    authDomain: 'makangizigratisapp.firebaseapp.com',
    storageBucket: 'makangizigratisapp.firebasestorage.app',
    measurementId: 'G-44EYNLMHBC',
  );
}
