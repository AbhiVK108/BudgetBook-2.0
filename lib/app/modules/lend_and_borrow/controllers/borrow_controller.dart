import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class BorrowController extends GetxController {
  BorrowController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  static const int pageSize = 20;

  final ApiService apiService;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isLoadingSummary = false.obs;
  final borrows = <Map<String, dynamic>>[].obs;
  final borrowingSummary = <BorrowingCurrencySummary>[].obs;
  final errorMessage = ''.obs;
  final summaryError = ''.obs;
  final loadMoreError = ''.obs;
  final currentPage = 0.obs;
  final lastPage = 1.obs;
  final totalRecords = 0.obs;
  final activeRecordCount = 0.obs;
  final overdueRecordCount = 0.obs;

  int _requestGeneration = 0;

  bool get hasMore => currentPage.value < lastPage.value;

  @override
  void onInit() {
    super.onInit();
    fetchBorrows();
    fetchBorrowingSummary();
  }

  Future<void> refreshBorrows() async {
    await Future.wait([fetchBorrows(), fetchBorrowingSummary()]);
  }

  Future<void> fetchBorrowingSummary() async {
    if (isLoadingSummary.value) return;
    isLoadingSummary.value = true;
    summaryError.value = '';
    try {
      final response = await apiService.getBorrowingSummary();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Borrowing summary request failed (${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned invalid borrowing summary data.',
        );
      }
      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map) {
        throw FormatException(
          decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'The borrowing summary response was invalid.',
        );
      }

      final data = Map<String, dynamic>.from(decoded['data'] as Map);
      final totalsValue = data['totals_by_currency'];
      if (totalsValue is! List) {
        throw const FormatException(
          'The borrowing summary currency totals were invalid.',
        );
      }
      final totals = <BorrowingCurrencySummary>[];
      for (final item in totalsValue) {
        if (item is! Map) {
          throw const FormatException(
            'The borrowing summary contained invalid currency totals.',
          );
        }
        totals.add(
          BorrowingCurrencySummary.fromJson(Map<String, dynamic>.from(item)),
        );
      }

      final activeCount = _summaryNonNegativeInt(
        data['active_record_count'],
        'active_record_count',
      );
      final overdueCount = _summaryNonNegativeInt(
        data['overdue_record_count'],
        'overdue_record_count',
      );
      borrowingSummary.assignAll(totals);
      activeRecordCount.value = activeCount;
      overdueRecordCount.value = overdueCount;
    } on FormatException catch (error) {
      summaryError.value = error.message;
      debugPrint('Unable to fetch borrowing summary: ${error.message}');
    } catch (error, stackTrace) {
      summaryError.value = 'Unable to load borrowing summary. Please retry.';
      debugPrint('Unable to fetch borrowing summary: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingSummary.value = false;
    }
  }

  Future<void> fetchBorrows() async {
    if (isLoading.value) return;
    final generation = ++_requestGeneration;
    isLoading.value = true;
    errorMessage.value = '';
    loadMoreError.value = '';
    try {
      final result = await _fetchPage(1);
      if (generation != _requestGeneration) return;
      borrows.assignAll(result.items);
      currentPage.value = result.currentPage;
      lastPage.value = result.lastPage;
      totalRecords.value = result.total;
    } on FormatException catch (error) {
      if (generation == _requestGeneration) errorMessage.value = error.message;
      debugPrint('Unable to fetch borrowing list: ${error.message}');
    } catch (error, stackTrace) {
      debugPrint('Unable to fetch borrowing list: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (generation == _requestGeneration) {
        errorMessage.value = 'Unable to load borrowing records. Please retry.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    loadMoreError.value = '';
    final generation = _requestGeneration;
    try {
      final result = await _fetchPage(currentPage.value + 1);
      if (generation != _requestGeneration) return;
      final knownIds = borrows.map(_recordId).whereType<String>().toSet();
      borrows.addAll(
        result.items.where((borrow) {
          final id = _recordId(borrow);
          return id == null || knownIds.add(id);
        }),
      );
      currentPage.value = result.currentPage;
      lastPage.value = result.lastPage;
      totalRecords.value = result.total;
    } on FormatException catch (error) {
      if (generation == _requestGeneration) loadMoreError.value = error.message;
      debugPrint('Unable to load more borrowing records: ${error.message}');
    } catch (error, stackTrace) {
      debugPrint('Unable to load more borrowing records: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (generation == _requestGeneration) {
        loadMoreError.value = 'Unable to load more records. Please retry.';
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<_BorrowingPage> _fetchPage(int page) async {
    final response = await apiService.getBorrowing(
      page: page,
      perPage: pageSize,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
        _responseMessage(response.body) ??
            'Borrowing request failed (${response.statusCode}).',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException(
        'The server returned invalid borrowing data.',
      );
    }
    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map ||
        decoded['data']['items'] is! List) {
      throw FormatException(
        decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'The borrowing response was invalid.',
      );
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final items = <Map<String, dynamic>>[];
    for (final item in data['items'] as List) {
      if (item is! Map) {
        throw const FormatException(
          'The borrowing list contained invalid data.',
        );
      }
      items.add(Map<String, dynamic>.from(item));
    }
    final paginationValue = data['pagination'];
    if (paginationValue is! Map) {
      throw const FormatException('The borrowing pagination data was invalid.');
    }
    final pagination = Map<String, dynamic>.from(paginationValue);
    return _BorrowingPage(
      items: items,
      currentPage: _positiveInt(pagination['current_page'], page),
      lastPage: _positiveInt(pagination['last_page'], page),
      total: _nonNegativeInt(pagination['total'], items.length),
    );
  }

  String? _responseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded['message']?.toString() : null;
    } on FormatException {
      return null;
    }
  }

  int _summaryNonNegativeInt(dynamic value, String field) {
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 0) {
      throw FormatException('The borrowing summary $field value was invalid.');
    }
    return parsed;
  }

  String? _recordId(Map<String, dynamic> borrow) {
    final value = borrow['uuid'] ?? borrow['id'] ?? borrow['borrowing_uuid'];
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

  String nameFor(Map<String, dynamic> borrow) =>
      (borrow['lender_name'] ?? borrow['givenTo'] ?? 'Unknown').toString();

  String dateFor(Map<String, dynamic> borrow) =>
      (borrow['borrowing_date'] ?? borrow['givenDate'] ?? '').toString();

  String returnDateFor(Map<String, dynamic> borrow) =>
      (borrow['expected_repayment_date'] ?? borrow['returnDate'] ?? '')
          .toString();

  String phoneFor(Map<String, dynamic> borrow) =>
      (borrow['lender_phone'] ?? borrow['phone'] ?? '').toString();

  String descriptionFor(Map<String, dynamic> borrow) =>
      (borrow['notes'] ?? borrow['description'] ?? '').toString();

  String statusFor(Map<String, dynamic> borrow) =>
      (borrow['status'] ?? '').toString();

  double _amountFor(Map<String, dynamic> borrow, List<String> keys) {
    for (final key in keys) {
      final amount = double.tryParse(
        borrow[key]?.toString().replaceAll(',', '').trim() ?? '',
      );
      if (amount != null && amount.isFinite) return amount;
    }
    return 0;
  }

  double amountFor(Map<String, dynamic> borrow) =>
      _amountFor(borrow, ['principal_amount', 'amount']);

  double paidFor(Map<String, dynamic> borrow) => _amountFor(borrow, [
    'principal_repaid',
    'paid_amount',
    'paidAmount',
    'paid',
  ]);

  double dueFor(Map<String, dynamic> borrow) => _amountFor(borrow, [
    'total_outstanding',
    'principal_outstanding',
    'due_amount',
    'dueAmount',
    'due',
  ]);

  double interestFor(Map<String, dynamic> borrow) => _amountFor(borrow, [
    'interest_outstanding',
    'interest_paid',
    'interestAmount',
  ]);

  String formatAmount(double amount) =>
      '₹${amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}';
}

class _BorrowingPage {
  const _BorrowingPage({
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

class BorrowingCurrencySummary {
  const BorrowingCurrencySummary({
    required this.currency,
    required this.principalTotal,
    required this.principalRepaid,
    required this.principalOutstanding,
    required this.interestPaid,
    required this.interestOutstanding,
    required this.totalOutstanding,
  });

  final String currency;
  final double principalTotal;
  final double principalRepaid;
  final double principalOutstanding;
  final double interestPaid;
  final double interestOutstanding;
  final double totalOutstanding;

  factory BorrowingCurrencySummary.fromJson(Map<String, dynamic> json) {
    final currency = json['currency']?.toString().trim();
    if (currency == null || currency.isEmpty) {
      throw const FormatException(
        'The borrowing summary currency was missing.',
      );
    }

    double readAmount(String field) {
      final parsed = double.tryParse(json[field]?.toString() ?? '');
      if (parsed == null || !parsed.isFinite) {
        throw FormatException(
          'The borrowing summary $field value was invalid.',
        );
      }
      return parsed;
    }

    return BorrowingCurrencySummary(
      currency: currency,
      principalTotal: readAmount('principal_total'),
      principalRepaid: readAmount('principal_repaid'),
      principalOutstanding: readAmount('principal_outstanding'),
      interestPaid: readAmount('interest_paid'),
      interestOutstanding: readAmount('interest_outstanding'),
      totalOutstanding: readAmount('total_outstanding'),
    );
  }
}
