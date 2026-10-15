
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class IndivPostIncomeController extends GetxController {
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final selectedDate = DateTime.now().obs;

  // Replace with the actual ID of the selected Salary category.
  final selectedCategoryId = 1.obs;

  bool isLoading = false;

  // Display date in the UI
  String get formattedSelectedDate {
    final date = selectedDate.value;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Select transaction date
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  // POST income
  Future<void> saveIncome() async {
    if (amountController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter amount');
      return;
    }

    final amount = double.tryParse(
      amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Please enter a valid amount');
      return;
    }

    if (selectedCategoryId.value <= 0) {
      Get.snackbar('Error', 'Please select an income category');
      return;
    }

    if (isLoading) return;

    isLoading = true;
    update();

    try {
      final url = Uri.parse(
        'https://budgetbook.in/api/api/income',
      );

      final date = selectedDate.value;
      final formattedDate =
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      final body = {
        'categoryId': selectedCategoryId.value.toString(),
        'amount': amount.toString(),
        'incomeDate': formattedDate,
        'description': noteController.text.trim(),
      };

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          responseData['status'] == 'success') {
        Get.snackbar(
          'Success',
          responseData['message'] ??
              'Income saved successfully',
        );

        amountController.clear();
        noteController.clear();

        Get.back();
      } else {
        Get.snackbar(
          'Failed',
          responseData is Map
              ? (responseData['message']?.toString() ??
                  'Unable to save income')
              : 'Unable to save income',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong: $e',
      );
    } finally {
      isLoading = false;
      update();
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }
}

