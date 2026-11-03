import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LoanPrepaymentController extends GetxController {
  LoanPrepaymentController({ApiService? apiService, Map<String, dynamic>? loan})
    : apiService = apiService ?? ApiService(),
      loan = loan ?? _loanFromArguments();

  final ApiService apiService;
  final Map<String, dynamic> loan;
  final accounts = <Map<String, dynamic>>[].obs;
  final selectedAccountUuid = RxnString();
  final isLoadingAccounts = false.obs;
  final isSubmitting = false.obs;
  final accountError = ''.obs;
  final prepaymentDate = DateTime.now().obs;
  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  final descriptionController = TextEditingController(
    text: 'Principal prepayment; resolve any partial installment first.',
  );

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
      (loan['nameOfLender'] ??
              loan['name_of_lender'] ??
              loan['lender_name'] ??
              loan['name'] ??
              'Loan')
          .toString()
          .trim();

  String get currency => (loan['currency'] ?? 'INR').toString().toUpperCase();

  String? get outstandingPrincipal {
    for (final key in const [
      'principal_outstanding',
      'outstanding_principal',
    ]) {
      final value = loan[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    if (isLoadingAccounts.value) return;
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
        items.whereType<Map>().map(Map<String, dynamic>.from).where((account) {
          final uuid = accountUuid(account);
          final status = account['status']?.toString().trim().toLowerCase();
          return uuid.isNotEmpty &&
              (status == null ||
                  status.isEmpty ||
                  status == 'active' ||
                  status == '1');
        }),
      );
      if (accounts.length == 1) {
        selectedAccountUuid.value = accountUuid(accounts.first);
      } else if (!accounts.any(
        (account) => accountUuid(account) == selectedAccountUuid.value,
      )) {
        selectedAccountUuid.value = null;
      }
    } on FormatException catch (error) {
      accountError.value = error.message;
      debugPrint('Unable to load prepayment accounts: ${error.message}');
    } catch (error, stackTrace) {
      accountError.value = 'Unable to load accounts. Please try again.';
      debugPrint('Unable to load prepayment accounts: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingAccounts.value = false;
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
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw FormatException(
        message ?? 'Unable to load accounts (${response.statusCode}).',
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

  String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> selectPrepaymentDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: prepaymentDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) prepaymentDate.value = picked;
  }

  Future<bool> submitPrepayment() async {
    if (isSubmitting.value) return false;
    if (loanUuid.isEmpty) {
      _showMessage(
        'Unable to record prepayment',
        'This loan does not have a valid UUID.',
      );
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      _showMessage('Invalid amount', 'Enter an amount greater than zero.');
      return false;
    }
    final sourceAccountUuid = selectedAccountUuid.value;
    if (sourceAccountUuid == null || sourceAccountUuid.isEmpty) {
      _showMessage('Required', 'Select the account paying this prepayment.');
      return false;
    }
    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      _showMessage('Required', 'Enter a description for this prepayment.');
      return false;
    }

    final reference = referenceController.text.trim();
    final requestBody = <String, dynamic>{
      'amount': amount.toStringAsFixed(2),
      'payment_date': formatDate(prepaymentDate.value),
      'source_account_uuid': sourceAccountUuid,
      'reference': reference,
      'description': description,
    };
    final encodedRequestBody = jsonEncode(requestBody);
    if (_pendingIdempotencyKey == null ||
        _pendingRequestBody != encodedRequestBody) {
      _pendingIdempotencyKey = ApiService.createIdempotencyKey();
      _pendingRequestBody = encodedRequestBody;
    }

    isSubmitting.value = true;
    try {
      final response = await apiService.postLoanPrepayment(
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
          'Prepayment recorded',
          payload['message']?.toString() ??
              'The principal prepayment was recorded successfully.',
        );
        return true;
      }

      if (response.statusCode == 400 || response.statusCode == 422) {
        _pendingIdempotencyKey = null;
        _pendingRequestBody = null;
      }
      final message =
          payload['message']?.toString() ??
          'Unable to record prepayment (${response.statusCode}).';
      final errors = _formatErrors(payload['errors']);
      _showMessage(
        'Prepayment failed',
        errors.isEmpty ? message : '$message\n$errors',
      );
    } on FormatException catch (error) {
      _showMessage('Server error', error.message);
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('Unable to record loan prepayment: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Connection error',
        'The server could not confirm this prepayment. Check your connection '
            'and try again; your form is unchanged.',
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to record loan prepayment: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Unable to record prepayment',
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
    amountController.dispose();
    referenceController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
