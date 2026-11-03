import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LoanDisbursementController extends GetxController {
  LoanDisbursementController({
    ApiService? apiService,
    Map<String, dynamic>? loan,
  }) : apiService = apiService ?? ApiService(),
       loan = loan ?? _loanFromArguments();

  final ApiService apiService;
  final Map<String, dynamic> loan;
  final accounts = <Map<String, dynamic>>[].obs;
  final expenseCategories = <Map<String, dynamic>>[].obs;
  final selectedAccountUuid = RxnString();
  final selectedCategoryUuid = RxnString();
  final isLoadingAccounts = false.obs;
  final isLoadingCategories = false.obs;
  final isSubmitting = false.obs;
  final accountError = ''.obs;
  final categoryError = ''.obs;
  final disbursementDate = DateTime.now().obs;
  final grossAmountController = TextEditingController();
  final processingFeeController = TextEditingController();

  String? _pendingIdempotencyKey;
  String? _pendingRequestBody;

  static Map<String, dynamic> _loanFromArguments() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      final loan = arguments['loan'];
      if (loan is Map) return Map<String, dynamic>.from(loan);
      return Map<String, dynamic>.from(arguments);
    }
    return <String, dynamic>{};
  }

  String get loanUuid =>
      (loan['uuid'] ?? loan['loan_uuid'] ?? loan['loanUuid'] ?? '')
          .toString()
          .trim();

  String get lenderName =>
      (loan['nameOfLender'] ?? loan['lender_name'] ?? loan['name'] ?? 'Loan')
          .toString()
          .trim();

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
    loadExpenseCategories();
  }

  Future<void> loadAccounts() async {
    isLoadingAccounts.value = true;
    accountError.value = '';
    try {
      final response = await apiService.getAccounts();
      final payload = _decodePayload(response);
      final data = payload['data'];
      final items = data is Map ? data['items'] : data;
      if (items is! List) {
        throw const FormatException('The accounts response was invalid.');
      }
      accounts.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((item) {
          final uuid = accountUuid(item);
          final status = item['status']?.toString().toLowerCase();
          return uuid.isNotEmpty &&
              (status == null ||
                  status.isEmpty ||
                  status == 'active' ||
                  status == '1');
        }),
      );
      if (accounts.length == 1) {
        selectedAccountUuid.value = accountUuid(accounts.first);
      }
    } on FormatException catch (error) {
      accountError.value = error.message;
      debugPrint('Unable to load disbursement accounts: ${error.message}');
    } catch (error, stackTrace) {
      accountError.value = 'Unable to load accounts. Please try again.';
      debugPrint('Unable to load disbursement accounts: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  Future<void> loadExpenseCategories() async {
    isLoadingCategories.value = true;
    categoryError.value = '';
    try {
      final uri = Uri.parse(ApiService.categoriesUrl).replace(
        queryParameters: const {'type': 'expense'},
      );
      final response = await apiService.get(uri.toString());
      final payload = _decodePayload(response);
      final data = payload['data'];
      final items = data is Map ? data['items'] : data;
      if (items is! List) {
        throw const FormatException('The categories response was invalid.');
      }
      expenseCategories.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((item) {
          final uuid = categoryUuid(item);
          final status = item['status']?.toString().toLowerCase();
          final type = (item['type'] ?? item['category_type'])
              ?.toString()
              .toLowerCase();
          return uuid.isNotEmpty &&
              (type == null || type.isEmpty || type == 'expense') &&
              (status == null ||
                  status.isEmpty ||
                  status == 'active' ||
                  status == '1');
        }),
      );
      if (expenseCategories.length == 1) {
        selectedCategoryUuid.value = categoryUuid(expenseCategories.first);
      }
    } on FormatException catch (error) {
      categoryError.value = error.message;
      debugPrint('Unable to load disbursement categories: ${error.message}');
    } catch (error, stackTrace) {
      categoryError.value = 'Unable to load categories. Please try again.';
      debugPrint('Unable to load disbursement categories: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Map<String, dynamic> _decodePayload(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned an invalid response.');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map ||
        decoded['success'] != true) {
      final message = decoded is Map
          ? decoded['message']?.toString()
          : null;
      throw FormatException(
        message ?? 'Unable to load choices (${response.statusCode}).',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  String accountUuid(Map<String, dynamic> account) =>
      (account['uuid'] ?? account['account_uuid'] ?? '').toString();

  String accountLabel(Map<String, dynamic> account) {
    final name = (account['name'] ?? account['account_name'] ?? 'Account')
        .toString();
    final type = account['type']?.toString();
    return type == null || type.isEmpty ? name : '$name · $type';
  }

  String categoryUuid(Map<String, dynamic> category) =>
      (category['uuid'] ?? category['category_uuid'] ?? '').toString();

  String categoryLabel(Map<String, dynamic> category) =>
      (category['name'] ?? category['category_name'] ?? 'Expense category')
          .toString();

  String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> selectDisbursementDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: disbursementDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) disbursementDate.value = picked;
  }

  Future<bool> submitDisbursement() async {
    if (isSubmitting.value) return false;
    if (loanUuid.isEmpty) {
      _showMessage(
        'Unable to record disbursement',
        'This loan does not have a valid UUID.',
      );
      return false;
    }

    final grossAmount = double.tryParse(grossAmountController.text.trim());
    if (grossAmount == null || !grossAmount.isFinite || grossAmount <= 0) {
      _showMessage('Invalid amount', 'Enter a gross amount greater than zero.');
      return false;
    }
    final processingFee = processingFeeController.text.trim().isEmpty
        ? 0.0
        : double.tryParse(processingFeeController.text.trim());
    if (processingFee == null ||
        !processingFee.isFinite ||
        processingFee < 0) {
      _showMessage('Invalid fee', 'Enter a valid processing fee.');
      return false;
    }
    final feeCategoryUuid = selectedCategoryUuid.value;
    if (feeCategoryUuid == null || feeCategoryUuid.isEmpty) {
      _showMessage('Required', 'Choose an expense category for the fee.');
      return false;
    }
    final receivingAccountUuid = selectedAccountUuid.value;
    if (receivingAccountUuid == null || receivingAccountUuid.isEmpty) {
      _showMessage('Required', 'Choose the account receiving this loan.');
      return false;
    }

    final requestBody = <String, dynamic>{
      'gross_amount': grossAmount.toStringAsFixed(2),
      'processing_fee': processingFee.toStringAsFixed(2),
      'fee_category_uuid': feeCategoryUuid,
      'disbursement_date': formatDate(disbursementDate.value),
      'receiving_account_uuid': receivingAccountUuid,
    };
    final encodedRequestBody = jsonEncode(requestBody);
    if (_pendingIdempotencyKey == null ||
        _pendingRequestBody != encodedRequestBody) {
      _pendingIdempotencyKey = ApiService.createIdempotencyKey();
      _pendingRequestBody = encodedRequestBody;
    }

    isSubmitting.value = true;
    try {
      final response = await apiService.postLoanDisbursement(
        loanUuid,
        requestBody,
        idempotencyKey: _pendingIdempotencyKey!,
      );
      final dynamic decoded;
      try {
        decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      } on FormatException {
        throw const FormatException('The server returned an invalid response.');
      }
      final payload = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['success'] == true) {
        _pendingIdempotencyKey = null;
        _pendingRequestBody = null;
        Get.back(result: true);
        _showMessage(
          'Disbursement recorded',
          payload['message']?.toString() ??
              'The loan disbursement was recorded successfully.',
        );
        return true;
      }

      if (response.statusCode == 400 || response.statusCode == 422) {
        _pendingIdempotencyKey = null;
        _pendingRequestBody = null;
      }
      final message =
          payload['message']?.toString() ??
          'Unable to record disbursement (${response.statusCode}).';
      final errors = _formatErrors(payload['errors']);
      _showMessage('Disbursement failed', errors.isEmpty ? message : '$message\n$errors');
    } on FormatException catch (error) {
      _showMessage('Server error', error.message);
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('Unable to record loan disbursement: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Connection error',
        'The server could not confirm this disbursement. Check your connection '
        'and try again; your form is unchanged.',
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to record loan disbursement: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Unable to record disbursement',
        'Please try again. Your form is unchanged.',
      );
    } finally {
      isSubmitting.value = false;
    }
    return false;
  }

  String _formatErrors(dynamic errors) {
    if (errors is List) return errors.join('\n');
    if (errors is! Map) return '';
    final messages = <String>[];
    errors.forEach((key, value) {
      if (value is List) {
        messages.addAll(value.map((item) => item.toString()));
      } else {
        messages.add(value.toString());
      }
    });
    return messages.join('\n');
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

  @override
  void onClose() {
    grossAmountController.dispose();
    processingFeeController.dispose();
    super.onClose();
  }
}
