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

class IncomeExpenseController extends GetxController {
  IncomeExpenseController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;

  static const String incomeListUrl = ApiService.incomeTransactionsUrl;
  final String baseUrl = ApiEndpoints.legacyIncomeUrl;

  final count = 0.obs;
  final incomeList = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isDeleting = false.obs;
  final isReversing = false.obs;
  final isReportLoading = false.obs;
  final incomeReport = <String, dynamic>{}.obs;
  final selectedReportPeriod = 'this_month'.obs;
  final selectedIncomePeriod = 'this_month'.obs;

  static const List<String> incomeReportPeriods = [
    'today',
    'this_week',
    'this_month',
    'previous_month',
    'this_year',
    'previous_year',
  ];

  String get incomeSummaryPeriodLabel {
    final period = selectedIncomePeriod.value;
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

  // ================= SELECTED MONTH =================

  final selectedMonth = DateTime.now().obs;

  // Previous month
  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    if (selectedReportPeriod.value == 'custom') getIncomeReport();
  }

  // Next month
  void nextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    if (selectedReportPeriod.value == 'custom') getIncomeReport();
  }

  // ================= SELECTED INCOME DATE =================

  final selectedIncomeDate = DateTime.now().obs;

  // Date format for API: yyyy-MM-dd
  String get formattedIncomeDate {
    final date = selectedIncomeDate.value;

    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  void onInit() {
    super.onInit();
    getIncome();
    getIncomeReport();
  }

  List<Map<String, dynamic>> get reportTotals {
    final totals = incomeReport['totals_by_currency'];
    if (totals is! List) return const [];
    return totals.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  List<Map<String, dynamic>> get categoryAnalysis {
    final categories = incomeReport['category_analysis'];
    if (categories is! List) return const [];
    return categories.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  List<Map<String, dynamic>> get monthlyTrend {
    final trend = incomeReport['monthly_trend_by_currency'];
    if (trend is! List) return const [];
    return trend.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  String reportLabel(String period) {
    switch (period) {
      case 'last_month':
        return 'Last month';
      case 'this_year':
        return 'This year';
      case 'custom':
        return 'Custom month';
      default:
        return 'This month';
    }
  }

  Future<void> selectIncomePeriod(String period) async {
    selectedIncomePeriod.value = period;
    selectedReportPeriod.value = period;
    await getIncomeReport();
  }

  Future<void> selectIncomeMonth(DateTime month) async {
    selectedMonth.value = DateTime(month.year, month.month);
    selectedIncomePeriod.value = 'month_${month.year}_${month.month}';
    selectedReportPeriod.value = 'month';
    await getIncomeReport();
  }

  Future<void> selectIncomeYear(int year) async {
    selectedMonth.value = DateTime(year, selectedMonth.value.month);
    selectedIncomePeriod.value = 'year';
    selectedReportPeriod.value = 'year';
    await getIncomeReport();
  }

  Future<void> getIncomeReport() async {
    try {
      isReportLoading.value = true;
      final queryParameters = <String, String>{
        'period': selectedReportPeriod.value == 'custom'
            ? 'month'
            : selectedReportPeriod.value,
      };
      if (selectedReportPeriod.value == 'custom' ||
          selectedIncomePeriod.value.startsWith('month_')) {
        queryParameters['month'] = selectedMonth.value.month.toString();
        queryParameters['year'] = selectedMonth.value.year.toString();
      }
      if (selectedReportPeriod.value == 'year') {
        queryParameters['year'] = selectedMonth.value.year.toString();
      }
      final uri = Uri.parse(
        ApiService.incomeReportUrl,
      ).replace(queryParameters: queryParameters);
      final response = await apiService.get(uri.toString());
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded is Map &&
          decoded['success'] == true &&
          decoded['data'] is Map) {
        incomeReport.assignAll(
          Map<String, dynamic>.from(decoded['data'] as Map),
        );
      } else {
        incomeReport.clear();
        final message = decoded is Map ? decoded['message']?.toString() : null;
        Get.snackbar(
          'Unable to load income summary',
          message?.isNotEmpty == true
              ? message!
              : 'The income report could not be loaded.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on FormatException {
      incomeReport.clear();
      Get.snackbar(
        'Unable to load income summary',
        'The server returned an invalid report response.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      debugPrint('INCOME REPORT ERROR: $error');
      incomeReport.clear();
      Get.snackbar(
        'Unable to load income summary',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isReportLoading.value = false;
    }
  }

  void setReportPeriod(String period) {
    selectedReportPeriod.value = period;
    selectedIncomePeriod.value = period;
    getIncomeReport();
  }

  Future<void> exportIncomeReportPdf() async {
    if (incomeReport.isEmpty) {
      await getIncomeReport();
    }
    if (incomeReport.isEmpty) return;

    final document = pw.Document();
    final totals = reportTotals;
    final categories = categoryAnalysis;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Income Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${incomeReport['from_date'] ?? ''} to ${incomeReport['to_date'] ?? ''}',
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
            'Income Transactions',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Category', 'Date', 'Amount'],
            data: filteredIncome
                .map(
                  (income) => [
                    income['categoryName']?.toString() ??
                        income['category_name']?.toString() ??
                        'Income',
                    income['incomeDate']?.toString() ??
                        income['income_date']?.toString() ??
                        income['transaction_date']?.toString() ??
                        '',
                    income['amount']?.toString() ?? '0.00',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    final bytes = await document.save();
    final filename =
        'income-report-${incomeReport['from_date'] ?? DateTime.now().toIso8601String().substring(0, 10)}.pdf';
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
                  shareIncomeReportPdf(bytes, filename);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Download to device'),
                onTap: () {
                  Get.back();
                  downloadIncomeReportPdf(bytes, filename);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> shareIncomeReportPdf(List<int> bytes, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: filename),
    );
  }

  Future<void> downloadIncomeReportPdf(List<int> bytes, String filename) async {
    await FilePicker.saveFile(
      dialogTitle: 'Save Income Report',
      fileName: filename,
      bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      mimeType: 'application/pdf',
    );
  }

  // ================= GET INCOME =================

  Future<void> getIncome() async {
    try {
      isLoading.value = true;

      final response = await apiService.get(
        '$incomeListUrl?page=1&per_page=20',
      );

      debugPrint('GET INCOME STATUS: ${response.statusCode}');

      if (response.statusCode == 401) {
        // Get.snackbar(
        //   'Session Expired',
        //   'Please login again.',
        //   snackPosition: SnackPosition.BOTTOM,
        // );
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        Get.snackbar(
          'Error',
          'Unable to get income.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (response.body.isEmpty) {
        incomeList.clear();
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
                    'Invalid income data received.'
              : 'Invalid income data received.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      incomeList.assignAll(
        records
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );

      debugPrint('Loaded ${incomeList.length} income transactions.');
    } catch (e) {
      debugPrint('GET INCOME ERROR: $e');

      Get.snackbar(
        'Error',
        'Something went wrong while loading income.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  static bool canOfferIncomeReversal(Map<String, dynamic> transaction) {
    final type = transaction['type']?.toString().trim().toLowerCase();
    if (type != null && type.isNotEmpty && type != 'income') return false;

    final uuid = transaction['uuid']?.toString().trim();
    if (uuid == null || uuid.isEmpty) return false;

    for (final key in ['is_reversed', 'reversed']) {
      if (_isTrue(transaction[key])) return false;
    }

    for (final key in [
      'reversed_at',
      'reversal_uuid',
      'reversal_transaction_uuid',
    ]) {
      final value = transaction[key];
      if (value != null && value.toString().trim().isNotEmpty) return false;
    }

    for (final key in ['is_reversible', 'can_reverse', 'reversible']) {
      final value = transaction[key];
      if (value != null && _isFalse(value)) return false;
    }

    final status = (transaction['reversal_status'] ?? transaction['status'])
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

  Future<void> confirmIncomeReversal(String transactionUuid) async {
    if (transactionUuid.trim().isEmpty || isReversing.value) return;

    final shouldContinue = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reverse this income?'),
        content: const Text(
          'This will request a reversal of this income transaction. '
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

    if (shouldContinue != true) return;

    if (shouldContinue == true) await reverseIncome(transactionUuid);
  }

  Future<void> reverseIncome(String transactionUuid) async {
    final uuid = transactionUuid.trim();
    if (uuid.isEmpty || isReversing.value) return;

    isReversing.value = true;
    try {
      final reverseUrl = '$incomeListUrl/${Uri.encodeComponent(uuid)}/reverse';
      final response = await apiService.post(reverseUrl, {});
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final payload = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['success'] == true) {
        Get.snackbar(
          'Income reversed',
          payload['message']?.toString() ??
              'The income was reversed successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        await getIncome();
        return;
      }

      final message =
          payload['message']?.toString() ??
          (response.statusCode == 401 || response.statusCode == 403
              ? 'Please sign in again to reverse this income.'
              : 'Unable to reverse this income. Please try again.');
      Get.snackbar(
        response.statusCode == 401 || response.statusCode == 403
            ? 'Session error'
            : 'Unable to reverse income',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FormatException {
      Get.snackbar(
        'Unable to reverse income',
        'The server returned an invalid response.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      debugPrint('INCOME REVERSAL ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      Get.snackbar(
        'Unable to reverse income',
        'Unable to connect to the server. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isReversing.value = false;
    }
  }

  // ================= PARSE INCOME DATE =================

  DateTime? _parseIncomeDate(Map<String, dynamic> income) {
    final value =
        income['incomeDate'] ??
        income['incomedate'] ??
        income['income_date'] ??
        income['transaction_date'] ??
        income['date'] ??
        income['created_at'];

    if (value == null) return null;

    final dateString = value.toString().trim();

    if (dateString.isEmpty) return null;

    // Supports yyyy-MM-dd and ISO date/time formats.
    final parsedDate = DateTime.tryParse(dateString);

    if (parsedDate != null) {
      return parsedDate;
    }

    // Remove time when the date includes a time portion.
    final dateOnly = dateString.split(' ').first;

    // Supports dd-MM-yyyy.
    final parts = dateOnly.split('-');

    if (parts.length == 3) {
      try {
        if (parts[0].length == 4) {
          // yyyy-MM-dd
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          // dd-MM-yyyy
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // ================= FILTER BY SELECTED MONTH =================

  List<Map<String, dynamic>> get filteredIncome {
    return incomeList.where((income) {
      final date = _parseIncomeDate(income);

      if (date == null) return false;

      return date.year == selectedMonth.value.year &&
          date.month == selectedMonth.value.month;
    }).toList();
  }

  // ================= TOTAL INCOME =================

  // Total for all income records.
  double get totalIncome {
    double total = 0;

    for (final income in incomeList) {
      total += double.tryParse(income['amount']?.toString() ?? '0') ?? 0;
    }

    return total;
  }

  // Total for the selected month only.
  double get filteredTotalIncome {
    double total = 0;

    for (final income in filteredIncome) {
      total += double.tryParse(income['amount']?.toString() ?? '0') ?? 0;
    }

    return total;
  }

  // ================= DATE PICKER =================

  Future<void> pickIncomeDate({String? currentDate}) async {
    DateTime initialDate = selectedIncomeDate.value;

    if (currentDate != null && currentDate.isNotEmpty) {
      final parsedDate = _parseIncomeDate({'incomeDate': currentDate});

      if (parsedDate != null) {
        initialDate = parsedDate;
      }
    }

    final pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select income date',
    );

    if (pickedDate != null) {
      selectedIncomeDate.value = pickedDate;
    }
  }

  // Set date when opening an existing income record for editing.
  void setIncomeDate(String? date) {
    if (date == null || date.trim().isEmpty) {
      selectedIncomeDate.value = DateTime.now();
      return;
    }

    final parsedDate = _parseIncomeDate({'incomeDate': date});

    if (parsedDate != null) {
      selectedIncomeDate.value = parsedDate;
    } else {
      selectedIncomeDate.value = DateTime.now();
    }
  }

  // ================= EDIT INCOME =================

  Future<void> editIncome({
    required String id,
    required String categoryId,
    required String amount,
    required String incomeDate,
    required String description,
    String receipt = '',
  }) async {
    try {
      if (amount.trim().isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter amount.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isLoading.value = true;

      final response = await apiService.put('$baseUrl/$id', {
        'categoryId': categoryId,
        'amount': amount,
        'incomeDate': incomeDate,
        'description': description,
        'receipt': receipt,
      });

      debugPrint('EDIT INCOME STATUS: ${response.statusCode}');
      debugPrint('EDIT INCOME RESPONSE: ${response.body}');

      dynamic data = <String, dynamic>{};

      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Get.snackbar(
          'Success',
          data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Income updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );

        await getIncome();
      } else if (response.statusCode == 401) {
        // Get.snackbar(
        //   'Session Expired',
        //   'Please login again.',
        //   snackPosition: SnackPosition.BOTTOM,
        // );
      } else {
        Get.snackbar(
          'Error',
          data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Unable to update income.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('EDIT INCOME ERROR: $e');

      Get.snackbar(
        'Error',
        'Something went wrong while updating income.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= DELETE INCOME =================

  Future<void> deleteIncome(String incomeUuid) async {
    final uuid = incomeUuid.trim();
    if (uuid.isEmpty || isDeleting.value) return;

    isDeleting.value = true;
    try {
      final response = await apiService.deleteIncome(uuid);
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final payload = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      final isSuccess =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['success'] != false;

      if (isSuccess) {
        Get.snackbar(
          'Income deleted',
          payload['message']?.toString().isNotEmpty == true
              ? payload['message'].toString()
              : 'Income deleted successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        incomeList.removeWhere(
          (item) => item['uuid']?.toString().trim() == uuid,
        );
        await getIncome();
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        Get.snackbar(
          'Session error',
          'Please sign in again to delete this income.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Unable to delete income',
          payload['message']?.toString().isNotEmpty == true
              ? payload['message'].toString()
              : 'Unable to delete income.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on FormatException {
      Get.snackbar(
        'Unable to delete income',
        'The server returned an invalid response.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      debugPrint('DELETE INCOME ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      Get.snackbar(
        'Unable to delete income',
        'Unable to connect to the server. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDeleting.value = false;
    }
  }

  // ================= DELETE CONFIRMATION =================

  Future<void> confirmDeleteIncome(String incomeUuid) async {
    final uuid = incomeUuid.trim();
    if (uuid.isEmpty || isDeleting.value) return;

    final shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Income'),
        content: const Text(
          'This permanently deletes the income transaction and cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await deleteIncome(uuid);
    }
  }

  // ================= REFRESH =================

  Future<void> refreshIncome() async {
    await getIncome();
  }

  void increment() {
    count.value++;
  }
}
