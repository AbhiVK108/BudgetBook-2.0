import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ChitSummaryController extends GetxController {
  ChitSummaryController({
    required this.chitUuid,
    required this.chit,
    ApiService? apiService,
  }) : apiService = apiService ?? ApiService();

  final String chitUuid;
  final Map<String, dynamic> chit;
  final ApiService apiService;

  final RxMap<String, dynamic> summary = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> payouts = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingPayouts = false.obs;
  final RxString loadError = ''.obs;
  final RxString payoutsError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSummary();
    fetchPayouts();
  }

  Future<void> refreshSummary() async {
    await Future.wait([fetchSummary(), fetchPayouts()]);
  }

  Future<void> fetchSummary() async {
    if (isLoading.value) return;
    isLoading.value = true;
    loadError.value = '';
    try {
      final response = await apiService.getChitSummary(chitUuid);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Failed to load chit summary (${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned an invalid chit summary.',
        );
      }
      if (decoded is! Map) {
        throw const FormatException('Unexpected chit summary response.');
      }

      final responseData = Map<String, dynamic>.from(decoded);
      if (responseData['success'] == false) {
        throw FormatException(
          responseData['message']?.toString() ??
              'The chit summary could not be loaded.',
        );
      }
      final parsedSummary = _summaryFromResponse(responseData);
      if (parsedSummary == null) {
        throw const FormatException('Unexpected chit summary response.');
      }
      summary.assignAll(parsedSummary);
    } on FormatException catch (error) {
      loadError.value = error.message;
      debugPrint('Unable to fetch chit summary: ${error.message}');
    } catch (error, stackTrace) {
      loadError.value = 'Unable to load the chit summary. Please retry.';
      debugPrint('Unable to fetch chit summary: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic>? _summaryFromResponse(Map<String, dynamic> response) {
    dynamic value = response['data'] ?? response['summary'];
    value ??= Map<String, dynamic>.from(response)
      ..remove('success')
      ..remove('status')
      ..remove('message');
    if (value is Map) {
      final nestedSummary = value['summary'] ?? value['chit_summary'];
      if (nestedSummary is Map) value = nestedSummary;
    }
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  Future<void> fetchPayouts() async {
    if (isLoadingPayouts.value) return;
    isLoadingPayouts.value = true;
    payoutsError.value = '';
    try {
      final response = await apiService.getChitPayouts(chitUuid);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Failed to load payouts (${response.statusCode}).',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Unexpected payouts response.');
      }
      final envelope = Map<String, dynamic>.from(decoded);
      if (envelope['success'] == false) {
        throw FormatException(
          envelope['message']?.toString() ?? 'The payouts could not be loaded.',
        );
      }
      payouts.assignAll(_payoutItems(envelope));
    } on FormatException catch (error) {
      payoutsError.value = error.message;
    } catch (_) {
      payoutsError.value = 'Unable to load payouts. Please retry.';
    } finally {
      isLoadingPayouts.value = false;
    }
  }

  List<Map<String, dynamic>> _payoutItems(Map<String, dynamic> envelope) {
    dynamic data = envelope['data'] ?? envelope['payouts'];
    dynamic items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = data['items'] ?? data['payouts'] ?? data['data'];
    }
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  String? _responseMessage(String body) {
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
}
