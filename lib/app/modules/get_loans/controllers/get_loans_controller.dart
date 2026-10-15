
import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:get/get.dart';

class GetLoansController extends GetxController {
  static const String url =
      'https://budgetbook.in/api/api/loans';

  final ApiService apiService = ApiService();

  final RxMap<String, dynamic> loan =
      <String, dynamic>{}.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isDeleting = false.obs;
  final RxString loadError = ''.obs;

  String? get loanId =>
      (loan['id'] ??
              loan['loanId'] ??
              loan['loan_id'])
          ?.toString();

  @override
  void onInit() {
    super.onInit();

    final argument = Get.arguments;

    if (argument is Map) {
      loan.assignAll(
        Map<String, dynamic>.from(argument),
      );
    }

    fetchLoan();
  }

  // ================= FETCH LOAN =================

  Future<void> fetchLoan() async {
    if (isLoading.value) return;

    final id = loanId;

    if (id == null || id.isEmpty) {
      loadError.value =
          'The selected loan has no ID.';
      return;
    }

    try {
      isLoading.value = true;
      loadError.value = '';

      // Uses ApiService.get() and its saved token.
      final response = await apiService.get(url);

      final decoded = _decodeResponse(
        response.body,
        response.statusCode,
      );

      if (decoded == null) return;

      final data = decoded['data'];
      List<dynamic> records = [];

      if (data is List) {
        records = data;
      } else if (data is Map && data['data'] is List) {
        records = data['data'] as List;
      } else if (data is Map) {
        final record =
            Map<String, dynamic>.from(data);

        if (_getId(record) == id) {
          loan.assignAll(record);
          return;
        }
      }

      Map<String, dynamic>? selectedLoan;

      for (final item in records) {
        if (item is Map) {
          final record =
              Map<String, dynamic>.from(item);

          if (_getId(record) == id) {
            selectedLoan = record;
            break;
          }
        }
      }

      if (selectedLoan != null) {
        loan.assignAll(selectedLoan);
      } else {
        loadError.value = 'Loan not found.';
      }
    } catch (error) {
      loadError.value = 'Unable to load loan details.';
      print('Fetch loan error: $error');
    } finally {
      isLoading.value = false;
    }
  }

  String? _getId(Map<String, dynamic> record) =>
      (record['id'] ??
              record['loanId'] ??
              record['loan_id'])
          ?.toString();

  // ================= UPDATE LOAN =================

  Future<bool> updateLoan(
    Map<String, dynamic> body,
  ) async {
    final id = loanId;

    if (id == null || id.isEmpty) {
      showMessage(
        'Error',
        'The selected loan has no ID.',
      );
      return false;
    }

    if (isSaving.value) return false;

    try {
      isSaving.value = true;
      loadError.value = '';

      // Uses ApiService.put() and its saved token.
      final response = await apiService.put(
        '$url/$id',
        body,
      );

      final decoded = _decodeResponse(
        response.body,
        response.statusCode,
      );

      if (decoded == null) {
        showMessage(
          'Update Failed',
          loadError.value,
        );
        return false;
      }

      final data = decoded['data'];

      if (data is Map) {
        loan.assignAll(
          Map<String, dynamic>.from(data),
        );
      } else {
        loan.addAll(body);
      }

      showMessage(
        'Success',
        decoded['message']?.toString() ??
            'Loan updated successfully.',
      );

      return true;
    } catch (error) {
      showMessage(
        'Network Error',
        'Unable to update loan.',
      );
      print('Update loan error: $error');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ================= DELETE LOAN =================

  Future<bool> deleteLoan() async {
    final id = loanId;

    if (id == null || id.isEmpty) {
      showMessage(
        'Error',
        'The selected loan has no ID.',
      );
      return false;
    }

    if (isDeleting.value) return false;

    try {
      isDeleting.value = true;
      loadError.value = '';

      // Uses ApiService.delete() and its saved token.
      final response = await apiService.delete(
        '$url/$id',
      );

      final decoded = _decodeResponse(
        response.body,
        response.statusCode,
      );

      if (decoded == null) {
        showMessage(
          'Delete Failed',
          loadError.value,
        );
        return false;
      }

      showMessage(
        'Success',
        decoded['message']?.toString() ??
            'Loan deleted successfully.',
      );

      return true;
    } catch (error) {
      showMessage(
        'Network Error',
        'Unable to delete loan.',
      );
      print('Delete loan error: $error');
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  // ================= RESPONSE HANDLING =================

  Map<String, dynamic>? _decodeResponse(
    String body,
    int statusCode,
  ) {
    dynamic decoded;

    try {
      decoded = body.isEmpty &&
              statusCode >= 200 &&
              statusCode < 300
          ? <String, dynamic>{
              'status': 'success',
            }
          : jsonDecode(body);
    } on FormatException {
      loadError.value =
          'Invalid server response. HTTP $statusCode.';
      return null;
    }

    if (decoded is! Map) {
      loadError.value =
          'Unexpected API response format.';
      return null;
    }

    if (statusCode < 200 ||
        statusCode >= 300 ||
        (decoded['status'] != null &&
            decoded['status']
                    .toString()
                    .toLowerCase() !=
                'success')) {
      loadError.value =
          decoded['message']?.toString() ??
              'The request failed.';
      return null;
    }

    return Map<String, dynamic>.from(decoded);
  }

  // ================= FIELD HELPERS =================

  double number(String key) {
    return double.tryParse(
          loan[key]?.toString() ?? '',
        ) ??
        0.0;
  }

  String value(
    String key, {
    String fallback = '—',
  }) {
    final current = loan[key]?.toString().trim();

    if (current == null || current.isEmpty) {
      return fallback;
    }

    return current;
  }

  // ================= SNACKBAR =================

  void showMessage(
    String title,
    String message,
  ) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}
