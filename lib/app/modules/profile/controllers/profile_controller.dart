import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class ProfileController extends GetxController {
  final ApiService apiService = ApiService();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final profile = Rxn<ProfileData>();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await apiService.get(ApiService.profileUrl);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Profile request failed (${response.statusCode}).');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map ||
          decoded['data']['profile'] is! Map) {
        throw const FormatException('The profile response was invalid.');
      }

      profile.value = ProfileData.fromJson(
        Map<String, dynamic>.from(decoded['data']['profile'] as Map),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to fetch profile: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage.value = 'Unable to load your profile. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}

class ProfileData {
  const ProfileData({
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.status,
    required this.profileImage,
    required this.createdAt,
    required this.mobileVerifiedAt,
    required this.emailVerifiedAt,
  });

  final String? fullName;
  final String? email;
  final String? mobile;
  final String? status;
  final String? profileImage;
  final String? createdAt;
  final String? mobileVerifiedAt;
  final String? emailVerifiedAt;

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    String? readString(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return ProfileData(
      fullName: readString('full_name'),
      email: readString('email'),
      mobile: readString('mobile'),
      status: readString('status'),
      profileImage: readString('profile_image'),
      createdAt: readString('created_at'),
      mobileVerifiedAt: readString('mobile_verified_at'),
      emailVerifiedAt: readString('email_verified_at'),
    );
  }
}
