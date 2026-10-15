import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class LendController extends GetxController {
  final ApiService apiService = ApiService();
  final String url = 'https://budgetbook.in/api/api/debit';

  final isLoading = false.obs;
  final lends = <Map<String, dynamic>>[].obs;
  final errorMessage = ''.obs;
  final count = 0.obs;

  double _amountFor(Map<String, dynamic> lend, List<String> keys) {
    for (final key in keys) {
      final amount = double.tryParse(lend[key]?.toString() ?? '');
      if (amount != null && amount.isFinite) {
        return amount;
      }
    }
    return 0;
  }

  double get totalAmount => lends.fold(
    0,
    (total, lend) => total + _amountFor(lend, ['amount', 'totalAmount']),
  );

  double get paidAmount => lends.fold(
    0,
    (total, lend) =>
        total + _amountFor(lend, ['paidAmount', 'paid', 'receivedAmount']),
  );

  double get dueAmount {
    final hasApiDue = lends.any(
      (lend) => lend.containsKey('dueAmount') || lend.containsKey('due'),
    );
    if (hasApiDue) {
      return lends.fold(
        0,
        (total, lend) => total + _amountFor(lend, ['dueAmount', 'due']),
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

  String lendName(Map<String, dynamic> lend) {
    return (lend['receiveFrom'] ??
            lend['givenTo'] ??
            lend['person'] ??
            lend['name'] ??
            'Unknown')
        .toString();
  }

  @override
  void onInit() {
    super.onInit();
    fetchLends();
  }

  Future<void> fetchLends() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await apiService.get(url);
      debugPrint('Lend status: ${response.statusCode}');
      debugPrint('Lend response: ${response.body}');

      if (response.statusCode != 200) {
        errorMessage.value =
            'Failed to fetch lending details (${response.statusCode}).';
        Get.snackbar('Error', errorMessage.value);
        return;
      }

      final decoded = jsonDecode(response.body);
      dynamic data;

      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map) {
        data = decoded['data'];
      }

      if (data is List) {
        lends.assignAll(
          data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map) {
        lends.assignAll([Map<String, dynamic>.from(data)]);
      } else {
        lends.clear();
        errorMessage.value = 'No lending data found in the server response.';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch lends error: $e');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage.value = 'Unable to load lending details.';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  void increment() => count.value++;
}
