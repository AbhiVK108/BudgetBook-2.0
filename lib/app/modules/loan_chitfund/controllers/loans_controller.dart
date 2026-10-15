
import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:get/get.dart';

class LoansController extends GetxController {
  static const String url =
      'https://budgetbook.in/api/api/loans';

  final ApiService apiService = ApiService();

  // Loan records
  final RxList<Map<String, dynamic>> loans =
      <Map<String, dynamic>>[].obs;

  // Loading and error states
  final RxBool isLoading = false.obs;
  final RxString loadError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLoans();
  }

  // ================= FETCH LOANS =================

  Future<void> fetchLoans() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      loadError.value = '';

      // ApiService automatically adds the saved Bearer token.
      final response = await apiService.get(url);

      print('Loans API status: ${response.statusCode}');

      final dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        loadError.value =
            'Invalid JSON response from server.';
        return;
      }

      if (decoded is! Map) {
        loadError.value = 'Unexpected API response format.';
        return;
      }

      final Map<String, dynamic> result =
          Map<String, dynamic>.from(decoded);

      // Check HTTP status and API status.
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          result['status']?.toString().toLowerCase() !=
              'success') {
        loadError.value =
            result['message']?.toString() ??
                'Failed to fetch loans.';

        print('Loans API error: ${response.body}');
        return;
      }

      final dynamic data = result['data'];

      if (data == null) {
        loans.clear();
        return;
      }

      if (data is List) {
        final records = data
            .whereType<Map>()
            .map(
              (record) => Map<String, dynamic>.from(record),
            )
            .toList();

        loans.assignAll(records);
      } else if (data is Map && data['data'] is List) {
        final records = (data['data'] as List)
            .whereType<Map>()
            .map(
              (record) => Map<String, dynamic>.from(record),
            )
            .toList();

        loans.assignAll(records);
      } else if (data is Map &&
          (data.containsKey('id') ||
              data.containsKey('loanId'))) {
        loans.assignAll([
          Map<String, dynamic>.from(data),
        ]);
      } else {
        loadError.value =
            'Unexpected loan list response format.';
      }
    } catch (error) {
      loadError.value = 'Unable to load loans.';
      print('Fetch loans exception: $error');
    } finally {
      isLoading.value = false;
    }
  }

  // ================= CONVERT AMOUNT =================

  double _number(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  // ================= TOTAL AMOUNTS =================

  double get totalAmount {
    return loans.fold(
      0.0,
      (sum, loan) => sum + _number(loan['totalAmount']),
    );
  }

  double get totalPaidAmount {
    return loans.fold(
      0.0,
      (sum, loan) => sum + _number(loan['paidAmount']),
    );
  }

  double get totalDueAmount {
    return loans.fold(
      0.0,
      (sum, loan) => sum + _number(loan['dueAmount']),
    );
  }

  double get totalSanctionedAmount {
    return loans.fold(
      0.0,
      (sum, loan) =>
          sum + _number(loan['sanctionedAmount']),
    );
  }

  // ================= REFRESH =================

  Future<void> refreshLoans() async {
    await fetchLoans();
  }

  // ================= SNACKBAR =================

  void showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}
