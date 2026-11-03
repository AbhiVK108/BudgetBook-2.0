import 'dart:convert';

import 'package:budget_book_2026/app/core/services/firebase_phone_auth_service.dart';
import 'package:budget_book_2026/app/core/constants/api_endpoints.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  final isLoading = false.obs;
  final isSendingOtp = false.obs;
  final isVerifyingOtp = false.obs;
  final isOtpSent = false.obs;
  final showPasswordLogin = false.obs;

  final ApiService apiService = ApiService();
  final FirebasePhoneAuthService phoneAuth = FirebasePhoneAuthService();

  final String loginUrl = ApiEndpoints.legacyVerifyUrl;

  void _debugAuth(String message) {
    if (kDebugMode) debugPrint('[PhoneOtp] $message');
  }

  Object? _redactAuthResponse(Object? value, {String? key}) {
    final normalizedKey = key?.toLowerCase() ?? '';
    if (normalizedKey.contains('token') ||
        normalizedKey.contains('mobile') ||
        normalizedKey.contains('phone') ||
        normalizedKey.contains('email') ||
        normalizedKey.contains('full_name') ||
        normalizedKey.contains('last_login_ip')) {
      return '[REDACTED]';
    }
    if (value is Map) {
      return value.map(
        (entryKey, entryValue) => MapEntry(
          entryKey.toString(),
          _redactAuthResponse(entryValue, key: entryKey.toString()),
        ),
      );
    }
    if (value is List) {
      return value.map(_redactAuthResponse).toList();
    }
    return value;
  }

  Future<void> sendPhoneOtp() async {
    final fullName = fullNameController.text.trim();
    final phoneNumber = phoneController.text.trim().replaceAll(
      RegExp(r'[\s()-]'),
      '',
    );
    if (fullName.isEmpty) {
      _showError('Enter your full name.');
      return;
    }
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phoneNumber)) {
      _showError(
        'Enter a valid phone number with country code, e.g. +14155552671.',
      );
      return;
    }
    if (isSendingOtp.value || isVerifyingOtp.value || isLoading.value) return;

    phoneController.text = phoneNumber;
    isSendingOtp.value = true;
    _debugAuth('Starting SMS code request.');
    try {
      await phoneAuth.sendCode(
        phoneNumber: phoneNumber,
        onCodeSent: () {
          _debugAuth('SMS code is ready for manual entry.');
          isOtpSent.value = true;
        },
        onAutoVerified: (credential) {
          _debugAuth('Firebase auto-verification returned a credential.');
          return _completeFirebaseSignIn(credential);
        },
      );
      isOtpSent.value = true;
      _debugAuth('SMS code request flow completed.');
    } on FirebaseAuthException catch (error) {
      _debugAuth('SMS code request failed (${error.code}).');
      _showError(_firebaseErrorText(error));
    } on StateError catch (error) {
      _debugAuth('SMS code request failed (StateError).');
      _showError(error.message);
    } catch (error) {
      _debugAuth('SMS code request failed (${error.runtimeType}).');
      _showError('Unable to send the verification code. Please try again.');
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> verifyPhoneOtp() async {
    final code = otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showError('Enter the six-digit verification code.');
      return;
    }
    if (isVerifyingOtp.value || isSendingOtp.value || isLoading.value) return;

    isVerifyingOtp.value = true;
    _debugAuth('Submitting entered SMS code for Firebase verification.');
    try {
      final credential = await phoneAuth.confirmCode(code);
      _debugAuth('Firebase verified the entered SMS code.');
      await _completeFirebaseSignIn(credential);
    } on FirebaseAuthException catch (error) {
      _debugAuth('Firebase OTP verification failed (${error.code}).');
      _showError(_firebaseErrorText(error));
    } on StateError catch (error) {
      _debugAuth('Firebase OTP verification failed (StateError).');
      _showError(error.message);
    } catch (error) {
      _debugAuth('Firebase OTP verification failed (${error.runtimeType}).');
      _showError('Unable to verify the code. Please try again.');
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  Future<void> _completeFirebaseSignIn(UserCredential credential) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      _debugAuth('Retrieving Firebase ID token after phone verification.');
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const FormatException(
          'Firebase did not return a signed-in user.',
        );
      }
      final firebaseIdToken = await firebaseUser.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw const FormatException(
          'Firebase did not return a valid ID token.',
        );
      }
      _debugAuth('Calling backend Firebase verification after OTP success.');
      final response = await apiService.verifyFirebasePhone(
        idToken: firebaseIdToken,
        fullName: fullNameController.text.trim(),
      );
      _debugAuth(
        'Backend Firebase verification returned ${response.statusCode}.',
      );
      if (response.body.trim().isEmpty) {
        throw const FormatException(
          'The sign-in server returned an empty response.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException(
          'The sign-in server returned invalid data.',
        );
      }
      final payload = Map<String, dynamic>.from(decoded);
      _debugAuth(
        'Backend response body: ${const JsonEncoder.withIndent('  ').convert(_redactAuthResponse(payload))}',
      );
      final status = payload['status']?.toString().toLowerCase();
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          payload['success'] == false ||
          status == 'error' ||
          status == 'failed') {
        throw Exception(
          payload['message']?.toString() ?? 'Phone sign-in was rejected.',
        );
      }
      final dataValue = payload['data'];
      final data = dataValue is Map
          ? Map<String, dynamic>.from(dataValue)
          : payload;
      final responseMaps = <Map<String, dynamic>>[payload, data];
      for (final key in ['user', 'profile', 'tokens']) {
        final value = data[key] ?? payload[key];
        if (value is Map) responseMaps.add(Map<String, dynamic>.from(value));
      }
      String? responseValue(List<String> keys) {
        for (final map in responseMaps.reversed) {
          for (final key in keys) {
            final value = map[key];
            if (value != null && value.toString().isNotEmpty) {
              return value.toString();
            }
          }
        }
        return null;
      }

      final accessToken = responseValue([
        'access_token',
        'accessToken',
        'token',
      ]);
      final userId = responseValue(['user_id', 'userId', 'id']);
      final roleId = responseValue(['role_id', 'roleId']);
      final refreshToken = responseValue(['refresh_token', 'refreshToken']);
      if (accessToken == null || accessToken.isEmpty) {
        throw const FormatException(
          'Sign-in succeeded but no access token was returned.',
        );
      }
      await apiService.saveAuthCredentials(
        accessToken: accessToken,
        userId: userId,
        roleId: roleId,
        refreshToken: refreshToken,
      );
      _debugAuth(
        'Saved credentials: accessToken=saved (${accessToken.length} chars), '
        'userId=$userId, roleId=$roleId, '
        'refreshToken=${refreshToken == null ? 'missing' : 'saved'}, '
        'expiresAt=${responseValue(['expires_at', 'expiresAt']) ?? 'not provided'}.',
      );
      final displayName =
          responseValue(['full_name', 'fullName', 'name']) ??
          fullNameController.text.trim();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('username', displayName);

      Get.offAllNamed('/home');
    } on FormatException catch (error) {
      _debugAuth('Post-verification response error (${error.message}).');
      _showError(error.message);
    } on FirebaseAuthException catch (error) {
      _debugAuth('Firebase sign-in completion failed (${error.code}).');
      _showError(_firebaseErrorText(error));
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      _debugAuth('Firebase sign-in completion failed (${error.runtimeType}).');
      _showError(message);
    } finally {
      isLoading.value = false;
    }
  }

  String _firebaseErrorText(FirebaseAuthException error) {
    switch (error.code) {
      case 'code-expired':
      case 'session-expired':
        return 'The code expired. Request a new verification code and enter the latest one.';
      case 'invalid-phone-number':
        return 'That phone number is not valid. Include the country code.';
      case 'invalid-verification-code':
        return 'That verification code is incorrect. Check it and try again.';
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'Too many attempts. Wait a while before requesting another code.';
      case 'captcha-check-failed':
        return 'Phone verification could not be confirmed. Please retry.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'app-not-authorized':
        return 'This app is not authorized for Firebase phone authentication.';
      default:
        return error.message ?? 'Firebase phone verification failed.';
    }
  }

  void _showError(String message) {
    Get.snackbar('Phone sign-in', message, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> loginUser() async {
    if (usernameController.text.trim().isEmpty) {
      Get.snackbar(
        "Required",
        "Please enter username",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      Get.snackbar(
        "Required",
        "Please enter password",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      final response = await apiService.postFormDataWithoutToken(loginUrl, {
        "username": usernameController.text.trim(),
        "password": passwordController.text.trim(),
      });

      if (response.body.isEmpty) {
        Get.snackbar(
          "Error",
          "Empty response from server",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final responseData = jsonDecode(response.body);

      final status = responseData["status"]?.toString().toLowerCase();

      if (response.statusCode == 200 &&
          status == "success" &&
          responseData is Map) {
        // Get user data from the data object.
        final data = responseData["data"];

        if (data is! Map) {
          Get.snackbar(
            "Login Error",
            "User information not received",
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        // Save username for the Home Screen.
        final savedUsername =
            data["username"]?.toString() ??
            data['full_name']?.toString() ??
            usernameController.text.trim();

        final accessToken =
            data['access_token']?.toString() ??
            data['accessToken']?.toString() ??
            data['token']?.toString() ??
            responseData['access_token']?.toString() ??
            responseData['accessToken']?.toString() ??
            responseData['token']?.toString();
        if (accessToken == null || accessToken.isEmpty) {
          Get.snackbar(
            'Login Error',
            'The server did not return an access token.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        await apiService.saveAuthCredentials(
          accessToken: accessToken,
          userId: (data['user_id'] ?? data['userId'] ?? data['id'])?.toString(),
          roleId: (data['role_id'] ?? data['roleId'])?.toString(),
          refreshToken: (data['refresh_token'] ?? data['refreshToken'])
              ?.toString(),
        );

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("username", savedUsername);

        debugPrint("Username saved: $savedUsername");

        Get.snackbar(
          "Success",
          "Login successful",
          snackPosition: SnackPosition.BOTTOM,
        );

        Get.offAllNamed('/home');
      } else {
        final message = responseData["message"]?.toString() ?? "Login failed";

        Get.snackbar(
          "Login Failed",
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint("Login Error: $e");

      Get.snackbar(
        "Error",
        "Unable to connect to server",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
