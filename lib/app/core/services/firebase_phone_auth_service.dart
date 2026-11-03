import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_client_options.dart';

class FirebasePhoneAuthService {
  ConfirmationResult? _webConfirmationResult;
  String? _verificationId;
  int? _resendToken;

  static Future<FirebaseApp>? _initialization;

  void _log(String message) {
    if (kDebugMode) debugPrint('[FirebasePhoneAuth] $message');
  }

  Future<FirebaseApp> _initializeFirebase() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return Firebase.initializeApp();
    }
    return Firebase.initializeApp(
      options: FirebaseClientOptions.currentPlatform,
    );
  }

  Future<FirebaseAuth> _auth() async {
    if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    _log('Initializing Firebase.');
    _initialization ??= _initializeFirebase();
    try {
      await _initialization;
      _log('Firebase initialization succeeded.');
    } catch (_) {
      _initialization = null;
      _log('Firebase initialization failed.');
      rethrow;
    }
    return FirebaseAuth.instance;
  }

  Future<void> sendCode({
    required String phoneNumber,
    required void Function() onCodeSent,
    required Future<void> Function(UserCredential credential) onAutoVerified,
  }) async {
    _log('Requesting SMS verification code.');
    final auth = await _auth();
    if (kIsWeb) {
      _webConfirmationResult = await auth.signInWithPhoneNumber(phoneNumber);
      _log('Web SMS verification request succeeded; code entry is available.');
      onCodeSent();
      return;
    }

    final result = Completer<void>();
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        _log('Firebase completed phone verification automatically.');
        try {
          final userCredential = await auth.signInWithCredential(credential);
          await onAutoVerified(userCredential);
          _log('Automatic phone sign-in callback completed.');
          if (!result.isCompleted) result.complete();
        } on FirebaseAuthException catch (error, stackTrace) {
          _log('Automatic phone sign-in failed (${error.code}).');
          if (!result.isCompleted) result.completeError(error, stackTrace);
        } catch (error, stackTrace) {
          _log('Automatic phone sign-in failed (${error.runtimeType}).');
          if (!result.isCompleted) result.completeError(error, stackTrace);
        }
      },
      verificationFailed: (error) {
        _log('SMS verification request failed (${error.code}).');
        if (!result.isCompleted) result.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _log('Firebase sent the SMS code; manual code entry is available.');
        if (!result.isCompleted) {
          onCodeSent();
          result.complete();
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
        _log(
          'Automatic SMS retrieval timed out; manual code entry is available.',
        );
        if (!result.isCompleted) {
          onCodeSent();
          result.complete();
        }
      },
    );
    try {
      await result.future.timeout(const Duration(seconds: 90));
    } on TimeoutException {
      _log('Timed out waiting for Firebase SMS verification callbacks.');
      rethrow;
    }
  }

  Future<UserCredential> confirmCode(String smsCode) async {
    _log('Submitting manually entered SMS code to Firebase.');
    if (kIsWeb) {
      final confirmation = _webConfirmationResult;
      if (confirmation == null) {
        throw StateError('Request a verification code before entering it.');
      }
      final credential = await confirmation.confirm(smsCode);
      _webConfirmationResult = null;
      _log('Firebase accepted the manually entered SMS code on web.');
      return credential;
    }

    final verificationId = _verificationId;
    if (verificationId == null) {
      throw StateError('Request a verification code before entering it.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      _log('Firebase accepted the manually entered SMS code.');
      return userCredential;
    } on FirebaseAuthException catch (error) {
      _log('Firebase rejected the SMS code (${error.code}).');
      rethrow;
    }
  }
}
