import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostchitfundController extends GetxController {
  static const String url = 'https://budgetbook.in/api/api/chitfunds';

  final ApiService apiService = ApiService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController chitNameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController membersController = TextEditingController();
  final TextEditingController durationController = TextEditingController(
    text: '12',
  );
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController beforeLiftController = TextEditingController();
  final TextEditingController afterLiftController = TextEditingController();
  final RxBool isLoading = false.obs;

  Future<void> saveChitFund() async {
    if (isLoading.value) return;

    final body = <String, String>{
      'chitName': chitNameController.text.trim(),
      'amount': amountController.text.trim(),
      'members': membersController.text.trim(),
      'duration': durationController.text.trim(),
      'startDate': startDateController.text.trim(),
      'endDate': endDateController.text.trim(),
      'beforeLift': beforeLiftController.text.trim(),
      'afterLift': afterLiftController.text.trim(),
    };

    try {
      isLoading.value = true;
      final response = await apiService.postFormData(url, body);
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
        _showMessage('Server Error', 'Unexpected API response format.');
        return;
      }

      final message =
          decoded['message']?.toString() ?? 'Unable to save chit fund.';
      final succeeded =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['status']?.toString().toLowerCase() == 'success';

      if (!succeeded) {
        _showMessage(
          'Unable to save chit fund',
          _errorMessage(decoded, message),
        );
        return;
      }

      _showMessage('Success', message);
      _clearForm();
    } catch (error) {
      _showMessage('Network Error', 'Unable to save chit fund: $error');
    } finally {
      isLoading.value = false;
    }
  }

  String _errorMessage(Map<dynamic, dynamic> response, String fallback) {
    final errors = response['errors'];
    if (errors is! Map) return fallback;

    return errors.entries
        .map((entry) {
          final value = entry.value;
          final details = value is List ? value.join(', ') : value;
          return '${entry.key}: $details';
        })
        .join('\n');
  }

  void _clearForm() {
    chitNameController.clear();
    amountController.clear();
    membersController.clear();
    durationController.text = '12';
    startDateController.clear();
    endDateController.clear();
    beforeLiftController.clear();
    afterLiftController.clear();
    formKey.currentState?.reset();
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    chitNameController.dispose();
    amountController.dispose();
    membersController.dispose();
    durationController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    beforeLiftController.dispose();
    afterLiftController.dispose();
    super.onClose();
  }
}
