import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class GetReminderController extends GetxController {
  final ApiService apiService = ApiService();

  final String url =
      'https://budgetbook.in/api/api/reminder';

  final Rx<DateTime> selectedDate = DateTime.now().obs;

  final RxBool isLoading = false.obs;

  final RxList<dynamic> reminders = <dynamic>[].obs;

  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReminders();
  }

  // GET REMINDERS FROM API
  Future<void> fetchReminders() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Uses ApiService headers, including the saved Bearer token.
      final response = await apiService.get(url);

      debugPrint('Reminder status: ${response.statusCode}');
      debugPrint('Reminder response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> fetchedReminders = [];

        if (decoded is List) {
          fetchedReminders = decoded;
        } else if (decoded is Map) {
          final data = decoded['data'];

          if (data is List) {
            fetchedReminders = data;
          } else if (data is Map) {
            // Support APIs returning one reminder inside data.
            fetchedReminders = [data];
          } else if (decoded['reminders'] is List) {
            fetchedReminders = decoded['reminders'];
          }
        }

        reminders.assignAll(
          fetchedReminders.whereType<Map>().map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );

        debugPrint('Reminders loaded: ${reminders.length}');
      } else {
        errorMessage.value =
            'Failed to fetch reminders (${response.statusCode})';

        Get.snackbar(
          'Error',
          errorMessage.value,
        );
      }
    } catch (e) {
      errorMessage.value = 'Unable to load reminders';

      debugPrint('Fetch reminder error: $e');

      Get.snackbar(
        'Error',
        errorMessage.value,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // THREE-DOT MENU
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
              // This resets the selected date only.
              selectedDate.value = DateTime.now();
              Get.back();
            },
          ),
        ),
      ),
    );
  }
}