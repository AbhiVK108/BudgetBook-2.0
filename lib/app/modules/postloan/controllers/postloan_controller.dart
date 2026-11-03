import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PostloanController extends GetxController {
  PostloanController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;
  static const loanTypes = <String>[
    'home',
    'personal',
    'auto',
    'education',
    'business',
    'other',
  ];

  final loanNameController = TextEditingController();
  final lenderNameController = TextEditingController();
  final lenderReferenceController = TextEditingController();
  final sanctionedAmountController = TextEditingController();
  final principalAmountController = TextEditingController();
  final annualInterestRateController = TextEditingController();
  final tenureMonthsController = TextEditingController();
  final notesController = TextEditingController();

  final selectedLoanType = 'home'.obs;
  final firstDueDate = Rxn<DateTime>();
  final accounts = <Map<String, dynamic>>[].obs;
  final expenseCategories = <Map<String, dynamic>>[].obs;
  final selectedAccountUuid = RxnString();
  final selectedExpenseCategoryUuid = RxnString();
  final isLoadingAccounts = false.obs;
  final isLoadingCategories = false.obs;
  final accountLoadError = ''.obs;
  final categoryLoadError = ''.obs;
  final isLoading = false.obs;
  String? _pendingIdempotencyKey;
  String? _pendingRequestBody;

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
    loadExpenseCategories();
  }

  @override
  void onClose() {
    loanNameController.dispose();
    lenderNameController.dispose();
    lenderReferenceController.dispose();
    sanctionedAmountController.dispose();
    principalAmountController.dispose();
    annualInterestRateController.dispose();
    tenureMonthsController.dispose();
    notesController.dispose();
    super.onClose();
  }

  String accountUuid(Map<String, dynamic> account) =>
      (account['uuid'] ?? account['account_uuid'])?.toString() ?? '';

  String accountName(Map<String, dynamic> account) =>
      (account['name'] ?? account['account_name'] ?? 'Account').toString();

  String categoryUuid(Map<String, dynamic> category) =>
      (category['uuid'] ?? category['category_uuid'])?.toString() ?? '';

  String categoryName(Map<String, dynamic> category) =>
      (category['name'] ?? category['category_name'] ?? 'Expense category')
          .toString();

  Future<void> loadAccounts() async {
    isLoadingAccounts.value = true;
    accountLoadError.value = '';
    try {
      final response = await apiService.getAccounts();
      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(decoded, 'Unable to load repayment accounts.'),
        );
      }
      final items = _itemsFrom(decoded['data']);
      if (items == null) {
        throw const FormatException('Unexpected accounts response.');
      }
      accounts.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((account) {
          final uuid = accountUuid(account).trim();
          final status = account['status']?.toString().toLowerCase();
          return uuid.isNotEmpty &&
              (status == null || status == 'active' || status == '1');
        }),
      );
      if (accounts.isNotEmpty &&
          !accounts.any(
            (account) => accountUuid(account) == selectedAccountUuid.value,
          )) {
        selectedAccountUuid.value = accountUuid(accounts.first);
      }
    } catch (error, stackTrace) {
      accountLoadError.value = error is FormatException
          ? error.message
          : 'Unable to load repayment accounts. Please retry.';
      debugPrint('Unable to load loan repayment accounts: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingAccounts.value = false;
    }
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
      expenseCategories.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((category) {
          final uuid = categoryUuid(category).trim();
          final type =
              (category['category_type'] ??
                      category['categoryType'] ??
                      category['type'])
                  ?.toString()
                  .toLowerCase();
          final status = category['status']?.toString().toLowerCase();
          return uuid.isNotEmpty &&
              (type == null || type == 'expense') &&
              (status == null || status == 'active' || status == '1');
        }),
      );
      if (expenseCategories.isNotEmpty &&
          !expenseCategories.any(
            (category) =>
                categoryUuid(category) == selectedExpenseCategoryUuid.value,
          )) {
        selectedExpenseCategoryUuid.value = categoryUuid(
          expenseCategories.first,
        );
      }
    } catch (error, stackTrace) {
      categoryLoadError.value = error is FormatException
          ? error.message
          : 'Unable to load expense categories. Please retry.';
      debugPrint('Unable to load loan interest categories: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> selectFirstDueDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: firstDueDate.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) firstDueDate.value = picked;
  }

  String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<bool> postLoan() async {
    if (isLoading.value) return false;
    final name = loanNameController.text.trim();
    final lender = lenderNameController.text.trim();
    final sanctioned = double.tryParse(sanctionedAmountController.text.trim());
    final principal = double.tryParse(principalAmountController.text.trim());
    final annualRate = double.tryParse(
      annualInterestRateController.text.trim(),
    );
    final tenure = int.tryParse(tenureMonthsController.text.trim());

    if (name.isEmpty || lender.isEmpty) {
      _showMessage('Required', 'Enter the loan name and lender name.');
      return false;
    }
    if (sanctioned == null || !sanctioned.isFinite || sanctioned <= 0) {
      _showMessage(
        'Invalid amount',
        'Enter a sanctioned amount greater than zero.',
      );
      return false;
    }
    if (principal == null ||
        !principal.isFinite ||
        principal <= 0 ||
        principal > sanctioned) {
      _showMessage(
        'Invalid principal',
        'Enter a principal amount greater than zero and no more than the sanctioned amount.',
      );
      return false;
    }
    if (annualRate == null || !annualRate.isFinite || annualRate < 0) {
      _showMessage(
        'Invalid interest rate',
        'Enter a valid annual interest rate.',
      );
      return false;
    }
    if (tenure == null || tenure <= 0) {
      _showMessage('Invalid tenure', 'Enter the loan tenure in months.');
      return false;
    }
    if (firstDueDate.value == null) {
      _showMessage('Required', 'Select the first due date.');
      return false;
    }
    final accountUuid = selectedAccountUuid.value;
    if (accountUuid == null || accountUuid.isEmpty) {
      _showMessage('Required', 'Select a repayment account.');
      return false;
    }
    final categoryUuid = selectedExpenseCategoryUuid.value;
    if (categoryUuid == null || categoryUuid.isEmpty) {
      _showMessage('Required', 'Select an interest expense category.');
      return false;
    }

    final body = <String, dynamic>{
      'loan_type': selectedLoanType.value,
      'name': name,
      'lender_name': lender,
      'lender_reference': lenderReferenceController.text.trim(),
      'sanctioned_amount': sanctioned.toStringAsFixed(2),
      'principal_amount': principal.toStringAsFixed(2),
      'currency': 'INR',
      'annual_interest_rate': annualRate.toStringAsFixed(4),
      'tenure_months': tenure,
      'first_due_date': formatDate(firstDueDate.value!),
      'repayment_account_uuid': accountUuid,
      'interest_category_uuid': categoryUuid,
      'notes': notesController.text.trim(),
    };
    final requestBody = jsonEncode(body);
    if (_pendingRequestBody != requestBody) {
      _pendingRequestBody = requestBody;
      _pendingIdempotencyKey = ApiService.createIdempotencyKey();
    }

    isLoading.value = true;
    try {
      late http.Response response;
      try {
        response = await apiService.postLoan(
          body,
          idempotencyKey: _pendingIdempotencyKey!,
        );
      } on http.ClientException {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        response = await apiService.postLoan(
          body,
          idempotencyKey: _pendingIdempotencyKey!,
        );
      }
      final decoded = _decodeResponse(response);
      final success =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['success'] == true;
      final message = _responseMessage(
        decoded,
        success ? 'Loan created successfully.' : 'Unable to save loan.',
      );
      if (success) {
        _pendingRequestBody = null;
        _pendingIdempotencyKey = null;
        _showMessage('Success', message);
        Get.back(result: true);
        return true;
      }
      _showMessage('Unable to save loan', _errorDetails(decoded, message));
      return false;
    } on FormatException catch (error) {
      _showMessage('Server error', error.message);
      return false;
    } catch (error, stackTrace) {
      debugPrint('Unable to submit loan: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Network error', 'Unable to save loan. Please retry.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw const FormatException('The server returned an empty response.');
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned invalid JSON.');
    }
    if (decoded is! Map) {
      throw const FormatException('The server response was invalid.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  List<dynamic>? _itemsFrom(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return null;
  }

  String _responseMessage(Map<String, dynamic> decoded, String fallback) {
    final message = decoded['message']?.toString().trim();
    return message == null || message.isEmpty ? fallback : message;
  }

  String _errorDetails(Map<String, dynamic> decoded, String fallback) {
    final errors = decoded['errors'];
    if (errors is! Map) return fallback;
    return errors.entries
        .map((entry) {
          final value = entry.value;
          return '${entry.key}: ${value is List ? value.join(', ') : value}';
        })
        .join('\n');
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}
