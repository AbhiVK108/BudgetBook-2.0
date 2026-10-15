
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:budget_book_2026/app/core/services/api_services.dart';

class PostborrowController extends GetxController {
  final ApiService apiService = ApiService();

  final String url = 'https://budgetbook.in/api/api/credit';

  final TextEditingController personController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController amountController =
      TextEditingController();

  final TextEditingController interestController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  // Selected dates
  final Rx<DateTime?> receiveDate = Rx<DateTime?>(null);
  final Rx<DateTime?> returnDate = Rx<DateTime?>(null);

  // Loading state
  final RxBool isLoading = false.obs;

  // Format date as YYYY-MM-DD
  String formatDate(DateTime date) {
    final String year = date.year.toString();
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Select given/borrow date
  Future<void> selectReceiveDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: receiveDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    receiveDate.value = picked;

    if (returnDate.value != null &&
        returnDate.value!.isBefore(picked)) {
      returnDate.value = null;

      _showMessage(
        'Return Date Reset',
        'Please select a return date on or after the given date.',
      );
    }
  }

  // Select return date
  Future<void> selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          returnDate.value ?? receiveDate.value ?? DateTime.now(),
      firstDate: receiveDate.value ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      returnDate.value = picked;
    }
  }

  // Submit borrow details
  Future<void> postBorrow() async {
    if (isLoading.value) return;

    final String person = personController.text.trim();
    final String phone = phoneController.text.trim();
    final String amountText = amountController.text.trim();
    final String interestText = interestController.text.trim();

    if (person.isEmpty) {
      _showMessage('Required', 'Please enter the person name.');
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showMessage(
        'Invalid Phone',
        'Please enter a valid 10-digit mobile number.',
      );
      return;
    }

    final double? amount = double.tryParse(amountText);

    if (amount == null || !amount.isFinite || amount <= 0) {
      _showMessage(
        'Invalid Amount',
        'Please enter an amount greater than zero.',
      );
      return;
    }

    final double? interest = double.tryParse(interestText);

    if (interest == null || !interest.isFinite || interest < 0) {
      _showMessage(
        'Invalid Interest',
        'Please enter a valid interest rate.',
      );
      return;
    }

    final DateTime? received = receiveDate.value;
    final DateTime? repayment = returnDate.value;

    if (received == null) {
      _showMessage('Required', 'Please select the given date.');
      return;
    }

    if (repayment == null) {
      _showMessage('Required', 'Please select the return date.');
      return;
    }

    if (repayment.isBefore(received)) {
      _showMessage(
        'Invalid Date',
        'Return date cannot be before the given date.',
      );
      return;
    }

    try {
      isLoading.value = true;

      // IMPORTANT:
      // The API requires givenTo and givenDate.
      final Map<String, String> body = {
        'givenTo': person,
        'phone': phone,
        'amount': amount.toString(),
        'givenDate': formatDate(received),
        'rateOfInterest': interest.toString(),
        'returnDate': formatDate(repayment),
        'description': descriptionController.text.trim(),
      };

      debugPrint('Borrow API URL: $url');
      debugPrint('Borrow request body: ${jsonEncode(body)}');

      // Use your existing ApiService with the saved token.
      final response = await apiService.postFormData(url, body);

      debugPrint('Borrow API status: ${response.statusCode}');
      debugPrint('Borrow API response: ${response.body}');

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        _showMessage(
          'Server Error',
          'Invalid server response. HTTP ${response.statusCode}.',
        );
        return;
      }

      if (decoded is! Map) {
        _showMessage(
          'Server Error',
          'Unexpected API response format.',
        );
        return;
      }

      final String message = decoded['message']?.toString() ??
          'Unable to save borrow details.';

      final bool success = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['status']?.toString().toLowerCase() == 'success';

      if (success) {
        _showMessage('Success', message);

        clearForm();

        if (Get.key.currentState?.canPop() ?? false) {
          Get.back();
        }
      } else {
        final dynamic errors = decoded['errors'];
        final List<String> details = [];

        if (errors is Map) {
          errors.forEach((key, value) {
            if (value is List) {
              details.addAll(
                value.map((item) => item.toString()),
              );
            } else {
              details.add(value.toString());
            }
          });
        }

        debugPrint('Borrow API errors: $errors');

        _showMessage(
          'Failed (${response.statusCode})',
          details.isNotEmpty ? details.join('\n') : message,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Post borrow error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(
        'Error',
        'Unable to submit borrow details. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Display messages
  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
    );
  }

  // Clear all fields
  void clearForm() {
    personController.clear();
    phoneController.clear();
    amountController.clear();
    interestController.clear();
    descriptionController.clear();

    receiveDate.value = null;
    returnDate.value = null;
  }

  @override
  void onClose() {
    personController.dispose();
    phoneController.dispose();
    amountController.dispose();
    interestController.dispose();
    descriptionController.dispose();

    super.onClose();
  }
}
