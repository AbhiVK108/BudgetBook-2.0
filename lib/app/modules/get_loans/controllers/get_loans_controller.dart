import 'dart:convert';

import 'package:budget_book_2026/app/core/constants/api_endpoints.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class GetLoansController extends GetxController {
  static const String url = ApiEndpoints.legacyLoansUrl;
  static const int paymentPageSize = 20;

  GetLoansController({
    ApiService? apiService,
    Map<String, dynamic>? initialLoan,
  }) : apiService = apiService ?? ApiService(),
       _initialLoan = initialLoan;

  final ApiService apiService;
  final Map<String, dynamic>? _initialLoan;

  final RxMap<String, dynamic> loan = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> schedule = <Map<String, dynamic>>[].obs;
  Map<String, dynamic>? focusInstallment;
  String focusInstallmentType = '';

  final RxBool isLoading = false.obs;
  final RxBool isLoadingSchedule = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isDeleting = false.obs;
  final RxString loadError = ''.obs;
  final RxString scheduleError = ''.obs;
  final RxList<Map<String, dynamic>> payments = <Map<String, dynamic>>[].obs;
  final scheduleSectionKey = GlobalKey();
  final paymentHistorySectionKey = GlobalKey();
  final RxBool isLoadingPayments = false.obs;
  final RxBool isLoadingMorePayments = false.obs;
  final RxString paymentError = ''.obs;
  final RxString paymentLoadMoreError = ''.obs;
  final RxInt currentPaymentPage = 0.obs;
  final RxInt lastPaymentPage = 1.obs;
  final RxInt totalPayments = 0.obs;

  int _paymentRequestGeneration = 0;

  bool get hasMorePayments => currentPaymentPage.value < lastPaymentPage.value;

  String? get loanId =>
      (loan['id'] ?? loan['uuid'] ?? loan['loanId'] ?? loan['loan_id'])
          ?.toString();

  String? get loanUuid =>
      (loan['uuid'] ?? loan['loan_uuid'] ?? loan['loanUuid'])
          ?.toString()
          .trim();

  @override
  void onInit() {
    super.onInit();

    final argument = _initialLoan ?? Get.arguments;

    if (argument is Map) {
      final initialValues = Map<String, dynamic>.from(argument);
      final focusedInstallment = initialValues.remove('focus_installment');
      focusInstallment = focusedInstallment is Map
          ? Map<String, dynamic>.from(focusedInstallment)
          : null;
      focusInstallmentType =
          initialValues.remove('focus_installment_type')?.toString() ?? '';
      loan.assignAll(initialValues);
    }

    fetchLoan();
    if (loanUuid?.isNotEmpty == true) {
      fetchSchedule();
      fetchPayments();
    }
  }

  Future<void> refreshDetails() async {
    await Future.wait([fetchLoan(), fetchSchedule(), fetchPayments()]);
  }

  Future<void> fetchSchedule() async {
    final uuid = loanUuid;
    if (uuid == null || uuid.isEmpty) {
      scheduleError.value = 'This loan is missing its UUID.';
      return;
    }
    if (isLoadingSchedule.value) return;

    try {
      isLoadingSchedule.value = true;
      scheduleError.value = '';

      final response = await apiService.getLoanSchedule(uuid);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Failed to fetch the loan schedule (${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned an invalid loan schedule.',
        );
      }
      if ((decoded is! Map && decoded is! List) ||
          (decoded is Map && decoded['success'] == false)) {
        throw FormatException(
          _responseMessage(response.body) ??
              'The loan schedule response was invalid.',
        );
      }

      final items = _scheduleFromResponse(decoded);
      if (items == null) {
        throw const FormatException('The loan schedule response was invalid.');
      }
      schedule.assignAll(items);
    } on FormatException catch (error) {
      debugPrint('Fetch loan schedule error: ${error.message}');
      scheduleError.value = error.message;
    } catch (error, stackTrace) {
      debugPrint('Fetch loan schedule error: $error');
      debugPrintStack(stackTrace: stackTrace);
      scheduleError.value = 'Unable to load the loan schedule. Please retry.';
    } finally {
      isLoadingSchedule.value = false;
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

      for (final key in [
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

  Future<void> fetchPayments() async {
    final uuid = loanUuid;
    if (uuid == null || uuid.isEmpty) {
      paymentError.value = 'This loan is missing its UUID.';
      return;
    }

    final generation = ++_paymentRequestGeneration;
    isLoadingPayments.value = true;
    paymentError.value = '';
    paymentLoadMoreError.value = '';
    try {
      final page = await _fetchPaymentPage(uuid, 1);
      if (generation != _paymentRequestGeneration) return;
      payments.assignAll(page.items);
      currentPaymentPage.value = page.currentPage;
      lastPaymentPage.value = page.lastPage;
      totalPayments.value = page.total;
    } on FormatException catch (error) {
      if (generation == _paymentRequestGeneration) {
        paymentError.value = error.message;
      }
      debugPrint('Fetch loan payment history error: ${error.message}');
    } catch (error, stackTrace) {
      if (generation == _paymentRequestGeneration) {
        paymentError.value = 'Unable to load payment history. Please retry.';
      }
      debugPrint('Fetch loan payment history error: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (generation == _paymentRequestGeneration) {
        isLoadingPayments.value = false;
      }
    }
  }

  Future<void> loadMorePayments() async {
    if (isLoadingPayments.value ||
        isLoadingMorePayments.value ||
        !hasMorePayments) {
      return;
    }

    final uuid = loanUuid;
    if (uuid == null || uuid.isEmpty) {
      paymentLoadMoreError.value = 'This loan is missing its UUID.';
      return;
    }

    final generation = _paymentRequestGeneration;
    isLoadingMorePayments.value = true;
    paymentLoadMoreError.value = '';
    try {
      final page = await _fetchPaymentPage(uuid, currentPaymentPage.value + 1);
      if (generation != _paymentRequestGeneration) return;
      final knownIds = payments.map(_paymentId).whereType<String>().toSet();
      payments.addAll(
        page.items.where((payment) {
          final id = _paymentId(payment);
          return id == null || knownIds.add(id);
        }),
      );
      currentPaymentPage.value = page.currentPage;
      lastPaymentPage.value = page.lastPage;
      totalPayments.value = page.total;
    } on FormatException catch (error) {
      if (generation == _paymentRequestGeneration) {
        paymentLoadMoreError.value = error.message;
      }
      debugPrint('Load more loan payments error: ${error.message}');
    } catch (error, stackTrace) {
      if (generation == _paymentRequestGeneration) {
        paymentLoadMoreError.value =
            'Unable to load more payments. Please retry.';
      }
      debugPrint('Load more loan payments error: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingMorePayments.value = false;
    }
  }

  Future<_LoanPaymentPage> _fetchPaymentPage(String uuid, int page) async {
    final response = await apiService.getLoanPayments(
      uuid,
      page: page,
      perPage: paymentPageSize,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
        _responseMessage(response.body) ??
            'Failed to fetch payment history (${response.statusCode}).',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException(
        'The server returned invalid payment history.',
      );
    }
    if (decoded is! Map ||
        (decoded['success'] != true &&
            decoded['status']?.toString().toLowerCase() != 'success')) {
      throw FormatException(
        _responseMessage(response.body) ??
            'The payment history response was invalid.',
      );
    }

    dynamic data = decoded['data'] ?? decoded['payments'];
    Map<dynamic, dynamic>? paginationValue;
    while (data is Map) {
      if (data['pagination'] is Map) {
        paginationValue = data['pagination'] as Map;
      }
      final items =
          data['items'] ?? data['payments'] ?? data['payment_history'];
      if (items is List) {
        data = items;
        break;
      }
      if (data['data'] is Map || data['data'] is List) {
        data = data['data'];
      } else {
        throw const FormatException(
          'The payment history response was invalid.',
        );
      }
    }
    if (data is! List) {
      throw const FormatException('The payment history response was invalid.');
    }

    final items = <Map<String, dynamic>>[];
    for (final item in data) {
      if (item is! Map) {
        throw const FormatException(
          'The payment history contained invalid data.',
        );
      }
      items.add(Map<String, dynamic>.from(item));
    }

    paginationValue ??= decoded['pagination'] is Map
        ? decoded['pagination'] as Map
        : null;
    final pagination = paginationValue == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(paginationValue);
    return _LoanPaymentPage(
      items: items,
      currentPage: _positiveInt(pagination['current_page'], page),
      lastPage: _positiveInt(pagination['last_page'], page),
      total: _nonNegativeInt(pagination['total'], items.length),
    );
  }

  String? _paymentId(Map<String, dynamic> payment) {
    final value = payment['uuid'] ?? payment['id'] ?? payment['payment_uuid'];
    final id = value?.toString().trim();
    return id == null || id.isEmpty ? null : id;
  }

  int _positiveInt(dynamic value, int fallback) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : fallback;
  }

  int _nonNegativeInt(dynamic value, int fallback) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed >= 0 ? parsed : fallback;
  }

  String paymentValue(
    Map<String, dynamic> payment,
    List<String> keys, {
    String fallback = '—',
  }) {
    for (final key in keys) {
      final value = payment[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  // ================= FETCH LOAN =================

  Future<void> fetchLoan() async {
    if (isLoading.value) return;

    final id = loanUuid ?? loanId;

    if (id == null || id.isEmpty) {
      loadError.value = 'The selected loan has no ID.';
      return;
    }

    try {
      isLoading.value = true;
      loadError.value = '';

      final response = await apiService.getLoanByUuid(id);
      if (kDebugMode) {
        debugPrint('Fetch loan raw response: ${response.body}');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Failed to load loan details (${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException('The server returned invalid loan data.');
      }
      if (decoded is! Map ||
          (decoded['success'] != true &&
              decoded['status']?.toString().toLowerCase() != 'success')) {
        throw FormatException(
          _responseMessage(response.body) ??
              'The loan details response was invalid.',
        );
      }

      final data = decoded['data'];
      final recordValue = data is Map ? data['loan'] ?? data : null;
      if (recordValue is! Map) {
        throw const FormatException('The loan details response was invalid.');
      }
      final record = Map<String, dynamic>.from(recordValue);
      final responseId = _getId(record);
      if (responseId != null && responseId != id) {
        throw const FormatException(
          'The server returned details for a different loan.',
        );
      }
      loan.assignAll(record);
    } on FormatException catch (error) {
      loadError.value = error.message;
      debugPrint('Fetch loan error: ${error.message}');
    } catch (error) {
      loadError.value = 'Unable to load loan details.';
      debugPrint('Fetch loan error: $error');
    } finally {
      isLoading.value = false;
    }
  }

  String? _getId(Map<String, dynamic> record) =>
      (record['id'] ??
              record['uuid'] ??
              record['loan_uuid'] ??
              record['loanId'] ??
              record['loan_id'])
          ?.toString();

  String? _responseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded['message']?.toString() : null;
    } on FormatException {
      return null;
    }
  }

  // ================= UPDATE LOAN =================

  Future<bool> updateLoan(Map<String, dynamic> body) async {
    final id = loanId;

    if (id == null || id.isEmpty) {
      showMessage('Error', 'The selected loan has no ID.');
      return false;
    }

    if (isSaving.value) return false;

    try {
      isSaving.value = true;
      loadError.value = '';

      // Uses ApiService.put() and its saved token.
      final response = await apiService.put('$url/$id', body);

      final decoded = _decodeResponse(response.body, response.statusCode);

      if (decoded == null) {
        showMessage('Update Failed', loadError.value);
        return false;
      }

      final data = decoded['data'];

      if (data is Map) {
        loan.assignAll(Map<String, dynamic>.from(data));
      } else {
        loan.addAll(body);
      }

      showMessage(
        'Success',
        decoded['message']?.toString() ?? 'Loan updated successfully.',
      );

      return true;
    } catch (error) {
      showMessage('Network Error', 'Unable to update loan.');
      print('Update loan error: $error');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ================= DELETE LOAN =================

  Future<bool> deleteLoan() async {
    final id = loanId;

    if (id == null || id.isEmpty) {
      showMessage('Error', 'The selected loan has no ID.');
      return false;
    }

    if (isDeleting.value) return false;

    try {
      isDeleting.value = true;
      loadError.value = '';

      // Uses ApiService.delete() and its saved token.
      final response = await apiService.delete('$url/$id');

      final decoded = _decodeResponse(response.body, response.statusCode);

      if (decoded == null) {
        showMessage('Delete Failed', loadError.value);
        return false;
      }

      showMessage(
        'Success',
        decoded['message']?.toString() ?? 'Loan deleted successfully.',
      );

      return true;
    } catch (error) {
      showMessage('Network Error', 'Unable to delete loan.');
      print('Delete loan error: $error');
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  // ================= RESPONSE HANDLING =================

  Map<String, dynamic>? _decodeResponse(String body, int statusCode) {
    dynamic decoded;

    try {
      decoded = body.isEmpty && statusCode >= 200 && statusCode < 300
          ? <String, dynamic>{'status': 'success'}
          : jsonDecode(body);
    } on FormatException {
      loadError.value = 'Invalid server response. HTTP $statusCode.';
      return null;
    }

    if (decoded is! Map) {
      loadError.value = 'Unexpected API response format.';
      return null;
    }

    if (statusCode < 200 ||
        statusCode >= 300 ||
        (decoded['status'] != null &&
            decoded['status'].toString().toLowerCase() != 'success')) {
      loadError.value = decoded['message']?.toString() ?? 'The request failed.';
      return null;
    }

    return Map<String, dynamic>.from(decoded);
  }

  // ================= FIELD HELPERS =================

  double number(String key) {
    return double.tryParse(value(key, fallback: '')) ?? 0.0;
  }

  String value(String key, {String fallback = '—'}) {
    final keys = _fieldAliases[key] ?? [key];
    for (final field in keys) {
      final current = loan[field]?.toString().trim();
      if (current != null && current.isNotEmpty) return current;
    }
    return fallback;
  }

  String valueFor(List<String> keys, {String fallback = '—'}) {
    for (final key in keys) {
      final current = loan[key]?.toString().trim();
      if (current != null && current.isNotEmpty) return current;
    }
    return fallback;
  }

  String scheduleValue(
    Map<String, dynamic> item,
    List<String> keys, {
    String fallback = '—',
  }) {
    for (final key in keys) {
      final current = item[key]?.toString().trim();
      if (current != null && current.isNotEmpty) return current;
    }
    return fallback;
  }

  double? scheduleOptionalNumber(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = double.tryParse(item[key]?.toString() ?? '');
      if (value != null && value.isFinite) return value;
    }
    return null;
  }

  static const Map<String, List<String>> _fieldAliases = {
    'nameOfLender': ['nameOfLender', 'name_of_lender', 'lender_name', 'lender'],
    'name': ['name', 'loan_name'],
    'loanType': ['loan_type', 'loanType'],
    'sanctionedAmount': ['sanctionedAmount', 'sanctioned_amount'],
    'principalAmount': ['principalAmount', 'principal_amount'],
    'disbursalAmount': ['disbursalAmount', 'disbursal_amount'],
    'chargesCutting': ['chargesCutting', 'charges_cutting'],
    'rateOfInterest': ['rateOfInterest', 'annual_interest_rate'],
    'loanTerms': ['loanTerms', 'tenure_months'],
    'startEMI': ['startEMI', 'first_due_date'],
    'endEMI': ['endEMI', 'last_due_date'],
    'dateOfDisbursement': [
      'dateOfDisbursement',
      'date_of_disbursement',
      'disbursement_date',
    ],
    'totalAmount': ['totalAmount', 'total_amount', 'total_payable'],
    'paidAmount': ['paidAmount', 'paid_amount', 'total_repaid'],
    'dueAmount': ['dueAmount', 'due_amount', 'total_outstanding'],
    'totalInterestAmount': [
      'totalInterestAmount',
      'total_interest_amount',
      'total_interest',
    ],
    'instalmentAmount': [
      'instalmentAmount',
      'installment_amount',
      'emi_amount',
    ],
    'loanStatus': ['loanStatus', 'loan_status', 'status'],
  };

  // ================= SNACKBAR =================

  void showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}

class _LoanPaymentPage {
  const _LoanPaymentPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Map<String, dynamic>> items;
  final int currentPage;
  final int lastPage;
  final int total;
}
