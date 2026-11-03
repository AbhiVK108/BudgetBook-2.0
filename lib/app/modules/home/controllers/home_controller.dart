import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  HomeController({ApiService? apiService, DateTime Function()? clock})
    : apiService = apiService ?? ApiService(),
      _clock = clock ?? DateTime.now;

  final ApiService apiService;
  final DateTime Function() _clock;

  final isLoading = false.obs;
  final username = 'User'.obs;
  final errorMessage = ''.obs;

  final totalIncome = 0.0.obs;
  final totalExpense = 0.0.obs;
  final available = 0.0.obs;
  final debitDue = 0.0.obs;
  final loanDue = 0.0.obs;

  final hasIncomeSummary = false.obs;
  final hasExpenseSummary = false.obs;
  final hasAvailableSummary = false.obs;
  final hasDebitDueSummary = false.obs;
  final hasLoanDueSummary = false.obs;
  final selectedPeriod = 'this_month'.obs;
  final selectedMonth = DateTime.now().obs;

  String get dashboardApiPeriod => selectedPeriod.value.startsWith('month_')
      ? 'month'
      : selectedPeriod.value;

  DateTime get summaryFromDate {
    final now = _clock();
    return DateTime(now.year, now.month);
  }

  DateTime get summaryToDate {
    final from = summaryFromDate;
    return DateTime(from.year, from.month + 1, 0);
  }

  String get summaryPeriodLabel => selectedPeriod.value == 'this_month'
      ? 'This month'
      : selectedPeriod.value == 'this_year'
      ? 'This year'
      : selectedPeriod.value.startsWith('month_')
      ? '${selectedMonth.value.year}-${selectedMonth.value.month.toString().padLeft(2, '0')}'
      : selectedPeriod.value == 'year'
      ? selectedMonth.value.year.toString()
      : {
              'today': 'Today',
              'this_week': 'This week',
              'previous_month': 'Previous month',
              'previous_year': 'Previous year',
            }[selectedPeriod.value] ??
            selectedPeriod.value.replaceAll('_', ' ');

  @override
  void onInit() {
    super.onInit();
    loadUsername();
    fetchTotals();
  }

  Future<void> loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      username.value = prefs.getString('username') ?? 'User';
    } catch (error, stackTrace) {
      debugPrint('Unable to load username: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> logout() async {
    await apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    Get.offAllNamed('/login');
  }

  Future<void> fetchTotals() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await apiService.getDashboardSummary(
        period: dashboardApiPeriod,
        month: dashboardApiPeriod == 'month' ? selectedMonth.value.month : null,
        year: selectedPeriod.value == 'year' ? selectedMonth.value.year : null,
      );
      final storedToken = await apiService.getToken();
      debugPrint(
        '[Dashboard] GET ${ApiService.dashboardSummaryUrl}'
        '?period=$dashboardApiPeriod'
        '${dashboardApiPeriod == 'month' ? '&month=${selectedMonth.value.month}' : ''}'
        '${selectedPeriod.value == 'year' ? '&year=${selectedMonth.value.year}' : ''}',
      );
      debugPrint(
        '[Dashboard] Authorization: '
        '${storedToken == null || storedToken.isEmpty ? "missing" : "Bearer <token-present>"}',
      );
      debugPrint('[Dashboard] HTTP ${response.statusCode}');
      debugPrint('[Dashboard] backend body: ${response.body}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String? serverMessage;
        try {
          final errorPayload = jsonDecode(response.body);
          if (errorPayload is Map) {
            serverMessage = errorPayload['message']?.toString();
          }
        } on FormatException {
          serverMessage = null;
        }
        throw FormatException(
          serverMessage == null || serverMessage.isEmpty
              ? 'Dashboard summary request failed (${response.statusCode}).'
              : serverMessage,
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned invalid dashboard summary data.',
        );
      }
      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map) {
        final message = decoded is Map ? decoded['message']?.toString() : null;
        throw FormatException(
          message == null || message.isEmpty
              ? 'The dashboard summary response was invalid.'
              : message,
        );
      }

      final data = Map<String, dynamic>.from(decoded['data'] as Map);
      final income = _readMetric(data, const [
        'total_income',
        'total_income_amount',
        'total_income_value',
        'income_total',
        'income_amount',
        'income_sum',
        'totalIncome',
        'totalIncomeAmount',
        'income',
      ]);
      final expense = _readMetric(data, const [
        'total_expense',
        'total_expense_amount',
        'total_expense_value',
        'expense_total',
        'expense_amount',
        'expense_sum',
        'totalExpense',
        'totalExpenseAmount',
        'expense',
        'expenses',
      ]);
      if (income == null || expense == null) {
        throw const FormatException(
          'Dashboard summary is missing income or expense totals.',
        );
      }

      totalIncome.value = income;
      totalExpense.value = expense;
      hasIncomeSummary.value = true;
      hasExpenseSummary.value = true;

      _applyOptionalMetric(
        data,
        const [
          'available_balance',
          'account_balance',
          'total_account_balance',
          'total_balance',
          'current_balance',
          'closing_balance',
          'net_balance',
          'available',
          'balance',
          'net_cash_flow_by_currency',
        ],
        available,
        hasAvailableSummary,
      );
      _applyOptionalMetric(
        data,
        const [
          'debit_due',
          'debit_due_total',
          'to_pay',
          'total_to_pay',
          'total_debit_due',
          'total_payable',
          'payable',
          'amount_to_pay',
          'payables',
          'borrowing',
          'borrowings',
          'total_borrowing_outstanding',
          'total_borrowing_due',
        ],
        debitDue,
        hasDebitDueSummary,
      );
      _applyOptionalMetric(
        data,
        const [
          'loan_due',
          'loan_due_total',
          'lend_back',
          'total_lend_back',
          'total_loan_due',
          'total_receivable',
          'receivable',
          'amount_to_receive',
          'receivables',
          'lending',
          'lendings',
          'total_lending_outstanding',
          'total_receivable_outstanding',
        ],
        loanDue,
        hasLoanDueSummary,
      );
    } on FormatException catch (error) {
      errorMessage.value = error.message;
      debugPrint('Unable to load dashboard summary: ${error.message}');
    } catch (error, stackTrace) {
      errorMessage.value = 'Unable to load dashboard summary. Please retry.';
      debugPrint('Unable to load dashboard summary: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  void _applyOptionalMetric(
    Map<String, dynamic> data,
    List<String> aliases,
    RxDouble destination,
    RxBool loaded,
  ) {
    final value = _readMetric(data, aliases);
    if (value == null) return;
    destination.value = value;
    loaded.value = true;
  }

  double? _readMetric(Map<String, dynamic> data, List<String> aliases) {
    for (final alias in aliases) {
      final value = _findMetricValue(data, {_normalizeKey(alias)});
      if (value == null) continue;

      final currencyTotal = value is List ? _sumCurrencyTotals(value) : null;
      if (currencyTotal != null) return currencyTotal;

      if (value is Map) {
        final totals =
            (value['totals_by_currency'] ??
                    _findMetricValue(Map<String, dynamic>.from(value), const {
                      'totalsbycurrency',
                    }))
                as dynamic;
        final currencyTotal = _sumCurrencyTotals(totals);
        if (currencyTotal != null) return currencyTotal;
      }

      final metricValue = value is Map
          ? _findMetricValue(Map<String, dynamic>.from(value), const {
              'amount',
              'total',
              'value',
              'total_amount',
              'total_outstanding',
              'outstanding_amount',
              'outstanding',
            })
          : value;
      if (metricValue == null) continue;

      final parsed = _parseMetricValue(metricValue);
      if (parsed == null || !parsed.isFinite) {
        throw FormatException(
          'Dashboard summary contains an invalid $alias value.',
        );
      }
      return parsed;
    }
    return null;
  }

  double? _sumCurrencyTotals(dynamic totals) {
    if (totals is! List || totals.isEmpty) return null;

    var sum = 0.0;
    var found = false;
    for (final item in totals) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final value = _findMetricValue(map, const {
        'totalamount',
        'amount',
        'total',
        'value',
        'totaloutstanding',
        'principaloutstanding',
        'interestoutstanding',
        'outstandingamount',
        'outstanding',
      });
      final parsed = value == null ? null : _parseMetricValue(value);
      if (parsed == null || !parsed.isFinite) continue;
      sum += parsed;
      found = true;
    }
    return found ? sum : null;
  }

  dynamic _findMetricValue(
    Map<String, dynamic> map,
    Set<String> normalizedAliases,
  ) {
    for (final entry in map.entries) {
      if (normalizedAliases.contains(_normalizeKey(entry.key))) {
        return entry.value;
      }
    }
    for (final value in map.values) {
      if (value is Map) {
        final found = _findMetricValue(
          Map<String, dynamic>.from(value),
          normalizedAliases,
        );
        if (found != null) return found;
      }
    }
    return null;
  }

  double? _parseMetricValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final normalized = value
        .toString()
        .trim()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^\d.+-]'), '');
    return double.tryParse(normalized);
  }

  String _normalizeKey(String key) =>
      key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

  Future<void> selectOverall() async {
    selectedPeriod.value = 'this_year';
    await fetchTotals();
  }

  Future<void> selectPeriod(String period) async {
    selectedPeriod.value = period;
    await fetchTotals();
  }

  Future<void> selectThisMonth() async {
    selectedMonth.value = _clock();
    selectedPeriod.value = 'this_month';
    await fetchTotals();
  }

  Future<void> selectMonth(DateTime month) async {
    selectedMonth.value = DateTime(month.year, month.month);
    selectedPeriod.value = 'month_${month.year}_${month.month}';
    await fetchTotals();
  }

  Future<void> selectYear(int year) async {
    selectedMonth.value = DateTime(year, selectedMonth.value.month);
    selectedPeriod.value = 'year';
    await fetchTotals();
  }
}
