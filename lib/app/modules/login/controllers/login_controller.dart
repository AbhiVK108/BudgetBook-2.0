
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;

  final ApiService apiService = ApiService();

  final String loginUrl =
      "https://budgetbook.in/api/api/verify";

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

      final response = await apiService.postFormDataWithoutToken(
        loginUrl,
        {
          "username": usernameController.text.trim(),
          "password": passwordController.text.trim(),
        },
      );

      debugPrint("Login Status Code: ${response.statusCode}");
      debugPrint("Login Response: ${response.body}");

      if (response.body.isEmpty) {
        Get.snackbar(
          "Error",
          "Empty response from server",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final responseData = jsonDecode(response.body);

      final status =
          responseData["status"]?.toString().toLowerCase();

      if (response.statusCode == 200 && status == "success") {
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
            data["username"]?.toString() ?? "";

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("username", savedUsername);

        debugPrint("Username saved: $savedUsername");

        // Preserve token saving if the API provides a top-level token.
        final token = responseData["token"];

        if (token != null && token.toString().isNotEmpty) {
          await apiService.saveToken(token.toString());
          debugPrint("Access token saved");
        }

        Get.snackbar(
          "Success",
          "Login successful",
          snackPosition: SnackPosition.BOTTOM,
        );

        Get.offAllNamed("/home");
      } else {
        final message =
            responseData["message"]?.toString() ?? "Login failed";

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
    super.onClose();
  }
}
