import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LendingRepaymentController extends GetxController {
  LendingRepaymentController({
    ApiService? apiService,
    Map<String, dynamic>? lending,
    this.isBorrowing = false,
  }) : apiService = apiService ?? ApiService(),
       lending = lending ?? _lendingFromArguments();

  final ApiService apiService;
  final Map<String, dynamic> lending;
  final bool isBorrowing;
  final accounts = <Map<String, dynamic>>[].obs;
  final selectedAccountUuid = RxnString();
  final isLoadingAccounts = false.obs;
  final accountError = ''.obs;
  final isSubmitting = false.obs;
  final repaymentDate = DateTime.now().obs;
  final amountController = TextEditingController();
  final referenceController = TextEditingController();

  String? _pendingIdempotencyKey;
  String? _pendingRequestBody;

  static Map<String, dynamic> _lendingFromArguments() {
    final arguments = Get.arguments;
    return arguments is Map
        ? Map<String, dynamic>.from(arguments)
        : <String, dynamic>{};
  }

  String get lendingUuid =>
      (lending['uuid'] ??
              lending['lending_uuid'] ??
              lending['borrowing_uuid'] ??
              lending['lendingUuid'] ??
              '')
          .toString()
          .trim();

  String get borrowerName {
    final name = isBorrowing
        ? lending['lender_name'] ??
              lending['person_name'] ??
              lending['receiveFrom'] ??
              lending['receive_from'] ??
              lending['name']
        : lending['person_name'] ??
              lending['borrower_name'] ??
              lending['receiveFrom'] ??
              lending['givenTo'] ??
              lending['name'];
    return name?.toString() ?? (isBorrowing ? 'Borrowing' : 'Lending');
  }

  String get currency =>
      (lending['currency'] ?? 'INR').toString().toUpperCase();

  String get outstandingAmount =>
      (lending['total_outstanding'] ??
              lending['principal_outstanding'] ??
              lending['due_amount'] ??
              lending['outstanding_amount'] ??
              lending['amount'] ??
              '0.00')
          .toString();

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    isLoadingAccounts.value = true;
    accountError.value = '';
    try {
      final response = await apiService.getAccounts();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _readMessage(response.body) ??
              'Unable to load receiving accounts (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      final dataValue = decoded is Map ? decoded['data'] : null;
      final items = dataValue is Map ? dataValue['items'] : dataValue;
      if (decoded is! Map || decoded['success'] != true || items is! List) {
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
      }
    } on FormatException catch (error) {
      accountError.value = error.message;
      debugPrint('Unable to load repayment accounts: ${error.message}');
    } catch (error, stackTrace) {
      accountError.value = 'Unable to load accounts. Please try again.';
      debugPrint('Unable to load repayment accounts: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingAccounts.value = false;
    }
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

  Future<void> selectRepaymentDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: repaymentDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) repaymentDate.value = picked;
  }

  Future<bool> submitRepayment() async {
    if (isSubmitting.value) return false;
    if (lendingUuid.isEmpty) {
      _showMessage(
        'Unable to record repayment',
        'This ${isBorrowing ? 'borrowing' : 'lending'} record does not have '
            'a valid identifier.',
      );
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      _showMessage('Invalid amount', 'Enter an amount greater than zero.');
      return false;
    }
    final receivingAccountUuid = selectedAccountUuid.value;
    if (receivingAccountUuid == null || receivingAccountUuid.isEmpty) {
      _showMessage(
        'Required',
        'Select the account ${isBorrowing ? 'paying' : 'receiving'} this repayment.',
      );
      return false;
    }

    final requestBody = <String, dynamic>{
      isBorrowing
          ? 'amount_paid'
          : 'amount_received': amount.toStringAsFixed(2),
      'repayment_date': formatDate(repaymentDate.value),
      isBorrowing
          ? 'source_account_uuid'
          : 'receiving_account_uuid': receivingAccountUuid,
      if (referenceController.text.trim().isNotEmpty)
        'reference': referenceController.text.trim(),
    };
    final encodedRequestBody = jsonEncode(requestBody);
    if (_pendingIdempotencyKey == null ||
        _pendingRequestBody != encodedRequestBody) {
      _pendingIdempotencyKey = ApiService.createIdempotencyKey();
      _pendingRequestBody = encodedRequestBody;
    }

    isSubmitting.value = true;
    try {
      final response = isBorrowing
          ? await apiService.postBorrowingRepayment(
              lendingUuid,
              requestBody,
              idempotencyKey: _pendingIdempotencyKey!,
            )
          : await apiService.postLendingRepayment(
              lendingUuid,
              requestBody,
              idempotencyKey: _pendingIdempotencyKey!,
            );
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final payload = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['success'] == true) {
        _pendingIdempotencyKey = null;
        _pendingRequestBody = null;
        final data = payload['data'];
        final repaymentResult = data is Map ? data['agreement'] : null;
        Get.back(result: repaymentResult is Map ? repaymentResult : true);
        Get.snackbar(
          'Repayment recorded',
          payload['message']?.toString() ??
              'The repayment was recorded successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      }

      if (response.statusCode == 400 || response.statusCode == 422) {
        _pendingIdempotencyKey = null;
        _pendingRequestBody = null;
      }
      final message =
          payload['message']?.toString() ??
          'Unable to record repayment (${response.statusCode}).';
      final errors = _formatErrors(payload['errors']);
      _showMessage(
        'Repayment failed',
        errors.isEmpty ? message : '$message\n$errors',
      );
    } on FormatException catch (error) {
      _showMessage('Server error', error.message);
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('Unable to record lending repayment: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Connection error',
        'The server could not confirm this repayment. Check your connection '
            'and try again; your form is unchanged.',
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to record lending repayment: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Unable to record repayment',
        'Please try again. Your form is unchanged.',
      );
    } finally {
      isSubmitting.value = false;
    }
    return false;
  }

  String? _readMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded['message']?.toString() : null;
    } on FormatException {
      return null;
    }
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
    super.onClose();
  }
}
