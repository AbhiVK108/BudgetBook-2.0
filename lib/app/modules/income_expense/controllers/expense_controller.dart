import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:budget_book_2026/app/core/constants/api_endpoints.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpenseController extends GetxController {
  ExpenseController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;
  final String baseUrl = ApiEndpoints.legacyExpenseUrl;
  static const String expenseListUrl = ApiService.expenseTransactionsUrl;

  // ================= OBSERVABLE VARIABLES =================

  final isLoading = false.obs;
  final isDeleting = false.obs;
  final isReversing = false.obs;

  final expenses = <Map<String, dynamic>>[].obs;
  final expenseReport = <String, dynamic>{}.obs;
  final isReportLoading = false.obs;

  final selectedMonth = DateTime.now().obs;
  final selectedExpensePeriod = 'this_month'.obs;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get expenseSummaryPeriodLabel {
    final period = selectedExpensePeriod.value;
    if (period == 'this_month') return 'This month';
    if (period == 'previous_month') return 'Previous month';
    if (period == 'this_year') return 'This year';
    if (period == 'previous_year') return 'Previous year';
    if (period == 'today') return 'Today';
    if (period == 'this_week') return 'This week';
    if (period.startsWith('month_')) {
      return '${_monthNames[selectedMonth.value.month - 1]} '
          '${selectedMonth.value.year}';
    }
    if (period == 'year') return selectedMonth.value.year.toString();
    return period.replaceAll('_', ' ');
  }

  void selectExpensePeriod(String period) {
    selectedExpensePeriod.value = period;
    getExpenseReport();
  }

  void selectExpenseMonth(DateTime month) {
    selectedMonth.value = DateTime(month.year, month.month);
    selectedExpensePeriod.value = 'month_${month.year}_${month.month}';
    getExpenseReport();
  }

  void selectExpenseYear(int year) {
    selectedMonth.value = DateTime(year, selectedMonth.value.month);
    selectedExpensePeriod.value = 'year';
    getExpenseReport();
  }

  // ================= INITIALIZATION =================

  @override
  void onInit() {
    super.onInit();
    getExpenses();
    getExpenseReport();
  }

  List<Map<String, dynamic>> get expenseCategoryAnalysis {
    for (final key in [
      'category_analysis',
      'largest_categories',
      'by_category',
    ]) {
      final categories = expenseReport[key];
      if (categories is List && categories.isNotEmpty) {
        final normalized = categories
            .whereType<Map>()
            .map((category) => Map<String, dynamic>.from(category))
            .map(_normalizeReportCategory)
            .toList();
        if (normalized.isNotEmpty) return normalized;
      }
    }

    final grouped = <String, Map<String, dynamic>>{};
    for (final expense in filteredExpenses) {
      final categoryName =
          expense['categoryName']?.toString() ??
          expense['category_name']?.toString() ??
          _nestedCategoryName(expense['category']) ??
          _simpleCategoryName(expense['category']) ??
          expense['category']?.toString() ??
          'Expense';
      final currency = expense['currency']?.toString() ?? 'INR';
      final key = '$currency|$categoryName';
      final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0;
      final category = grouped.putIfAbsent(
        key,
        () => <String, dynamic>{
          'category_name': categoryName,
          'currency': currency,
          'amount': 0.0,
          'transaction_count': 0,
        },
      );
      category['amount'] =
          (double.tryParse(category['amount'].toString()) ?? 0) + amount;
      category['transaction_count'] =
          (category['transaction_count'] as int) + 1;
    }

    final categories = grouped.values.toList();
    final total = categories.fold<double>(
      0,
      (sum, category) =>
          sum + (double.tryParse(category['amount'].toString()) ?? 0),
    );
    for (final category in categories) {
      final amount = double.tryParse(category['amount'].toString()) ?? 0;
      category['amount'] = amount.toStringAsFixed(2);
      category['percentage_of_total'] = total == 0
          ? '0.00'
          : (amount / total * 100).toStringAsFixed(2);
    }
    categories.sort(
      (a, b) => (double.tryParse(b['amount'].toString()) ?? 0).compareTo(
        double.tryParse(a['amount'].toString()) ?? 0,
      ),
    );
    return categories;
  }

  List<Map<String, dynamic>> get reportTotals {
    final totals = expenseReport['totals_by_currency'];
    if (totals is! List) return const [];
    return totals.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Map<String, dynamic> _normalizeReportCategory(Map<String, dynamic> category) {
    final nestedName = _nestedCategoryName(category['category']);
    final name =
        category['category_name']?.toString() ??
        category['categoryName']?.toString() ??
        nestedName ??
        category['name']?.toString() ??
        'Expense';
    final amount =
        category['amount'] ??
        category['total_amount'] ??
        category['expense'] ??
        '0.00';

    return <String, dynamic>{
      ...category,
      'category_name': name,
      'amount': amount.toString(),
      'transaction_count':
          category['transaction_count'] ?? category['count'] ?? 0,
      'currency': category['currency']?.toString() ?? 'INR',
      'percentage_of_total': category['percentage_of_total'] ?? '0.00',
    };
  }

  String? _nestedCategoryName(dynamic category) {
    if (category is Map) {
      return category['category_name']?.toString() ??
          category['categoryName']?.toString() ??
          category['name']?.toString();
    }
    return null;
  }

  String? _simpleCategoryName(dynamic category) {
    if (category == null || category is Map) return null;
    return category.toString();
  }

  Future<void> getExpenseReport() async {
    try {
      isReportLoading.value = true;
      final queryParameters = {'period': selectedExpensePeriod.value};
      if (selectedExpensePeriod.value.startsWith('month_')) {
        queryParameters['period'] = 'month';
        queryParameters['month'] = selectedMonth.value.month.toString();
        queryParameters['year'] = selectedMonth.value.year.toString();
      } else if (selectedExpensePeriod.value == 'year') {
        queryParameters['year'] = selectedMonth.value.year.toString();
      }
      final uri = Uri.parse(
        ApiService.expenseReportUrl,
      ).replace(queryParameters: queryParameters);
      final response = await apiService.get(uri.toString());
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded is Map &&
          decoded['success'] == true &&
          decoded['data'] is Map) {
        expenseReport.assignAll(
          Map<String, dynamic>.from(decoded['data'] as Map),
        );
      } else {
        expenseReport.clear();
      }
    } catch (error) {
      debugPrint('EXPENSE REPORT ERROR: $error');
      expenseReport.clear();
    } finally {
      isReportLoading.value = false;
    }
  }

  // ================= GET EXPENSES =================

  Future<void> getExpenses() async {
    try {
      isLoading.value = true;

      final response = await apiService.get(
        '$expenseListUrl?page=1&per_page=20',
      );

      debugPrint('EXPENSE STATUS: ${response.statusCode}');

      if (response.statusCode == 401) {
        // Get.snackbar(
        //   'Session Expired',
        //   'Please login again',
        //   snackPosition: SnackPosition.BOTTOM,
        // );
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        Get.snackbar(
          'Error',
          'Unable to load expenses.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (response.body.isEmpty) {
        expenses.clear();
        return;
      }

      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      final records = data is Map ? data['items'] : null;

      if (decoded is! Map || decoded['success'] != true || records is! List) {
        Get.snackbar(
          'Error',
          decoded is Map
              ? decoded['message']?.toString() ??
                    'Invalid expense data received.'
              : 'Invalid expense data received.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      expenses.assignAll(
        records
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );

      debugPrint('EXPENSES LOADED: ${expenses.length}');
    } catch (e) {
      debugPrint('GET EXPENSE ERROR: $e');

      Get.snackbar(
        'Error',
        'Failed to load expenses',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= FILTER EXPENSES BY MONTH =================

  List<Map<String, dynamic>> get filteredExpenses {
    final now = DateTime.now();
    return expenses.where((expense) {
      final dateValue =
          expense['transaction_date'] ??
          expense['expenseDate'] ??
          expense['expense_date'] ??
          expense['date'] ??
          expense['created_at'];

      if (dateValue == null) return false;

      final date = _parseExpenseDate(dateValue.toString());

      if (date == null) return false;

      switch (selectedExpensePeriod.value) {
        case 'today':
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        case 'this_week':
          final weekStart = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: now.weekday - DateTime.monday));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return !date.isBefore(weekStart) && !date.isAfter(weekEnd);
        case 'previous_month':
          final previousMonth = DateTime(now.year, now.month - 1);
          return date.year == previousMonth.year &&
              date.month == previousMonth.month;
        case 'this_year':
          return date.year == now.year;
        case 'previous_year':
          return date.year == now.year - 1;
        case 'year':
          return date.year == selectedMonth.value.year;
      }
      return date.year == selectedMonth.value.year &&
          date.month == selectedMonth.value.month;
    }).toList();
  }

  // ================= MONTHLY TOTAL =================

  double get filteredTotalExpense {
    return filteredExpenses.fold<double>(0.0, (total, expense) {
      final amount =
          double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;

      return total + amount;
    });
  }

  Future<void> exportExpenseReportPdf() async {
    if (expenseReport.isEmpty) {
      await getExpenseReport();
    }
    if (expenseReport.isEmpty) return;

    final document = pw.Document();
    final totals = reportTotals;
    final categories = expenseCategoryAnalysis;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Expense Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${expenseReport['from_date'] ?? ''} to ${expenseReport['to_date'] ?? ''}',
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...totals.map(
            (total) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '${total['currency'] ?? ''}: '
                '${total['total_amount'] ?? '0.00'} '
                '(${total['transaction_count'] ?? 0} transactions)',
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Category Analysis',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Category', 'Amount', 'Transactions', 'Share'],
            data: categories
                .map(
                  (category) => [
                    category['category_name']?.toString() ?? '',
                    category['amount']?.toString() ?? '0.00',
                    category['transaction_count']?.toString() ?? '0',
                    '${category['percentage_of_total'] ?? '0'}%',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Expense Transactions',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Category', 'Date', 'Amount'],
            data: filteredExpenses
                .map(
                  (expense) => [
                    expense['categoryName']?.toString() ??
                        expense['category_name']?.toString() ??
                        _nestedCategoryName(expense['category']) ??
                        'Expense',
                    expense['transaction_date']?.toString() ??
                        expense['expenseDate']?.toString() ??
                        expense['expense_date']?.toString() ??
                        '',
                    expense['amount']?.toString() ?? '0.00',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    final bytes = await document.save();
    final filename =
        'expense-report-${expenseReport['from_date'] ?? DateTime.now().toIso8601String().substring(0, 10)}.pdf';
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE4E7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share PDF'),
                onTap: () {
                  Get.back();
                  shareExpenseReportPdf(bytes, filename);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Download to device'),
                onTap: () {
                  Get.back();
                  downloadExpenseReportPdf(bytes, filename);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> shareExpenseReportPdf(List<int> bytes, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: filename),
    );
  }

  Future<void> downloadExpenseReportPdf(
    List<int> bytes,
    String filename,
  ) async {
    await FilePicker.saveFile(
      dialogTitle: 'Save Expense Report',
      fileName: filename,
      bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      mimeType: 'application/pdf',
    );
  }

  static bool canOfferExpenseReversal(Map<String, dynamic> expense) {
    final type = expense['type']?.toString().trim().toLowerCase();
    if (type != null && type.isNotEmpty && type != 'expense') return false;

    final uuid = expense['uuid']?.toString().trim();
    if (uuid == null || uuid.isEmpty) return false;

    for (final key in ['is_reversed', 'reversed']) {
      if (_isTrue(expense[key])) return false;
    }

    for (final key in [
      'reversed_at',
      'reversal_uuid',
      'reversal_transaction_uuid',
    ]) {
      final value = expense[key];
      if (value != null && value.toString().trim().isNotEmpty) return false;
    }

    for (final key in ['is_reversible', 'can_reverse', 'reversible']) {
      if (expense[key] != null && _isFalse(expense[key])) return false;
    }

    final status = (expense['reversal_status'] ?? expense['status'])
        ?.toString()
        .trim()
        .toLowerCase();
    return status != 'reversed';
  }

  static bool _isTrue(dynamic value) {
    if (value == true || value == 1) return true;
    return const {
      'true',
      '1',
      'yes',
    }.contains(value?.toString().trim().toLowerCase());
  }

  static bool _isFalse(dynamic value) {
    if (value == false || value == 0) return true;
    return const {
      'false',
      '0',
      'no',
    }.contains(value?.toString().trim().toLowerCase());
  }

  Future<void> confirmExpenseReversal(String expenseUuid) async {
    if (expenseUuid.trim().isEmpty || isReversing.value) return;

    final shouldContinue = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reverse this expense?'),
        content: const Text(
          'This will request a reversal of this expense transaction. '
          'Continue only if the original entry needs to be corrected or '
          'canceled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldContinue == true) await reverseExpense(expenseUuid);
  }

  Future<void> reverseExpense(String expenseUuid) async {
    final uuid = expenseUuid.trim();
    if (uuid.isEmpty || isReversing.value) return;

    isReversing.value = true;
    try {
      final reverseUrl = '$expenseListUrl/${Uri.encodeComponent(uuid)}/reverse';
      final response = await apiService.post(reverseUrl, {});
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final payload = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['success'] == true) {
        Get.snackbar(
          'Expense reversed',
          payload['message']?.toString() ??
              'The expense was reversed successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        await getExpenses();
        return;
      }

      final message =
          payload['message']?.toString() ??
          (response.statusCode == 401 || response.statusCode == 403
              ? 'Please sign in again to reverse this expense.'
              : 'Unable to reverse this expense. Please try again.');
      Get.snackbar(
        response.statusCode == 401 || response.statusCode == 403
            ? 'Session error'
            : 'Unable to reverse expense',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FormatException {
      Get.snackbar(
        'Unable to reverse expense',
        'The server returned an invalid response.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      debugPrint('EXPENSE REVERSAL ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      Get.snackbar(
        'Unable to reverse expense',
        'Unable to connect to the server. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isReversing.value = false;
    }
  }

  // ================= DATE PARSER =================

  DateTime? _parseExpenseDate(String value) {
    try {
      final parsed = DateTime.tryParse(value);

      if (parsed != null) return parsed;

      final parts = value.split('-');

      if (parts.length == 3) {
        try {
          if (parts[0].length == 4) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } catch (_) {
          return null;
        }
      }
    } catch (e) {
      debugPrint('DATE PARSE ERROR: $e');
    }

    return null;
  }

  // ================= EDIT EXPENSE =================

  Future<void> editExpense({
    required dynamic expenseId,
    required double amount,
    required String description,
    required String category,
    required String date,
  }) async {
    try {
      isLoading.value = true;

      final updateUrl = '$baseUrl/$expenseId';

      final body = {
        'amount': amount,
        'description': description,
        'category': category,
        'date': date,
      };

      debugPrint('UPDATE URL: $updateUrl');
      debugPrint('UPDATE BODY: ${jsonEncode(body)}');

      final response = await apiService.put(updateUrl, body);

      debugPrint('UPDATE STATUS: ${response.statusCode}');
      debugPrint('UPDATE RESPONSE: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Success',
          'Expense updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );

        await getExpenses();
      } else if (response.statusCode == 401) {
        // Get.snackbar(
        //   'Session Expired',
        //   'Please login again',
        //   snackPosition: SnackPosition.BOTTOM,
        // );
      } else {
        Get.snackbar(
          'Error',
          'Unable to update expense',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('UPDATE EXPENSE ERROR: $e');

      Get.snackbar(
        'Error',
        'Failed to update expense',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= DELETE EXPENSE =================

  Future<void> deleteExpense(dynamic expenseId) async {
    try {
      isDeleting.value = true;

      final deleteUrl = '$baseUrl/$expenseId';

      debugPrint('DELETE URL: $deleteUrl');

      final response = await apiService.delete(deleteUrl);

      debugPrint('DELETE STATUS: ${response.statusCode}');
      debugPrint('DELETE RESPONSE: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        Get.snackbar(
          'Success',
          'Expense deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );

        await getExpenses();
      } else if (response.statusCode == 401) {
        // Get.snackbar(
        //   'Session Expired',
        //   'Please login again',
        //   snackPosition: SnackPosition.BOTTOM,
        // );
      } else {
        Get.snackbar(
          'Error',
          'Unable to delete expense',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('DELETE EXPENSE ERROR: $e');

      Get.snackbar(
        'Error',
        'Failed to delete expense',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDeleting.value = false;
    }
  }

  // ================= DELETE CONFIRMATION =================

  void confirmDelete(dynamic expenseId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              deleteExpense(expenseId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ================= PREVIOUS MONTH =================

  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
  }

  // ================= NEXT MONTH =================

  void nextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
  }
}
