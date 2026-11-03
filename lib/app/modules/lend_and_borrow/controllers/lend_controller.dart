import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class LendController extends GetxController {
  LendController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  static const int pageSize = 20;

  final ApiService apiService;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isLoadingSummary = false.obs;
  final lends = <Map<String, dynamic>>[].obs;
  final lendingSummary = <LendingCurrencySummary>[].obs;
  final errorMessage = ''.obs;
  final summaryError = ''.obs;
  final loadMoreError = ''.obs;
  final count = 0.obs;
  final currentPage = 0.obs;
  final lastPage = 1.obs;
  final totalRecords = 0.obs;
  final activeRecordCount = 0.obs;
  final overdueRecordCount = 0.obs;

  int _requestGeneration = 0;

  bool get hasMore => currentPage.value < lastPage.value;

  double _amountFor(Map<String, dynamic> lend, List<String> keys) {
    for (final key in keys) {
      final amount = double.tryParse(lend[key]?.toString() ?? '');
      if (amount != null && amount.isFinite) {
        return amount;
      }
    }
    return 0;
  }

  double get totalAmount =>
      lends.fold(0, (total, lend) => total + lendAmount(lend));

  double get paidAmount => lends.fold(
    0,
    (total, lend) =>
        total +
        _amountFor(lend, [
          'paidAmount',
          'paid_amount',
          'paid',
          'receivedAmount',
          'received_amount',
          'amount_received',
        ]),
  );

  double get dueAmount {
    final hasApiDue = lends.any(
      (lend) =>
          lend.containsKey('dueAmount') ||
          lend.containsKey('due_amount') ||
          lend.containsKey('due'),
    );
    if (hasApiDue) {
      return lends.fold(
        0,
        (total, lend) =>
            total + _amountFor(lend, ['dueAmount', 'due_amount', 'due']),
      );
    }
    return (totalAmount - paidAmount).clamp(0, double.infinity).toDouble();
  }

  String formatAmount(double amount) {
    final formatted = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '₹$formatted';
  }

  double lendAmount(Map<String, dynamic> lend) {
    return _amountFor(lend, [
      'principal_amount',
      'amount',
      'totalAmount',
      'total_amount',
    ]);
  }

  String lendName(Map<String, dynamic> lend) {
    return (lend['borrower_name'] ??
            lend['receiveFrom'] ??
            lend['receive_from'] ??
            lend['givenTo'] ??
            lend['given_to'] ??
            lend['person_name'] ??
            lend['full_name'] ??
            lend['person'] ??
            lend['name'] ??
            'Unknown')
        .toString();
  }

  String dateFor(Map<String, dynamic> lend) =>
      (lend['transaction_date'] ??
              lend['lending_date'] ??
              lend['given_date'] ??
              lend['date'] ??
              '')
          .toString();

  String statusFor(Map<String, dynamic> lend) =>
      (lend['status'] ?? '').toString();

  double dueFor(Map<String, dynamic> lend) => _amountFor(lend, [
    'total_outstanding',
    'principal_outstanding',
    'due_amount',
    'dueAmount',
    'due',
  ]);

  @override
  void onInit() {
    super.onInit();
    fetchLends();
    fetchLendingSummary();
  }

  Future<void> refreshLending() async {
    await Future.wait([fetchLends(), fetchLendingSummary()]);
  }

  Future<void> fetchLendingSummary() async {
    if (isLoadingSummary.value) return;
    isLoadingSummary.value = true;
    summaryError.value = '';

    try {
      final response = await apiService.getLendingSummary();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Lending summary request failed (${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned invalid lending summary data.',
        );
      }

      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map) {
        throw FormatException(
          decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'The lending summary response was invalid.',
        );
      }

      final data = Map<String, dynamic>.from(decoded['data'] as Map);
      final totalsValue = data['totals_by_currency'];
      if (totalsValue is! List) {
        throw const FormatException(
          'The lending summary currency totals were invalid.',
        );
      }
      final totals = <LendingCurrencySummary>[];
      for (final item in totalsValue) {
        if (item is! Map) {
          throw const FormatException(
            'The lending summary contained invalid currency totals.',
          );
        }
        totals.add(
          LendingCurrencySummary.fromJson(Map<String, dynamic>.from(item)),
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
      lendingSummary.assignAll(totals);
      activeRecordCount.value = activeCount;
      overdueRecordCount.value = overdueCount;
    } on FormatException catch (error) {
      summaryError.value = error.message;
      debugPrint('Unable to fetch lending summary: ${error.message}');
    } catch (error, stackTrace) {
      summaryError.value = 'Unable to load lending summary. Please retry.';
      debugPrint('Unable to fetch lending summary: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingSummary.value = false;
    }
  }

  int _summaryNonNegativeInt(dynamic value, String field) {
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 0) {
      throw FormatException('The lending summary $field value was invalid.');
    }
    return parsed;
  }

  String? _responseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded['message']?.toString() : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> fetchLends() async {
    if (isLoading.value) return;
    final generation = ++_requestGeneration;
    isLoading.value = true;
    errorMessage.value = '';
    loadMoreError.value = '';

    try {
      final result = await _fetchPage(1);
      if (generation != _requestGeneration) return;
      lends.assignAll(result.items);
      currentPage.value = result.currentPage;
      lastPage.value = result.lastPage;
      totalRecords.value = result.total;
    } on FormatException catch (error) {
      if (generation == _requestGeneration) {
        errorMessage.value = error.message;
      }
      debugPrint('Unable to fetch lending list: ${error.message}');
    } catch (error, stackTrace) {
      debugPrint('Unable to fetch lending list: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (generation == _requestGeneration) {
        errorMessage.value = 'Unable to load lending details. Please retry.';
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
      final knownIds = lends.map(_recordId).whereType<String>().toSet();
      lends.addAll(
        result.items.where((lend) {
          final id = _recordId(lend);
          return id == null || knownIds.add(id);
        }),
      );
      currentPage.value = result.currentPage;
      lastPage.value = result.lastPage;
      totalRecords.value = result.total;
    } on FormatException catch (error) {
      if (generation == _requestGeneration) {
        loadMoreError.value = error.message;
      }
      debugPrint('Unable to load more lending records: ${error.message}');
    } catch (error, stackTrace) {
      debugPrint('Unable to load more lending records: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (generation == _requestGeneration) {
        loadMoreError.value = 'Unable to load more records. Please retry.';
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<_LendingPage> _fetchPage(int page) async {
    final response = await apiService.getLending(page: page, perPage: pageSize);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? serverMessage;
      try {
        final decodedError = jsonDecode(response.body);
        if (decodedError is Map) {
          serverMessage = decodedError['message']?.toString();
        }
      } on FormatException {
        serverMessage = null;
      }
      throw FormatException(
        serverMessage == null || serverMessage.isEmpty
            ? 'Lending request failed (${response.statusCode}).'
            : serverMessage,
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned invalid lending data.');
    }

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map ||
        decoded['data']['items'] is! List) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw FormatException(
        message == null || message.isEmpty
            ? 'The lending response was invalid.'
            : message,
      );
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final items = <Map<String, dynamic>>[];
    for (final item in data['items'] as List) {
      if (item is! Map) {
        throw const FormatException('The lending list contained invalid data.');
      }
      items.add(Map<String, dynamic>.from(item));
    }

    final paginationValue = data['pagination'];
    if (paginationValue is! Map) {
      throw const FormatException('The lending pagination data was invalid.');
    }
    final pagination = Map<String, dynamic>.from(paginationValue);
    return _LendingPage(
      items: items,
      currentPage: _positiveInt(pagination['current_page'], page),
      lastPage: _positiveInt(pagination['last_page'], page),
      total: _nonNegativeInt(pagination['total'], items.length),
    );
  }

  String? _recordId(Map<String, dynamic> lend) {
    final value =
        lend['uuid'] ??
        lend['id'] ??
        lend['lending_uuid'] ??
        lend['lending_id'];
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

  void increment() => count.value++;
}

class _LendingPage {
  const _LendingPage({
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

class LendingCurrencySummary {
  const LendingCurrencySummary({
    required this.currency,
    required this.principalTotal,
    required this.principalRecovered,
    required this.principalOutstanding,
    required this.interestReceived,
    required this.interestOutstanding,
    required this.totalOutstanding,
  });

  final String currency;
  final double principalTotal;
  final double principalRecovered;
  final double principalOutstanding;
  final double interestReceived;
  final double interestOutstanding;
  final double totalOutstanding;

  factory LendingCurrencySummary.fromJson(Map<String, dynamic> json) {
    String readCurrency() {
      final value = json['currency']?.toString().trim();
      if (value == null || value.isEmpty) {
        throw const FormatException(
          'The lending summary currency was missing.',
        );
      }
      return value;
    }

    double readAmount(String field) {
      final parsed = double.tryParse(json[field]?.toString() ?? '');
      if (parsed == null || !parsed.isFinite) {
        throw FormatException('The lending summary $field value was invalid.');
      }
      return parsed;
    }

    return LendingCurrencySummary(
      currency: readCurrency(),
      principalTotal: readAmount('principal_total'),
      principalRecovered: readAmount('principal_recovered'),
      principalOutstanding: readAmount('principal_outstanding'),
      interestReceived: readAmount('interest_received'),
      interestOutstanding: readAmount('interest_outstanding'),
      totalOutstanding: readAmount('total_outstanding'),
    );
  }
}
