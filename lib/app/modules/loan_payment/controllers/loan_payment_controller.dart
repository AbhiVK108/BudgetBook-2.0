import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LoanPaymentController extends GetxController {
  LoanPaymentController({
    ApiService? apiService,
    Map<String, dynamic>? loan,
    String? initialInstallmentUuid,
  }) : apiService = apiService ?? ApiService(),
       loan = loan ?? _loanFromArguments(),
       _initialInstallmentUuid =
           initialInstallmentUuid ?? _installmentUuidFromArguments() {
    installments.assignAll(_readInstallments(this.loan));
    if (_initialInstallmentUuid != null &&
        installments.any(
          (installment) =>
              installmentUuid(installment) == _initialInstallmentUuid,
        )) {
      selectedInstallmentUuid.value = _initialInstallmentUuid;
    } else if (installments.length == 1) {
      selectedInstallmentUuid.value = installmentUuid(installments.first);
    }
  }

  final ApiService apiService;
  final Map<String, dynamic> loan;
  final String? _initialInstallmentUuid;
  final accounts = <Map<String, dynamic>>[].obs;
  final installments = <Map<String, dynamic>>[].obs;
  final selectedAccountUuid = RxnString();
  final selectedInstallmentUuid = RxnString();
  final isLoadingAccounts = false.obs;
  final isLoadingInstallments = false.obs;
  final isSubmitting = false.obs;
  final accountError = ''.obs;
  final installmentError = ''.obs;
  final paymentDate = DateTime.now().obs;
  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  final descriptionController = TextEditingController();

  String? _pendingIdempotencyKey;
  String? _pendingRequestBody;

  static Map<String, dynamic> _loanFromArguments() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      final value = arguments['loan'];
      if (value is Map) return Map<String, dynamic>.from(value);
      return Map<String, dynamic>.from(arguments);
    }
    return <String, dynamic>{};
  }

  static String? _installmentUuidFromArguments() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      final uuid = arguments['installment_uuid']?.toString().trim();
      if (uuid != null && uuid.isNotEmpty) return uuid;
    }
    return null;
  }

  static List<Map<String, dynamic>> _readInstallments(
    Map<String, dynamic> loan,
  ) {
    for (final key in const [
      'installments',
      'loan_installments',
      'installment_schedule',
      'repayment_schedule',
    ]) {
      final value = loan[key];
      dynamic records = value;
      if (records is Map) {
        records =
            records['items'] ??
            records['schedule'] ??
            records['installments'] ??
            records['loan_installments'] ??
            records['data'];
      }
      if (records is Map) records = records['items'];
      if (records is List) {
        return records.whereType<Map>().map(Map<String, dynamic>.from).where((
          item,
        ) {
          final uuid = (item['uuid'] ?? item['installment_uuid'])
              ?.toString()
              .trim();
          final statuses = [
            item['status'],
            item['payment_status'],
            item['state'],
          ].map((value) => value?.toString().trim().toLowerCase());
          return uuid != null &&
              uuid.isNotEmpty &&
              !statuses.any(
                (status) =>
                    status == 'paid' ||
                    status == 'completed' ||
                    status == 'settled',
              );
        }).toList();
      }
    }
    return [];
  }

  String get loanUuid =>
      (loan['uuid'] ?? loan['loan_uuid'] ?? loan['loanUuid'] ?? '')
          .toString()
          .trim();

  String get lenderName =>
      (loan['nameOfLender'] ?? loan['lender_name'] ?? loan['name'] ?? 'Loan')
          .toString()
          .trim();

  String get dueAmount =>
      (loan['dueAmount'] ??
              loan['due_amount'] ??
              loan['total_outstanding'] ??
              '')
          .toString();

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
    if (installments.isEmpty) loadInstallments();
  }

  Future<void> loadInstallments() async {
    if (isLoadingInstallments.value) return;
    if (loanUuid.isEmpty) {
      installmentError.value = 'This loan is missing its UUID.';
      return;
    }

    isLoadingInstallments.value = true;
    installmentError.value = '';
    try {
      final response = await apiService.getLoanSchedule(loanUuid);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          'Unable to load installments (${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned an invalid installment schedule.',
        );
      }
      if ((decoded is! Map && decoded is! List) ||
          (decoded is Map && decoded['success'] == false)) {
        throw const FormatException(
          'The installment schedule response was invalid.',
        );
      }

      final schedule = _scheduleFromResponse(decoded);
      if (schedule == null) {
        throw const FormatException(
          'The installment schedule response was invalid.',
        );
      }
      installments.assignAll(
        schedule.where(_isUnpaidInstallment).where((item) {
          final uuid = installmentUuid(item).trim();
          return uuid.isNotEmpty;
        }),
      );
      if (_initialInstallmentUuid != null &&
          installments.any(
            (item) => installmentUuid(item) == _initialInstallmentUuid,
          )) {
        selectedInstallmentUuid.value = _initialInstallmentUuid;
      } else if (installments.length == 1) {
        selectedInstallmentUuid.value = installmentUuid(installments.first);
      }
    } on FormatException catch (error) {
      installmentError.value = error.message;
      debugPrint('Unable to load loan installments: ${error.message}');
    } catch (error, stackTrace) {
      installmentError.value = 'Unable to load installments. Please try again.';
      debugPrint('Unable to load loan installments: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingInstallments.value = false;
    }
  }

  List<Map<String, dynamic>>? _scheduleFromResponse(dynamic response) {
    dynamic findItems(dynamic value, {bool allowEmpty = false}) {
      if (value is List) {
        final items = value.whereType<Map>().map(Map<String, dynamic>.from);
        if (allowEmpty) return items.toList();
        final installments = items.where(_hasInstallmentIdentity).toList();
        return installments.isEmpty ? null : installments;
      }
      if (value is! Map) return null;

      for (final key in const [
        'items',
        'schedule',
        'repayment_schedule',
        'installment_schedule',
        'installments',
        'loan_installments',
        'amortization_schedule',
        'rows',
      ]) {
        if (value.containsKey(key)) {
          final result = findItems(value[key], allowEmpty: true);
          if (result != null) return result;
        }
      }
      for (final key in const ['data', 'result', 'payload', 'loan']) {
        if (value.containsKey(key)) {
          final result = findItems(value[key], allowEmpty: allowEmpty);
          if (result != null) return result;
        }
      }
      for (final nestedValue in value.values) {
        final result = findItems(nestedValue);
        if (result != null) return result;
      }
      return null;
    }

    return findItems(response, allowEmpty: response is List);
  }

  bool _hasInstallmentIdentity(Map<String, dynamic> item) {
    final uuid = (item['uuid'] ?? item['installment_uuid'])?.toString().trim();
    return uuid != null &&
        uuid.isNotEmpty &&
        const [
          'installment_number',
          'installment_no',
          'sequence',
          'number',
          'due_date',
          'installment_date',
          'installment_amount',
          'due_amount',
          'status',
          'payment_status',
        ].any(item.containsKey);
  }

  bool _isUnpaidInstallment(Map<String, dynamic> installment) {
    final statuses = [
      installment['status'],
      installment['payment_status'],
      installment['state'],
    ].map((value) => value?.toString().trim().toLowerCase());
    return !statuses.any(
      (status) =>
          status == 'paid' || status == 'completed' || status == 'settled',
    );
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
      debugPrint('Unable to load loan payment accounts: ${error.message}');
    } catch (error, stackTrace) {
      accountError.value = 'Unable to load accounts. Please try again.';
      debugPrint('Unable to load loan payment accounts: $error');
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

  String installmentUuid(Map<String, dynamic> installment) =>
      (installment['uuid'] ?? installment['installment_uuid'] ?? '').toString();

  String installmentLabel(Map<String, dynamic> installment) {
    final sequence =
        installment['installment_number'] ??
        installment['installment_no'] ??
        installment['number'];
    final date =
        installment['due_date'] ??
        installment['installment_date'] ??
        installment['payment_date'];
    final amount =
        installment['due_amount'] ??
        installment['amount_due'] ??
        installment['amount'] ??
        installment['installment_amount'];
    final details = <String>[];
    if (sequence != null) details.add('Installment $sequence');
    if (date != null && date.toString().isNotEmpty) {
      details.add(date.toString());
    }
    if (amount != null && amount.toString().isNotEmpty) {
      details.add('₹${amount.toString()}');
    }
    return details.isEmpty ? 'Installment' : details.join(' · ');
  }

  String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> selectPaymentDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: paymentDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) paymentDate.value = picked;
  }

  Future<bool> submitPayment() async {
    if (isSubmitting.value) return false;
    if (loanUuid.isEmpty) {
      _showMessage('Unable to record payment', 'This loan has no valid UUID.');
      return false;
    }
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      _showMessage('Invalid amount', 'Enter an amount greater than zero.');
      return false;
    }
    final outstanding = double.tryParse(dueAmount);
    if (outstanding != null && outstanding > 0 && amount > outstanding) {
      _showMessage(
        'Amount exceeds balance',
        'Enter an amount no greater than your outstanding balance.',
      );
      return false;
    }
    final accountUuidValue = selectedAccountUuid.value;
    if (accountUuidValue == null || accountUuidValue.isEmpty) {
      _showMessage('Required', 'Select the account making this payment.');
      return false;
    }
    final installmentUuidValue = selectedInstallmentUuid.value;
    if (installmentUuidValue == null ||
        !installments.any(
          (installment) => installmentUuid(installment) == installmentUuidValue,
        )) {
      _showMessage('Required', 'Select an unpaid loan installment.');
      return false;
    }

    final reference = referenceController.text.trim();
    final description = descriptionController.text.trim();
    final requestBody = <String, dynamic>{
      'amount': amount.toStringAsFixed(2),
      'payment_date': formatDate(paymentDate.value),
      'source_account_uuid': accountUuidValue,
      'installment_uuid': installmentUuidValue,
      if (reference.isNotEmpty) 'reference': reference,
      if (description.isNotEmpty) 'description': description,
    };
    final encodedRequestBody = jsonEncode(requestBody);
    if (_pendingIdempotencyKey == null ||
        _pendingRequestBody != encodedRequestBody) {
      _pendingIdempotencyKey = ApiService.createIdempotencyKey();
      _pendingRequestBody = encodedRequestBody;
    }

    isSubmitting.value = true;
    try {
      final response = await apiService.postLoanPayment(
        loanUuid,
        requestBody,
        idempotencyKey: _pendingIdempotencyKey!,
      );
      dynamic decoded;
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
          'Payment recorded',
          payload['message']?.toString() ??
              'The loan payment was recorded successfully.',
        );
        return true;
      }
      if (response.statusCode == 400 || response.statusCode == 422) {
        _pendingIdempotencyKey = null;
        _pendingRequestBody = null;
      }
      final message =
          payload['message']?.toString() ??
          'Unable to record payment (${response.statusCode}).';
      _showMessage('Payment failed', _formatErrors(payload['errors'], message));
    } on FormatException catch (error) {
      _showMessage('Server error', error.message);
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('Unable to record loan payment: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Connection error',
        'The server could not confirm this payment. Check your connection '
            'and try again; your form is unchanged.',
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to record loan payment: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Unable to record payment',
        'Please try again. Your form is unchanged.',
      );
    } finally {
      isSubmitting.value = false;
    }
    return false;
  }

  String _formatErrors(dynamic errors, String fallback) {
    if (errors is List && errors.isNotEmpty) return errors.join('\n');
    if (errors is Map) {
      final messages = <String>[];
      errors.forEach((key, value) {
        if (value is List) {
          messages.addAll(value.map((item) => item.toString()));
        } else {
          messages.add(value.toString());
        }
      });
      if (messages.isNotEmpty) return '$fallback\n${messages.join('\n')}';
    }
    return fallback;
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
