import 'dart:convert';
import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ChitfundController extends GetxController {
  ChitfundController({ApiService? apiService})
    : apiService = apiService ?? ApiService();
  final ApiService apiService;
  final RxMap<String, dynamic> summary = <String, dynamic>{}.obs;
  final RxString summaryError = ''.obs;
  final RxList<Map<String, dynamic>> upcomingInstallments =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> overdueInstallments =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingUpcomingInstallments = false.obs;
  final RxBool isLoadingOverdueInstallments = false.obs;
  final RxString upcomingInstallmentsError = ''.obs;
  final RxString overdueInstallmentsError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSummary();
    fetchUpcomingInstallments();
    fetchOverdueInstallments();
  }

  Future<void> refreshSummary() async => Future.wait([
    fetchSummary(),
    fetchUpcomingInstallments(),
    fetchOverdueInstallments(),
  ]);

  Future<void> fetchSummary() async {
    summaryError.value = '';
    try {
      final response = await apiService.getChitsSummary();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException('Unable to load chit summary.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] != true) {
        throw FormatException(
          decoded is Map
              ? decoded['message']?.toString() ?? 'Unable to load chit summary.'
              : 'Invalid chit summary response.',
        );
      }
      final data = decoded['data'];
      if (data is! Map)
        throw const FormatException('Invalid chit summary data.');
      summary.assignAll(Map<String, dynamic>.from(data));
    } on FormatException catch (error) {
      summaryError.value = error.message;
    } catch (error, stackTrace) {
      summaryError.value = 'Unable to load chit summary.';
      debugPrint('Unable to fetch chit summary: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<ChitSummaryMetric> get summaryMetrics => [
    ChitSummaryMetric('Total Chits', summary['total_chits'] ?? 0),
    ChitSummaryMetric('Total Chit Value', summary['total_chit_value'] ?? 0),
    ChitSummaryMetric(
      'Monthly Installment Total',
      summary['monthly_installment_total'] ?? 0,
    ),
  ];

  Future<void> fetchUpcomingInstallments() => _fetchInstallments(
    apiService.getUpcomingChitInstallments,
    upcomingInstallments,
    isLoadingUpcomingInstallments,
    upcomingInstallmentsError,
    'upcoming',
  );
  Future<void> fetchOverdueInstallments() => _fetchInstallments(
    apiService.getOverdueChitInstallments,
    overdueInstallments,
    isLoadingOverdueInstallments,
    overdueInstallmentsError,
    'overdue',
  );

  Future<void> _fetchInstallments(
    Future<dynamic> Function() request,
    RxList<Map<String, dynamic>> target,
    RxBool loading,
    RxString error,
    String kind,
  ) async {
    if (loading.value) return;
    loading.value = true;
    error.value = '';
    try {
      final response = await request();
      if (response.statusCode < 200 || response.statusCode >= 300)
        throw Exception('Unable to load $kind installments.');
      final decoded = jsonDecode(response.body);
      final items = _extract(decoded, kind: kind);
      if (items == null)
        throw const FormatException('Unexpected installments response format.');
      target.assignAll(items);
    } catch (e) {
      error.value = e is FormatException || e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Unable to load $kind installments. Please retry.';
      debugPrint('Unable to fetch $kind chit installments: $e');
    } finally {
      loading.value = false;
    }
  }

  List<Map<String, dynamic>>? _extract(dynamic value, {required String kind}) {
    if (value is List)
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    if (value is! Map) return null;
    for (final key in [
      'items',
      '${kind}_installments',
      'chit_installments',
      'installments',
      'results',
      'data',
    ]) {
      if (value.containsKey(key)) {
        final found = _extract(value[key], kind: kind);
        if (found != null) return found;
      }
    }
    return null;
  }
}

class ChitSummaryMetric {
  const ChitSummaryMetric(this.label, this.value);

  final String label;
  final dynamic value;
}
