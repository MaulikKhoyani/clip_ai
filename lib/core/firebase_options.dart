import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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
    apiKey: 'AIzaSyDSRoayYcqfv46oMw9qtCQy3n5SNMLh7FY',
    appId: '1:1041379095704:android:32ed1c55ae81f503a94ced',
    messagingSenderId: '1041379095704',
    projectId: 'clipai-5e5cf',
    storageBucket: 'clipai-5e5cf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAJmDKG-3J6UZdaIiFM3zUh76jBns5AwZ4',
    appId: '1:1041379095704:ios:b3b33c54728f04eea94ced',
    messagingSenderId: '1041379095704',
    projectId: 'clipai-5e5cf',
    storageBucket: 'clipai-5e5cf.firebasestorage.app',
    iosBundleId: 'com.clipai.clipai',
  );
}
