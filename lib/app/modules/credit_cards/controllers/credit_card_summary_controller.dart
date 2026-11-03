import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class CreditCardSummaryController extends GetxController {
  CreditCardSummaryController({
    required this.cardUuid,
    required this.card,
    ApiService? apiService,
  }) : apiService = apiService ?? ApiService();

  final String cardUuid;
  final Map<String, dynamic> card;
  final ApiService apiService;
  final summary = <String, dynamic>{}.obs;
  final transactions = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isTransactionsLoading = false.obs;
  final errorMessage = ''.obs;
  final transactionsErrorMessage = ''.obs;
  final expenseCategories = <Map<String, dynamic>>[].obs;
  final isCategoriesLoading = false.obs;
  final isPostingPurchase = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSummary();
    // Keep the transaction feed independent from the summary request so a
    // partial outage does not hide card activity.
    fetchTransactions();
  }

  Future<void> refreshData() async {
    await Future.wait([fetchSummary(), fetchTransactions()]);
  }

  Future<void> fetchSummary() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await apiService.getCreditCardSummary(cardUuid);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _message(response.body) ??
              'Unable to load credit card details (${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException('Invalid card summary.');
      final envelope = Map<String, dynamic>.from(decoded);
      if (envelope['success'] == false) {
        throw FormatException(
          _message(response.body) ?? 'Unable to load credit card details.',
        );
      }
      final value = envelope['data'] ?? envelope['summary'] ?? envelope;
      if (value is! Map) throw const FormatException('Invalid card summary.');
      final parsed = Map<String, dynamic>.from(value);
      final nested = parsed['summary'] ?? parsed['credit_card_summary'];
      summary.assignAll(
        nested is Map ? Map<String, dynamic>.from(nested) : parsed,
      );
    } on FormatException catch (error) {
      errorMessage.value = error.message;
      debugPrint('Unable to fetch credit card summary: ${error.message}');
    } catch (error, stackTrace) {
      errorMessage.value = 'Unable to load credit card details. Please retry.';
      debugPrint('Unable to fetch credit card summary: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTransactions() async {
    if (isTransactionsLoading.value) return;
    isTransactionsLoading.value = true;
    transactionsErrorMessage.value = '';
    try {
      final response = await apiService.getCreditCardTransactions(cardUuid);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _message(response.body) ??
              'Unable to load credit card transactions (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid credit card transactions.');
      }
      final envelope = Map<String, dynamic>.from(decoded);
      if (envelope['success'] == false) {
        throw FormatException(
          _message(response.body) ?? 'Unable to load credit card transactions.',
        );
      }

      final data = envelope['data'];
      final rawItems = data is List
          ? data
          : data is Map
          ? (data['items'] ?? data['transactions'] ?? data['purchases'])
          : (envelope['items'] ?? envelope['transactions']);
      if (rawItems is! List) {
        throw const FormatException(
          'The credit card transaction response was invalid.',
        );
      }
      transactions.assignAll(
        rawItems.whereType<Map>().map(Map<String, dynamic>.from),
      );
    } on FormatException catch (error) {
      transactionsErrorMessage.value = error.message;
      debugPrint('Unable to fetch credit card transactions: ${error.message}');
    } catch (error, stackTrace) {
      transactionsErrorMessage.value =
          'Unable to load credit card transactions. Please retry.';
      debugPrint('Unable to fetch credit card transactions: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isTransactionsLoading.value = false;
    }
  }

  Future<void> fetchExpenseCategories() async {
    if (isCategoriesLoading.value) return;
    isCategoriesLoading.value = true;
    try {
      final response = await apiService.get(
        '${ApiService.categoriesUrl}?type=expense',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _message(response.body) ?? 'Unable to load expense categories.',
        );
      }
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      final items = data is List
          ? data
          : data is Map && data['items'] is List
          ? data['items'] as List
          : const <dynamic>[];
      expenseCategories.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((item) {
          final uuid = (item['uuid'] ?? item['category_uuid'])
              ?.toString()
              .trim();
          final type = (item['type'] ?? item['category_type'])
              ?.toString()
              .toLowerCase();
          final status = item['status']?.toString().toLowerCase();
          return uuid != null &&
              uuid.isNotEmpty &&
              (type == null || type == 'expense') &&
              (status == null || status == 'active' || status == '1');
        }),
      );
    } catch (error) {
      debugPrint('Unable to fetch credit card expense categories: $error');
      Get.snackbar('Unable to load categories', 'Please try again.');
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<bool> postPurchase({
    required String amount,
    required String transactionDate,
    required String categoryUuid,
    String? description,
    String? reference,
    String? notes,
  }) async {
    if (isPostingPurchase.value) return false;
    isPostingPurchase.value = true;
    final body = <String, dynamic>{
      'kind': 'purchase',
      'amount': amount,
      'transaction_date': transactionDate,
      'category_uuid': categoryUuid,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (reference != null && reference.trim().isNotEmpty)
        'reference': reference.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
    try {
      final response = await apiService.postCreditCardTransaction(
        cardUuid,
        body,
        idempotencyKey:
            'credit-card-purchase-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _message(response.body) ?? 'Unable to record purchase.',
        );
      }
      await Future.wait([fetchSummary(), fetchTransactions()]);
      Get.snackbar(
        'Purchase recorded',
        'Your credit card transaction was added.',
      );
      return true;
    } catch (error) {
      debugPrint('Unable to post credit card purchase: $error');
      Get.snackbar(
        'Purchase not recorded',
        error is FormatException ? error.message : 'Please try again.',
      );
      return false;
    } finally {
      isPostingPurchase.value = false;
    }
  }

  String? _message(String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map) {
        final message = value['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
