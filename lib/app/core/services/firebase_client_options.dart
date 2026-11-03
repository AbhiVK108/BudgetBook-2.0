import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseClientOptions {
  static FirebaseOptions get currentPlatform {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
    const iosClientId = String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');
    const androidClientId = String.fromEnvironment(
      'FIREBASE_ANDROID_CLIENT_ID',
    );
    const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        messagingSenderId.isEmpty ||
        projectId.isEmpty) {
      throw StateError(
        'Firebase is not configured. Provide FIREBASE_API_KEY, '
        'FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, and '
        'FIREBASE_PROJECT_ID with --dart-define.',
      );
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: kIsWeb
          ? (authDomain.isEmpty ? '$projectId.firebaseapp.com' : authDomain)
          : null,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
      iosClientId: iosClientId.isEmpty ? null : iosClientId,
      androidClientId: androidClientId.isEmpty ? null : androidClientId,
      measurementId: kIsWeb && measurementId.isNotEmpty ? measurementId : null,
    );
  }
}
