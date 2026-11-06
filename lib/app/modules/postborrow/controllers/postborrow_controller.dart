import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PostborrowController extends GetxController {
  PostborrowController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;
  final categories = <Map<String, dynamic>>[].obs;
  final accounts = <Map<String, dynamic>>[].obs;
  final isLoadingCategories = false.obs;
  final isLoadingAccounts = false.obs;
  final isCreatingCategory = false.obs;
  final categoryLoadError = ''.obs;
  final accountLoadError = ''.obs;
  final selectedInterestCategoryUuid = RxnString();
  final selectedReceivingAccountUuid = RxnString();
  final interestMethod = 'fixed'.obs;
  final Rx<DateTime?> receiveDate = Rx<DateTime?>(null);
  final Rx<DateTime?> returnDate = Rx<DateTime?>(null);
  final RxBool isLoading = false.obs;

  String? _pendingBorrowingIdempotencyKey;
  String? _pendingBorrowingRequestBody;

  final TextEditingController personController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController interestController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadExpenseCategories();
    loadReceivingAccounts();
  }

  String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> loadExpenseCategories() async {
    isLoadingCategories.value = true;
    categoryLoadError.value = '';
    try {
      final uri = Uri.parse(
        ApiService.categoriesUrl,
      ).replace(queryParameters: {'type': 'expense'});
      final response = await apiService.get(uri.toString());
      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(decoded, 'Unable to load expense categories.'),
        );
      }
      final items = _itemsFrom(decoded['data']);
      if (items == null) {
        throw const FormatException('Unexpected expense categories response.');
      }
      categories.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((item) {
          final uuid = (item['uuid'] ?? item['category_uuid'])
              ?.toString()
              .trim();
          final type =
              (item['category_type'] ?? item['categoryType'] ?? item['type'])
                  ?.toString()
                  .trim()
                  .toLowerCase();
          final status = item['status']?.toString().trim().toLowerCase();
          return uuid != null &&
              uuid.isNotEmpty &&
              (type == null || type == 'expense') &&
              (status == null || status == '1' || status == 'active');
        }),
      );
      if (categories.length == 1) {
        selectedInterestCategoryUuid.value = categoryUuid(categories.first);
      }
    } catch (error) {
      categoryLoadError.value = error is FormatException
          ? error.message
          : 'Failed to load expense categories. Please try again.';
      debugPrint('BORROWING CATEGORY LOAD ERROR: $error');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> loadReceivingAccounts() async {
    isLoadingAccounts.value = true;
    accountLoadError.value = '';
    try {
      final response = await apiService.getAccounts();
      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(decoded, 'Unable to load accounts.'),
        );
      }
      final items = _itemsFrom(decoded['data']);
      if (items == null) {
        throw const FormatException('Unexpected accounts response.');
      }
      accounts.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((item) {
          final uuid = (item['uuid'] ?? item['account_uuid'])
              ?.toString()
              .trim();
          final status = item['status']?.toString().trim().toLowerCase();
          return uuid != null &&
              uuid.isNotEmpty &&
              (status == null || status == 'active' || status == '1');
        }),
      );
      if (accounts.length == 1) {
        selectedReceivingAccountUuid.value = accountUuid(accounts.first);
      }
    } catch (error) {
      accountLoadError.value = error is FormatException
          ? error.message
          : 'Failed to load accounts. Please try again.';
      debugPrint('BORROWING ACCOUNT LOAD ERROR: $error');
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  Future<Map<String, dynamic>?> createExpenseCategory({
    required String name,
    required String icon,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || isCreatingCategory.value) return null;

    try {
      isCreatingCategory.value = true;
      final response = await apiService.postCategory({
        'name': trimmedName,
        'type': 'expense',
        'icon': icon,
        'sort_order': 100,
      });
      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        return null;
      }

      final data = decoded['data'];
      if (data is! Map) return null;
      final category = Map<String, dynamic>.from(data);
      final uuid = categoryUuid(category);
      if (uuid.isEmpty) return null;

      categories.add(category);
      selectedInterestCategoryUuid.value = uuid;
      return category;
    } catch (error) {
      debugPrint('BORROWING CATEGORY CREATE ERROR: $error');
      return null;
    } finally {
      isCreatingCategory.value = false;
    }
  }

  List<dynamic>? _itemsFrom(dynamic value) {
    if (value is List) return value;
    if (value is Map && value['items'] is List) {
      return value['items'] as List<dynamic>;
    }
    return null;
  }

  String categoryUuid(Map<String, dynamic> category) =>
      (category['uuid'] ?? category['category_uuid'])?.toString() ?? '';

  String categoryName(Map<String, dynamic> category) =>
      (category['name'] ??
              category['category_name'] ??
              category['categoryName'])
          ?.toString() ??
      'Expense category';

  String accountUuid(Map<String, dynamic> account) =>
      (account['uuid'] ?? account['account_uuid'])?.toString() ?? '';

  String accountName(Map<String, dynamic> account) =>
      (account['name'] ?? account['account_name'])?.toString() ?? 'Account';

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw const FormatException('Empty response from server.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Unexpected server response.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _responseMessage(Map<String, dynamic> decoded, String fallback) {
    final message = decoded['message']?.toString().trim();
    return message == null || message.isEmpty ? fallback : message;
  }

  Future<void> selectReceiveDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: receiveDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    receiveDate.value = picked;
    if (returnDate.value != null && returnDate.value!.isBefore(picked)) {
      returnDate.value = null;
      _showMessage(
        'Return Date Reset',
        'Please select a return date on or after the borrowing date.',
      );
    }
  }

  Future<void> selectReturnDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: returnDate.value ?? receiveDate.value ?? DateTime.now(),
      firstDate: receiveDate.value ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) returnDate.value = picked;
  }

  Future<void> postBorrow() async {
    if (isLoading.value) return;

    final person = personController.text.trim();
    final phone = phoneController.text.trim();
    final amountText = amountController.text.trim();
    final interestText = interestController.text.trim();
    final amount = double.tryParse(amountText);
    final interest = double.tryParse(interestText);
    final received = receiveDate.value;
    final repayment = returnDate.value;

    if (person.isEmpty) {
      _showMessage('Required', 'Please enter the lender name.');
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showMessage(
        'Invalid Phone',
        'Enter a valid 10-digit mobile number, or leave it blank.',
      );
      return;
    }
    if (amount == null || !amount.isFinite || amount <= 0) {
      _showMessage(
        'Invalid Amount',
        'Please enter an amount greater than zero.',
      );
      return;
    }
    if (interestText.isEmpty ||
        interest == null ||
        !interest.isFinite ||
        interest < 0) {
      _showMessage(
        'Invalid Interest',
        'Please enter a valid fixed interest amount (zero or more).',
      );
      return;
    }
    if (received == null) {
      _showMessage('Required', 'Please select the borrowing date.');
      return;
    }
    if (repayment == null) {
      _showMessage('Required', 'Please select the expected repayment date.');
      return;
    }
    if (repayment.isBefore(received)) {
      _showMessage(
        'Invalid Date',
        'Repayment date cannot be before the borrowing date.',
      );
      return;
    }
    if (selectedInterestCategoryUuid.value?.isNotEmpty != true) {
      _showMessage(
        'Required',
        'Please select an expense category for interest.',
      );
      return;
    }
    if (selectedReceivingAccountUuid.value?.isNotEmpty != true) {
      _showMessage('Required', 'Please select the receiving account.');
      return;
    }

    try {
      isLoading.value = true;
      final body = <String, dynamic>{
        'lender_name': person,
        'principal_amount': amount.toStringAsFixed(2),
        'borrowing_date': formatDate(received),
        'interest_method': interestMethod.value,
        'fixed_interest_amount': interest.toStringAsFixed(2),
        'interest_category_uuid': selectedInterestCategoryUuid.value!,
        'expected_repayment_date': formatDate(repayment),
        'receiving_account_uuid': selectedReceivingAccountUuid.value!,
        'notes': descriptionController.text.trim(),
        if (phone.isNotEmpty) 'lender_phone': phone,
      };
      final encodedBody = jsonEncode(body);
      if (_pendingBorrowingIdempotencyKey == null ||
          _pendingBorrowingRequestBody != encodedBody) {
        _pendingBorrowingIdempotencyKey = ApiService.createIdempotencyKey();
        _pendingBorrowingRequestBody = encodedBody;
      }

      debugPrint('Borrowing API URL: ${ApiService.borrowingUrl}');
      debugPrint('Borrowing request body: $encodedBody');
      final response = await apiService.postBorrowing(
        body,
        idempotencyKey: _pendingBorrowingIdempotencyKey!,
      );
      debugPrint('Borrowing API status: ${response.statusCode}');
      debugPrint('Borrowing API response: ${response.body}');

      final Map<String, dynamic> decoded;
      try {
        decoded = _decodeResponse(response);
      } on FormatException catch (error) {
        _showMessage('Server Error', error.message);
        return;
      }

      final message = _responseMessage(
        decoded,
        'Unable to save borrowing details.',
      );
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['success'] == true) {
        _showMessage('Success', message);
        clearForm();
        _pendingBorrowingIdempotencyKey = null;
        _pendingBorrowingRequestBody = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.key.currentState?.canPop() ?? false) {
            Get.back(result: true);
          }
        });
        return;
      }

      final errors = decoded['errors'];
      final details = <String>[];
      if (errors is Map) {
        errors.forEach((key, value) {
          if (value is List) {
            details.addAll(value.map((item) => item.toString()));
          } else {
            details.add(value.toString());
          }
        });
      } else if (errors is List) {
        details.addAll(errors.map((item) => item.toString()));
      }
      debugPrint('Borrowing API errors: $errors');
      _showMessage(
        'Failed (${response.statusCode})',
        details.isNotEmpty ? details.join('\n') : message,
      );
    } catch (error, stackTrace) {
      debugPrint('Post borrowing error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Error',
        'Unable to submit borrowing details. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
    );
  }

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
