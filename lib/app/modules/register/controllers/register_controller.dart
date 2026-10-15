import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterController extends GetxController {
  final isLoading = false.obs;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final url = 'https://budgetbook.in/api/api/customers';

Future<void> registerUser() async {
  final username = usernameController.text.trim();
  final password = passwordController.text;
  final confirmPassword = confirmPasswordController.text;

  if (username.isEmpty) {
    Get.snackbar("Error", "Please enter a valid user name");
    return;
  }

  if (password.isEmpty) {
    Get.snackbar("Error", "Please enter a password");
    return;
  }

  if (confirmPassword.isEmpty) {
    Get.snackbar("Error", "Please confirm your password");
    return;
  }

  if (password != confirmPassword) {
    Get.snackbar("Error", "Passwords do not match");
    return;
  }

  try {
    isLoading.value = true;

    print("Username: $username");
    print("Password: $password");
    print("Confirm Password: $confirmPassword");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': username,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );

    print("Register Status: ${response.statusCode}");
    print("Register Response: ${response.body}");

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      Get.snackbar(
        "Success",
        responseData['message'] ?? "Account created successfully!",
      );

      usernameController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      Get.offAllNamed(Routes.LOGIN);
    } else {
      if (responseData['errors'] != null) {
        final errors = responseData['errors'] as Map<String, dynamic>;

        final errorMessage = errors.values
            .map((error) => error.toString())
            .join("\n");

        Get.snackbar(
          "Registration Failed",
          errorMessage,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          "Registration Failed",
          responseData['message'] ?? "Registration failed",
        );
      }
    }
  } catch (e) {
    print("Register Exception: $e");

    Get.snackbar(
      "Error",
      "Something went wrong: $e",
    );
  } finally {
    isLoading.value = false;
  }
}

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}


