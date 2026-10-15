import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:get/get.dart';

class PostloanController extends GetxController {
  final ApiService apiService = ApiService();
  final String url = 'https://budgetbook.in/api/api/loans';
  final RxBool isLoading = false.obs;

  Future<bool> postLoan(Map<String, String> body) async {
    if (isLoading.value) return false;

    try {
      isLoading.value = true;
      final response = await apiService.postFormData(url, body);

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        _showMessage(
          'Server Error',
          'Invalid server response. HTTP ${response.statusCode}.',
        );
        return false;
      }

      if (decoded is! Map) {
        _showMessage('Server Error', 'Unexpected API response format.');
        return false;
      }

      final message =
          decoded['message']?.toString() ?? 'Unable to save loan details.';
      final success = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['status']?.toString().toLowerCase() == 'success';

      if (success) {
        _showMessage('Success', message);
        return true;
      }

      final errors = decoded['errors'];
      final errorMessage = errors is Map
          ? errors.entries
              .map((entry) {
                final value = entry.value;
                final details = value is List ? value.join(', ') : value;
                return '${entry.key}: $details';
              })
              .join('\n')
          : message;
      _showMessage('Unable to save loan', errorMessage);
      return false;
    } catch (error) {
      _showMessage('Network Error', 'Unable to save loan details: $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}
