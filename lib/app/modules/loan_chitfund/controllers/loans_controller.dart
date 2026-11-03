import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class LoansController extends GetxController {
  LoansController({ApiService? apiService, DateTime Function()? clock})
    : apiService = apiService ?? ApiService(),
      _clock = clock ?? DateTime.now {
    final now = _clock();
    final firstMonthOfQuarter = ((now.month - 1) ~/ 3) * 3 + 1;
    selectedSummaryFromDate = DateTime(now.year, firstMonthOfQuarter).obs;
    selectedSummaryToDate = DateTime(now.year, firstMonthOfQuarter + 3, 0).obs;
  }

  static const int pageSize = 20;

  final ApiService apiService;
  final DateTime Function() _clock;
  late final Rx<DateTime> selectedSummaryFromDate;
  late final Rx<DateTime> selectedSummaryToDate;
  final RxList<Map<String, dynamic>> loans = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> upcomingInstallments =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> overdueInstallments =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> loanSummary = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingUpcomingInstallments = false.obs;
  final RxBool isLoadingOverdueInstallments = false.obs;
  final RxBool isLoadingLoanSummary = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString loadError = ''.obs;
  final RxString upcomingInstallmentsError = ''.obs;
  final RxString overdueInstallmentsError = ''.obs;
  final RxString loanSummaryError = ''.obs;
  final RxString loadMoreError = ''.obs;
  final RxInt currentPage = 0.obs;
  final RxInt lastPage = 1.obs;
  final RxInt totalRecords = 0.obs;
  final RxInt selectedSection = 0.obs;

  int _requestGeneration = 0;

  bool get hasMore => currentPage.value < lastPage.value;

  DateTime get summaryFromDate {
    return selectedSummaryFromDate.value;
  }

  DateTime get summaryToDate => selectedSummaryToDate.value;

  String get summaryPeriodLabel =>
      '${_formatDate(summaryFromDate)} to ${_formatDate(summaryToDate)}';

  String get summaryPeriodDisplayLabel {
    if (summaryFromDate.year == summaryToDate.year) {
      return '${_formatDisplayDate(summaryFromDate)} – '
          '${_formatDisplayDate(summaryToDate)}, ${summaryToDate.year}';
    }
    return '${_formatDisplayDate(summaryFromDate)}, ${summaryFromDate.year} – '
        '${_formatDisplayDate(summaryToDate)}, ${summaryToDate.year}';
  }

  @override
  void onInit() {
    super.onInit();
    fetchLoans();
    fetchUpcomingInstallments();
    fetchOverdueInstallments();
    fetchLoanSummary();
  }

  Future<void> fetchLoanSummary() async {
    if (isLoadingLoanSummary.value) return;
    isLoadingLoanSummary.value = true;
    loanSummaryError.value = '';
    try {
      final response = await apiService.getLoanSummary(
        fromDate: summaryFromDate,
        toDate: summaryToDate,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Loan summary request failed (${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned invalid loan summary data.',
        );
      }
      if (decoded is! Map ||
          decoded['success'] == false ||
          (decoded['status'] != null &&
              decoded['status'].toString().toLowerCase() == 'error')) {
        throw FormatException(
          _responseMessage(response.body) ??
              'The loan summary response was invalid.',
        );
      }

      final data = decoded['data'] ?? decoded['summary'];
      final summary = data is Map && data['summary'] is Map
          ? data['summary'] as Map
          : data;
      if (summary is! Map) {
        throw const FormatException('Unexpected loan summary response format.');
      }
      loanSummary.assignAll(Map<String, dynamic>.from(summary));
    } on FormatException catch (error) {
      loanSummaryError.value = error.message;
      debugPrint('Unable to fetch loan summary: ${error.message}');
    } catch (error, stackTrace) {
      loanSummaryError.value = 'Unable to load loan summary. Please retry.';
      debugPrint('Unable to fetch loan summary: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingLoanSummary.value = false;
    }
  }

  Future<void> setSummaryPeriod(DateTime fromDate, DateTime toDate) async {
    if (isLoadingLoanSummary.value) return;
    selectedSummaryFromDate.value = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day,
    );
    selectedSummaryToDate.value = DateTime(
      toDate.year,
      toDate.month,
      toDate.day,
    );
    loanSummary.clear();
    await fetchLoanSummary();
  }

  Future<void> fetchLoans() async {
    if (isLoading.value) return;
    final generation = ++_requestGeneration;
    isLoading.value = true;
    loadError.value = '';
    loadMoreError.value = '';
    try {
      final page = await _fetchPage(1);
      if (generation != _requestGeneration) return;
      loans.assignAll(page.items);
      currentPage.value = page.currentPage;
      lastPage.value = page.lastPage;
      totalRecords.value = page.total;
    } on FormatException catch (error) {
      if (generation == _requestGeneration) loadError.value = error.message;
      debugPrint('Unable to fetch loans: ${error.message}');
    } catch (error, stackTrace) {
      if (generation == _requestGeneration) {
        loadError.value = 'Unable to load loans. Please retry.';
      }
      debugPrint('Unable to fetch loans: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUpcomingInstallments() async {
    if (isLoadingUpcomingInstallments.value) return;
    isLoadingUpcomingInstallments.value = true;
    upcomingInstallmentsError.value = '';
    try {
      final response = await apiService.getUpcomingLoanInstallments();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Upcoming installments request failed '
                  '(${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned invalid upcoming installment data.',
        );
      }
      if (decoded is! Map ||
          decoded['success'] == false ||
          (decoded['status'] != null &&
              decoded['status'].toString().toLowerCase() == 'error')) {
        throw FormatException(
          _responseMessage(response.body) ??
              'The upcoming installments response was invalid.',
        );
      }

      final items = _installmentsFromResponse(
        decoded,
        responseKey: 'upcoming_installments',
      );
      if (items == null) {
        throw const FormatException(
          'Unexpected upcoming installments response format.',
        );
      }
      upcomingInstallments.assignAll(items);
    } on FormatException catch (error) {
      upcomingInstallmentsError.value = error.message;
      debugPrint(
        'Unable to fetch upcoming loan installments: ${error.message}',
      );
    } catch (error, stackTrace) {
      upcomingInstallmentsError.value =
          'Unable to load upcoming installments. Please retry.';
      debugPrint('Unable to fetch upcoming loan installments: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingUpcomingInstallments.value = false;
    }
  }

  Future<void> fetchOverdueInstallments() async {
    if (isLoadingOverdueInstallments.value) return;
    isLoadingOverdueInstallments.value = true;
    overdueInstallmentsError.value = '';
    try {
      final response = await apiService.getOverdueLoanInstallments();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Overdue installments request failed '
                  '(${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned invalid overdue installment data.',
        );
      }
      if (decoded is! Map ||
          decoded['success'] == false ||
          (decoded['status'] != null &&
              decoded['status'].toString().toLowerCase() == 'error')) {
        throw FormatException(
          _responseMessage(response.body) ??
              'The overdue installments response was invalid.',
        );
      }

      final items = _installmentsFromResponse(
        decoded,
        responseKey: 'overdue_installments',
      );
      if (items == null) {
        throw const FormatException(
          'Unexpected overdue installments response format.',
        );
      }
      overdueInstallments.assignAll(items);
    } on FormatException catch (error) {
      overdueInstallmentsError.value = error.message;
      debugPrint('Unable to fetch overdue loan installments: ${error.message}');
    } catch (error, stackTrace) {
      overdueInstallmentsError.value =
          'Unable to load overdue installments. Please retry.';
      debugPrint('Unable to fetch overdue loan installments: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingOverdueInstallments.value = false;
    }
  }

  List<Map<String, dynamic>>? _installmentsFromResponse(
    Map<dynamic, dynamic> response, {
    required String responseKey,
  }) {
    dynamic findItems(dynamic value) {
      if (value is List) {
        final items = <Map<String, dynamic>>[];
        for (final item in value) {
          if (item is! Map) return null;
          items.add(Map<String, dynamic>.from(item));
        }
        return items;
      }
      if (value is! Map) return null;

      for (final key in [
        'items',
        'overdue_installments',
        'upcoming_installments',
        'installments',
        'loan_installments',
        'results',
        'data',
      ]) {
        if (value.containsKey(key)) {
          final result = findItems(value[key]);
          if (result != null) return result;
        }
      }
      return null;
    }

    return findItems(
      response['data'] ?? response[responseKey] ?? response['items'],
    );
  }

  String? _responseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<void> loadNextPage() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    loadMoreError.value = '';
    final generation = _requestGeneration;
    try {
      final page = await _fetchPage(currentPage.value + 1);
      if (generation != _requestGeneration) return;
      final knownIds = loans.map(_recordId).whereType<String>().toSet();
      loans.addAll(
        page.items.where((loan) {
          final id = _recordId(loan);
          return id == null || knownIds.add(id);
        }),
      );
      currentPage.value = page.currentPage;
      lastPage.value = page.lastPage;
      totalRecords.value = page.total;
    } on FormatException catch (error) {
      if (generation == _requestGeneration) {
        loadMoreError.value = error.message;
      }
      debugPrint('Unable to load more loans: ${error.message}');
    } catch (error, stackTrace) {
      if (generation == _requestGeneration) {
        loadMoreError.value = 'Unable to load more loans. Please retry.';
      }
      debugPrint('Unable to load more loans: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<_LoanPage> _fetchPage(int page) async {
    final response = await apiService.getLoans(page: page, perPage: pageSize);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) message = decoded['message']?.toString();
      } on FormatException {
        message = null;
      }
      throw FormatException(
        message == null || message.isEmpty
            ? 'Loans request failed (${response.statusCode}).'
            : message,
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned invalid loan data.');
    }
    if (decoded is! Map) {
      throw const FormatException('Unexpected API response format.');
    }
    final result = Map<String, dynamic>.from(decoded);
    final apiSuccess =
        result['success'] == true ||
        result['status']?.toString().toLowerCase() == 'success';
    if (!apiSuccess) {
      throw FormatException(
        result['message']?.toString() ?? 'Failed to fetch loans.',
      );
    }

    final data = result['data'];
    final dynamic itemValue = data is List
        ? data
        : data is Map && data['items'] is List
        ? data['items']
        : data is Map && data['data'] is List
        ? data['data']
        : data is Map &&
              (data.containsKey('id') ||
                  data.containsKey('uuid') ||
                  data.containsKey('loanId'))
        ? [data]
        : null;
    if (itemValue is! List) {
      throw const FormatException('Unexpected loan list response format.');
    }

    final items = <Map<String, dynamic>>[];
    for (final item in itemValue) {
      if (item is! Map) {
        throw const FormatException('The loans list contained invalid data.');
      }
      items.add(Map<String, dynamic>.from(item));
    }
    final pagination = data is Map && data['pagination'] is Map
        ? Map<String, dynamic>.from(data['pagination'] as Map)
        : <String, dynamic>{};
    return _LoanPage(
      items: items,
      currentPage: _positiveInt(pagination['current_page'], page),
      lastPage: _positiveInt(pagination['last_page'], page),
      total: _nonNegativeInt(pagination['total'], items.length),
    );
  }

  String? _recordId(Map<String, dynamic> loan) {
    final value =
        loan['uuid'] ?? loan['id'] ?? loan['loan_uuid'] ?? loan['loan_id'];
    final id = value?.toString().trim();
    return id == null || id.isEmpty ? null : id;
  }

  dynamic summaryValueFor(List<String> keys) {
    dynamic findValue(Map<dynamic, dynamic> values) {
      for (final key in keys) {
        final value = values[key];
        if (value != null && value.toString().trim().isNotEmpty) return value;
      }
      for (final value in values.values) {
        if (value is Map) {
          final nestedValue = findValue(value);
          if (nestedValue != null) return nestedValue;
        }
      }
      return null;
    }

    return findValue(loanSummary);
  }

  int _positiveInt(dynamic value, int fallback) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : fallback;
  }

  int _nonNegativeInt(dynamic value, int fallback) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed >= 0 ? parsed : fallback;
  }

  String lenderName(Map<String, dynamic> loan) =>
      (loan['nameOfLender'] ??
              loan['name_of_lender'] ??
              loan['lender_name'] ??
              loan['lender'] ??
              loan['name'] ??
              'Loan')
          .toString();

  double amountFor(Map<String, dynamic> loan, List<String> keys) {
    for (final key in keys) {
      final amount = double.tryParse(loan[key]?.toString() ?? '');
      if (amount != null && amount.isFinite) return amount;
    }
    return 0;
  }

  double totalAmountFor(Map<String, dynamic> loan) => amountFor(loan, [
    'totalAmount',
    'total_amount',
    'total_payable',
    'total_outstanding',
    'sanctionedAmount',
    'sanctioned_amount',
    'principal_amount',
  ]);

  String valueFor(Map<String, dynamic> loan, List<String> keys) {
    for (final key in keys) {
      final value = loan[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  double get totalAmount =>
      loans.fold(0, (sum, loan) => sum + totalAmountFor(loan));

  double get totalPaidAmount => loans.fold(
    0,
    (sum, loan) =>
        sum + amountFor(loan, ['paidAmount', 'paid_amount', 'total_repaid']),
  );

  double get totalDueAmount => loans.fold(
    0,
    (sum, loan) =>
        sum + amountFor(loan, ['dueAmount', 'due_amount', 'total_outstanding']),
  );

  double get totalSanctionedAmount => loans.fold(
    0,
    (sum, loan) =>
        sum + amountFor(loan, ['sanctionedAmount', 'sanctioned_amount']),
  );

  Future<void> refreshLoans() async {
    await Future.wait([
      fetchLoans(),
      fetchUpcomingInstallments(),
      fetchOverdueInstallments(),
      fetchLoanSummary(),
    ]);
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _formatDisplayDate(DateTime date) =>
      '${_monthName(date.month)} ${date.day}';

  String _monthName(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  void showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}

class _LoanPage {
  const _LoanPage({
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
