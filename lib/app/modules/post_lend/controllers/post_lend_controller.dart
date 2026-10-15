
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:budget_book_2026/app/core/services/api_services.dart';

class PostLendController extends GetxController {
  final ApiService apiService = ApiService();

  final String url = 'https://budgetbook.in/api/api/debit';

  // Form controllers
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
  final Rx<DateTime?> giveDate = Rx<DateTime?>(null);
  final Rx<DateTime?> returnDate = Rx<DateTime?>(null);

  // Loading state
  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  dynamic editingLendId;

  // Format date as YYYY-MM-DD
  String formatDate(DateTime date) {
    final String year = date.year.toString();
    final String month =
        date.month.toString().padLeft(2, '0');
    final String day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is! Map) return;

    final lend = Map<String, dynamic>.from(argument);
    editingLendId = lend['id'] ?? lend['debitId'] ?? lend['debit_id'];
    isEditMode.value = true;
    personController.text =
        (lend['receiveFrom'] ?? lend['givenTo'] ?? lend['person'] ?? '')
            .toString();
    phoneController.text = (lend['phone'] ?? '').toString();
    amountController.text = (lend['amount'] ?? '').toString();
    interestController.text =
        (lend['rateOfInterest'] ?? lend['interest'] ?? '').toString();
    descriptionController.text = (lend['description'] ?? '').toString();
    giveDate.value = _parseDate(lend['receiveDate'] ?? lend['giveDate']);
    returnDate.value = _parseDate(lend['returnDate'] ?? lend['repaymentDate']);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    final parts = text.split('-');
    if (parts.length != 3) return null;
    try {
      if (parts[0].length == 4) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } on FormatException {
      return null;
    }
  }

  // Select give date
  Future<void> selectGiveDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: giveDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    giveDate.value = picked;

    // Reset return date if it is before the give date.
    if (returnDate.value != null &&
        returnDate.value!.isBefore(picked)) {
      returnDate.value = null;

      _showMessage(
        'Return Date Reset',
        'Please select a return date on or after the give date.',
      );
    }
  }

  // Select return date
  Future<void> selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          returnDate.value ?? giveDate.value ?? DateTime.now(),
      firstDate: giveDate.value ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      returnDate.value = picked;
    }
  }

  // Submit lending details
  Future<void> postLend() async {
    if (isLoading.value) return;

    final String person = personController.text.trim();
    final String phone = phoneController.text.trim();
    final String amountText = amountController.text.trim();
    final String interestText = interestController.text.trim();

    // Validate person name
    if (person.isEmpty) {
      _showMessage('Required', 'Please enter the person name.');
      return;
    }

    // Validate phone number
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showMessage(
        'Invalid Phone',
        'Please enter a valid 10-digit mobile number.',
      );
      return;
    }

    // Validate amount
    final double? amount = double.tryParse(amountText);

    if (amount == null || !amount.isFinite || amount <= 0) {
      _showMessage(
        'Invalid Amount',
        'Please enter an amount greater than zero.',
      );
      return;
    }

    // Validate interest rate
    final double? interest = double.tryParse(interestText);

    if (interestText.isEmpty ||
        interest == null ||
        !interest.isFinite ||
        interest < 0) {
      _showMessage(
        'Invalid Interest',
        'Please enter a valid interest rate.',
      );
      return;
    }

    // Validate dates
    final DateTime? give = giveDate.value;
    final DateTime? repayment = returnDate.value;

    if (give == null) {
      _showMessage('Required', 'Please select the give date.');
      return;
    }

    if (repayment == null) {
      _showMessage('Required', 'Please select the return date.');
      return;
    }

    if (repayment.isBefore(give)) {
      _showMessage(
        'Invalid Date',
        'Return date cannot be before give date.',
      );
      return;
    }

    if (isEditMode.value && editingLendId == null) {
      _showMessage(
        'Unable to update',
        'The selected lend record does not contain an ID.',
      );
      return;
    }

    try {
      isLoading.value = true;

      // All values are strings for multipart form-data.
      final Map<String, String> body = {
        'phone': phone,
        'receiveFrom': person,
        'amount': amount.toString(),
        'receiveDate': formatDate(give),
        'rateOfInterest': interest.toString(),
        'returnDate': formatDate(repayment),
        'description': descriptionController.text.trim(),
      };

      final requestUrl = isEditMode.value ? '$url/$editingLendId' : url;
      debugPrint('Lend API URL: $requestUrl');
      debugPrint('Lend request fields: ${jsonEncode(body)}');

      // Send form-data with the saved Bearer token.
      final http.Response response = isEditMode.value
          ? await apiService.put(
              requestUrl,
              Map<String, dynamic>.from(body),
            )
          : await apiService.postFormData(url, body);

      debugPrint('Lend API status: ${response.statusCode}');
      debugPrint('Lend API response: ${response.body}');

      dynamic decoded;

      try {
        decoded = response.body.isEmpty &&
                isEditMode.value &&
                response.statusCode >= 200 &&
                response.statusCode < 300
            ? {'status': 'success'}
            : jsonDecode(response.body);
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

      final String message =
          decoded['message']?.toString() ??
              'Unable to ${isEditMode.value ? 'update' : 'save'} lending details.';

      final bool success =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['status']?.toString().toLowerCase() ==
              'success';

      if (success) {
        _showMessage(
          'Success',
          decoded['message']?.toString() ??
              (isEditMode.value
                  ? 'Lending details updated.'
                  : 'Lending details saved.'),
        );

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

        debugPrint('Lend API errors: $errors');

        _showMessage(
          'Failed (${response.statusCode})',
          details.isNotEmpty ? details.join('\n') : message,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Post lend error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(
        'Error',
        'Unable to submit lending details. Please try again.',
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

    giveDate.value = null;
    returnDate.value = null;
    editingLendId = null;
    isEditMode.value = false;
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
