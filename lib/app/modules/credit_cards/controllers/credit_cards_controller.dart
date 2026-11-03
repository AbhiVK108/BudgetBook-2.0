import 'dart:convert';
import 'dart:io';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class CreditCardsController extends GetxController {
  CreditCardsController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;
  final cards = <Map<String, dynamic>>[].obs;
  final upcomingStatements = <Map<String, dynamic>>[].obs;
  final overdueStatements = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isStatementsLoading = false.obs;
  final isOverdueStatementsLoading = false.obs;
  final isReportLoading = false.obs;
  final reportCardCount = 0.obs;
  final reportTotals = <Map<String, dynamic>>[].obs;
  final reportErrorMessage = ''.obs;
  final errorMessage = ''.obs;
  final statementsErrorMessage = ''.obs;
  final overdueStatementsErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCreditCards();
    fetchCreditCardsReport();
    fetchUpcomingStatements();
    fetchOverdueStatements();
  }

  Future<void> fetchCreditCards() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await apiService.getCreditCards();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _message(response.body) ??
              'Credit cards request failed (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      final items = _extractItems(decoded);
      if (items == null) {
        throw const FormatException('The credit cards response was invalid.');
      }
      cards.assignAll(items);
    } on FormatException catch (error) {
      errorMessage.value = error.message;
      debugPrint('Unable to fetch credit cards: ${error.message}');
    } catch (error, stackTrace) {
      errorMessage.value = 'Unable to load credit cards. Please try again.';
      debugPrint('Unable to fetch credit cards: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCreditCardsReport() async {
    if (isReportLoading.value) return;
    isReportLoading.value = true;
    reportErrorMessage.value = '';
    try {
      final response = await apiService.getCreditCardsReport();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _message(response.body) ??
              'Credit-card report request failed (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['data'] is! Map) {
        throw const FormatException(
          'The credit-card report response was invalid.',
        );
      }
      final data = Map<String, dynamic>.from(decoded['data'] as Map);
      reportCardCount.value = _numberValue(data['card_count']).toInt();
      final totals = data['totals_by_currency'];
      reportTotals.assignAll(
        totals is List
            ? [
                for (final total in totals)
                  if (total is Map) Map<String, dynamic>.from(total),
              ]
            : const [],
      );
    } on FormatException catch (error) {
      reportErrorMessage.value = error.message;
      debugPrint('Unable to fetch credit-card report: ${error.message}');
    } catch (error, stackTrace) {
      reportErrorMessage.value =
          'Unable to load credit-card report. Please try again.';
      debugPrint('Unable to fetch credit-card report: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isReportLoading.value = false;
    }
  }

  Future<void> exportCreditCardsReportPdf() async {
    if (reportTotals.isEmpty) {
      await fetchCreditCardsReport();
    }
    if (reportTotals.isEmpty) return;

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Credit Card Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('${reportCardCount.value} credit cards'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Currency',
              'Credit limit',
              'Outstanding',
              'Available credit',
              'Utilization',
            ],
            data: reportTotals
                .map(
                  (total) => [
                    total['currency']?.toString() ?? '',
                    total['credit_limit']?.toString() ?? '0.00',
                    total['outstanding_liability']?.toString() ?? '0.00',
                    total['available_credit']?.toString() ?? '0.00',
                    '${total['credit_utilization_percent'] ?? '0.00'}%',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Amount Details',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Currency',
              'Credit balance',
              'Due',
              'Minimum due',
              'Overdue',
            ],
            data: reportTotals
                .map(
                  (total) => [
                    total['currency']?.toString() ?? '',
                    total['credit_balance']?.toString() ?? '0.00',
                    total['total_amount_due']?.toString() ?? '0.00',
                    total['minimum_amount_due']?.toString() ?? '0.00',
                    total['overdue_amount']?.toString() ?? '0.00',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    final bytes = await document.save();
    final filename =
        'credit-card-report-${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
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
                  shareCreditCardsReportPdf(bytes, filename);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Download to device'),
                onTap: () {
                  Get.back();
                  downloadCreditCardsReportPdf(bytes, filename);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> shareCreditCardsReportPdf(
    List<int> bytes,
    String filename,
  ) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: filename),
    );
  }

  Future<void> downloadCreditCardsReportPdf(
    List<int> bytes,
    String filename,
  ) async {
    await FilePicker.saveFile(
      dialogTitle: 'Save Credit Card Report',
      fileName: filename,
      bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      mimeType: 'application/pdf',
    );
  }

  Future<void> fetchUpcomingStatements() async {
    if (isStatementsLoading.value) return;
    isStatementsLoading.value = true;
    statementsErrorMessage.value = '';
    try {
      final response = await apiService.getUpcomingCreditCardStatements();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _message(response.body) ??
              'Upcoming statements request failed (${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      final items = _extractStatementItems(decoded);
      if (items == null) {
        throw const FormatException(
          'The upcoming statements response was invalid.',
        );
      }
      upcomingStatements.assignAll(items);
    } on FormatException catch (error) {
      statementsErrorMessage.value = error.message;
      debugPrint('Unable to fetch upcoming statements: ${error.message}');
    } catch (error, stackTrace) {
      statementsErrorMessage.value =
          'Unable to load upcoming statements. Please try again.';
      debugPrint('Unable to fetch upcoming statements: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isStatementsLoading.value = false;
    }
  }

  Future<void> fetchOverdueStatements() async {
    if (isOverdueStatementsLoading.value) return;
    isOverdueStatementsLoading.value = true;
    overdueStatementsErrorMessage.value = '';
    try {
      final response = await apiService.getOverdueCreditCardStatements();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _message(response.body) ??
              'Overdue statements request failed (${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      final items = _extractStatementItems(decoded);
      if (items == null) {
        throw const FormatException(
          'The overdue statements response was invalid.',
        );
      }
      overdueStatements.assignAll(items);
    } on FormatException catch (error) {
      overdueStatementsErrorMessage.value = error.message;
      debugPrint('Unable to fetch overdue statements: ${error.message}');
    } catch (error, stackTrace) {
      overdueStatementsErrorMessage.value =
          'Unable to load overdue statements. Please try again.';
      debugPrint('Unable to fetch overdue statements: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isOverdueStatementsLoading.value = false;
    }
  }

  List<Map<String, dynamic>>? _extractItems(dynamic value) {
    if (value is List) return _maps(value);
    if (value is! Map) return null;

    final map = Map<String, dynamic>.from(value);
    for (final key in ['items', 'credit_cards', 'cards']) {
      final nested = _extractItems(map[key]);
      if (nested != null) return nested;
    }
    return map['data'] == null ? null : _extractItems(map['data']);
  }

  List<Map<String, dynamic>> _maps(List<dynamic> values) => [
    for (final value in values)
      if (value is Map) Map<String, dynamic>.from(value),
  ];

  List<Map<String, dynamic>>? _extractStatementItems(dynamic value) {
    if (value is List) return _maps(value);
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    for (final key in [
      'items',
      'statements',
      'upcoming_statements',
      'overdue_statements',
      'credit_card_statements',
    ]) {
      final nested = _extractStatementItems(map[key]);
      if (nested != null) return nested;
    }
    return map['data'] == null ? null : _extractStatementItems(map['data']);
  }

  String? _message(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  num _numberValue(dynamic value) => num.tryParse(value?.toString() ?? '') ?? 0;
}
