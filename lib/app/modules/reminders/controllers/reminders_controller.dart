
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class RemindersController extends GetxController {
  final TextEditingController descriptionController =
      TextEditingController();

  final ApiService apiService = ApiService();

  final String url =
      'https://budgetbook.in/api/api/reminder';

  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // ================= FORMATTED DATE =================

  String get formattedSelectedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final date = selectedDate.value;

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ================= API DATE =================

  String get apiDate {
    final date = selectedDate.value;

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ================= SELECT DATE =================

  Future<void> selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select reminder date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF079B8D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF333333),
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Color(0xFF079B8D),
              headerForegroundColor: Colors.white,
            ),
            textTheme: Theme.of(context).textTheme.apply(
                  fontFamily: 'HankenGrotesk',
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      selectedDate.value = pickedDate;
    }
  }

  // ================= POST REMINDER =================

  Future<void> saveEntry() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final description = descriptionController.text.trim();

    // Validate description
    if (description.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter a description.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Prevent duplicate submissions
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      debugPrint('POST REMINDER URL: $url');
      debugPrint('POST REMINDER DATE: $apiDate');
      debugPrint('POST REMINDER DESCRIPTION: $description');

      // Use ApiService to include the saved authentication token
    final response = await apiService.postFormData(
            url,
    {
          'reminderDate': apiDate,
          'description': description,
    },
    );
 
      debugPrint('REMINDER STATUS: ${response.statusCode}');
      debugPrint('REMINDER BODY: ${response.body}');
      debugPrint('SENT DATE: $apiDate');
      debugPrint('SENT DESCRIPTION: $description');

      // Safely decode the response
      dynamic responseData = <String, dynamic>{};

      if (response.body.trim().isNotEmpty) {
        try {
          responseData = jsonDecode(response.body);
        } catch (_) {
          responseData = <String, dynamic>{};
        }
      }

      final String message =
          responseData is Map &&
                  responseData['message'] != null
              ? responseData['message'].toString()
              : '';

      // Success
      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        Get.snackbar(
          'Entry Saved',
          message.isNotEmpty
              ? message
              : 'Reminder saved successfully.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF079B8D),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
          ),
        );

        descriptionController.clear();
        selectedDate.value = DateTime.now();
      } else {
        Get.snackbar(
          response.statusCode == 401
              ? 'Authentication Failed'
              : 'Failed',
          response.statusCode == 401
              ? 'Your token is missing or invalid. Please login again.'
              : message.isNotEmpty
                  ? message
                  : 'Unable to save reminder. Status: ${response.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('POST REMINDER ERROR: $e');

      Get.snackbar(
        'Error',
        'Unable to connect to the server. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= MORE MENU =================

  void onMenuPressed() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Clear Entry',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              descriptionController.clear();
              selectedDate.value = DateTime.now();
              Get.back();
            },
          ),
        ),
      ),
    );
  }

  // ================= DISPOSE =================

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}

