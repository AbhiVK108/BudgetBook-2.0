
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class BorrowController extends GetxController {
  final ApiService apiService = ApiService();

  final String url = 'https://budgetbook.in/api/api/credit';

  final isLoading = false.obs;
  final borrows = <Map<String, dynamic>>[].obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBorrows();
  }

  // ================= FETCH BORROW RECORDS =================

  Future<void> fetchBorrows() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Uses your ApiService and saved Bearer token.
      final response = await apiService.get(url);

      debugPrint('Borrow API status: ${response.statusCode}');
      debugPrint('Borrow API response: ${response.body}');

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        errorMessage.value = 'Invalid response received from server.';
        Get.snackbar('Error', errorMessage.value);
        return;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final String message = decoded is Map
            ? (decoded['message'] ?? 'Failed to fetch borrow records.')
                .toString()
            : 'Failed to fetch borrow records.';

        errorMessage.value = response.statusCode == 401
            ? 'Session expired. Please login again.'
            : message;

        Get.snackbar('Error', errorMessage.value);
        return;
      }

      if (decoded is Map && decoded['data'] is List) {
        final List<dynamic> records = decoded['data'];

        borrows.assignAll(
          records
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );

        debugPrint('Borrow records loaded: ${borrows.length}');
      } else {
        borrows.clear();
        errorMessage.value =
            decoded is Map
                ? (decoded['message'] ??
                        'Borrow records were not found.')
                    .toString()
                : 'Unexpected borrow API response.';

        debugPrint(errorMessage.value);
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch borrow error: $e');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage.value = 'Unable to load borrow records.';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // ================= REFRESH =================

  Future<void> refreshBorrows() async {
    await fetchBorrows();
  }

  // ================= BORROW DETAILS =================

  String nameFor(Map<String, dynamic> borrow) {
    return (borrow['givenTo'] ?? 'Unknown').toString();
  }

  String dateFor(Map<String, dynamic> borrow) {
    return (borrow['givenDate'] ?? '').toString();
  }

  String returnDateFor(Map<String, dynamic> borrow) {
    return (borrow['returnDate'] ?? '').toString();
  }

  String phoneFor(Map<String, dynamic> borrow) {
    return (borrow['phone'] ?? '').toString();
  }

  String descriptionFor(Map<String, dynamic> borrow) {
    return (borrow['description'] ?? '').toString();
  }

  String statusFor(Map<String, dynamic> borrow) {
    return (borrow['status'] ?? '').toString();
  }

  // ================= AMOUNT HELPERS =================

  double _toDouble(dynamic value) {
    return double.tryParse(
          value?.toString().replaceAll(',', '').trim() ?? '',
        ) ??
        0.0;
  }

  double amountFor(Map<String, dynamic> borrow) {
    return _toDouble(borrow['amount']);
  }

  double paidFor(Map<String, dynamic> borrow) {
    return _toDouble(borrow['paidAmount']);
  }

  double dueFor(Map<String, dynamic> borrow) {
    return _toDouble(borrow['dueAmount']);
  }

  double interestFor(Map<String, dynamic> borrow) {
    return _toDouble(borrow['interestAmount']);
  }

  double rateOfInterestFor(Map<String, dynamic> borrow) {
    return _toDouble(borrow['rateOfInterest']);
  }

  // ================= TOTALS =================

  double get totalAmount {
    return borrows.fold(
      0.0,
      (total, borrow) => total + amountFor(borrow),
    );
  }

  double get paidAmount {
    return borrows.fold(
      0.0,
      (total, borrow) => total + paidFor(borrow),
    );
  }

  double get dueAmount {
    return borrows.fold(
      0.0,
      (total, borrow) => total + dueFor(borrow),
    );
  }

  double get totalInterest {
    return borrows.fold(
      0.0,
      (total, borrow) => total + interestFor(borrow),
    );
  }

  // ================= FORMAT AMOUNT =================

  String formatAmount(double amount) {
    return '₹${amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}';
  }
}
