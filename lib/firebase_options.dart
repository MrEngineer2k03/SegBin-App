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
    final options = _getPlatformOptions();
    return options;
  }

  static FirebaseOptions _getPlatformOptions() {
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
    apiKey: 'AIzaSyAEGn5CDWQNO_ug8lR2Mz2JQC0ES3gx-0Q',
    appId: '1:697988632641:web:f4fc41c98dcec79b3136c0',
    messagingSenderId: '697988632641',
    projectId: 'smart-waste-segregation-cc790',
    authDomain: 'smart-waste-segregation-cc790.firebaseapp.com',
    storageBucket: 'smart-waste-segregation-cc790.firebasestorage.app',
    measurementId: 'G-ZS8RXJ7PQN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGhi9m8HtggPlXM3v-TdCAUrrgDDv17nE',
    appId: '1:697988632641:android:ff5fec3fc0661e0d3136c0',
    messagingSenderId: '697988632641',
    projectId: 'smart-waste-segregation-cc790',
    storageBucket: 'smart-waste-segregation-cc790.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBTt7SGP1HUNJuerUUb32rEsNMgo5eeK9M',
    appId: '1:697988632641:ios:a800e00c34d6d87b3136c0',
    messagingSenderId: '697988632641',
    projectId: 'smart-waste-segregation-cc790',
    storageBucket: 'smart-waste-segregation-cc790.firebasestorage.app',
    iosBundleId: 'com.example.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBTt7SGP1HUNJuerUUb32rEsNMgo5eeK9M',
    appId: '1:697988632641:ios:a800e00c34d6d87b3136c0',
    messagingSenderId: '697988632641',
    projectId: 'smart-waste-segregation-cc790',
    storageBucket: 'smart-waste-segregation-cc790.firebasestorage.app',
    iosBundleId: 'com.example.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAEGn5CDWQNO_ug8lR2Mz2JQC0ES3gx-0Q',
    appId: '1:697988632641:web:75e4b1c7729c597c3136c0',
    messagingSenderId: '697988632641',
    projectId: 'smart-waste-segregation-cc790',
    authDomain: 'smart-waste-segregation-cc790.firebaseapp.com',
    storageBucket: 'smart-waste-segregation-cc790.firebasestorage.app',
    measurementId: 'G-NNF9F3C4B4',
  );

}
