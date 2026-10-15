
import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostExpenseController extends GetxController {
  // API SERVICE
  final ApiService apiService = ApiService();

  final String categoryurl =
      'https://budgetbook.in/api/api/categories';

  final String url =
      'https://budgetbook.in/api/api/expense';

  // CATEGORIES
  final categories = <Map<String, dynamic>>[].obs;

  final selectedIndex = (-1).obs;
  final selectedCategoryId = RxnString();

  final isLoadingCategories = false.obs;
  final isLoading = false.obs;

  // FORM CONTROLLERS
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final selectedDate = ''.obs;

  @override
  void onInit() {
    super.onInit();

    selectedDate.value = _formatDate(DateTime.now());
    getExpenseCategories();
  }

  // GET ACTIVE EXPENSE CATEGORIES
  Future<void> getExpenseCategories() async {
    try {
      isLoadingCategories.value = true;

      final response = await apiService.get(categoryurl);

      debugPrint('Category Status: ${response.statusCode}');
      debugPrint('Category Response: ${response.body}');

      if (response.statusCode == 401) {
        showError('Session expired. Please login again.');
        return;
      }

      if (response.statusCode != 200) {
        showError(
          'Unable to fetch categories (${response.statusCode})',
        );
        return;
      }

      if (response.body.isEmpty) {
        showError('Empty response from server');
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map || decoded['data'] is! List) {
        categories.clear();
        showError('Invalid categories response');
        return;
      }

      final List<dynamic> data = decoded['data'];

      final expenseCategories = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((category) {
        final type = category['categoryType']
            ?.toString()
            .toLowerCase()
            .trim();

        final status = category['status']?.toString().trim();

        return type == 'expense' && status == '1';
      }).toList();

      categories.assignAll(expenseCategories);

      selectedIndex.value = -1;
      selectedCategoryId.value = null;

      debugPrint('Expense Categories: ${categories.length}');
    } catch (e) {
      debugPrint('Get Categories Error: $e');
      showError('Unable to load expense categories');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // SELECT CATEGORY
  void selectCategory(int index) {
    if (index < 0 || index >= categories.length) return;

    final id = categories[index]['id'];

    if (id == null || id.toString().isEmpty) {
      showError('Invalid category ID');
      return;
    }

    selectedIndex.value = index;
    selectedCategoryId.value = id.toString();

    debugPrint(
      'Selected Category: ${categories[index]['categoryName']}',
    );
    debugPrint('Selected Category ID: $id');
  }

  // FORMAT DATE AS DD-MM-YYYY
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  // PARSE DD-MM-YYYY
  DateTime? _parseDate(String date) {
    try {
      final parts = date.split('-');

      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final parsed = DateTime(year, month, day);

      if (parsed.day != day ||
          parsed.month != month ||
          parsed.year != year) {
        return null;
      }

      return parsed;
    } catch (_) {
      return null;
    }
  }

  // FORMAT DATE FOR API
  String _formatApiDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute:$second';
  }

  // PICK DATE
  Future<void> pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: _parseDate(selectedDate.value) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      selectedDate.value = _formatDate(picked);
    }
  }

  // SAVE EXPENSE
  Future<void> savedExpense() async {
    final amountText = amountController.text.trim();
    final description = noteController.text.trim();
    final categoryId = selectedCategoryId.value;

    // VALIDATE AMOUNT
    if (amountText.isEmpty) {
      showError('Please enter an amount');
      return;
    }

    final parsedAmount = double.tryParse(amountText);

    if (parsedAmount == null ||
        !parsedAmount.isFinite ||
        parsedAmount <= 0) {
      showError('Please enter a valid amount');
      return;
    }

    // VALIDATE DESCRIPTION
    if (description.isEmpty) {
      showError('Please enter a description');
      return;
    }

    // VALIDATE CATEGORY
    if (categoryId == null || categoryId.isEmpty) {
      showError('Please select a category');
      return;
    }

    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final parsedDate =
          _parseDate(selectedDate.value) ?? DateTime.now();

      final expenseDate = _formatApiDate(parsedDate);

      // FORM DATA
      //
      // Confirm these field names with your expense API.
      final Map<String, String> requestBody = {
        'categoryId': categoryId,
        'amount': parsedAmount.toString(),
        'expenseDate': expenseDate,
        'description': description,
        'receipt': '',
      };

      debugPrint(
        'Expense Request: ${jsonEncode(requestBody)}',
      );

      // POST USING APISERVICE
      final response = await apiService.postFormData(
        url,
        requestBody,
      );

      debugPrint('Expense Status: ${response.statusCode}');
      debugPrint('Expense Response: ${response.body}');

      dynamic responseData;

      try {
        if (response.body.isNotEmpty) {
          responseData = jsonDecode(response.body);
        }
      } catch (_) {
        responseData = null;
      }

      final httpSuccess =
          response.statusCode >= 200 &&
          response.statusCode < 300;

      final apiStatus = responseData is Map
          ? responseData['status']
              ?.toString()
              .toLowerCase()
              .trim()
          : null;

      final apiError =
          apiStatus == 'error' || apiStatus == 'failed';

      if (httpSuccess && !apiError) {
        Get.snackbar(
          'Success',
          responseData is Map
              ? responseData['message']?.toString() ??
                  'Expense saved successfully'
              : 'Expense saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        amountController.clear();
        noteController.clear();

        selectedIndex.value = -1;
        selectedCategoryId.value = null;
        selectedDate.value = _formatDate(DateTime.now());

        Get.back();
      } else {
        String message = 'Unable to save expense';

        if (responseData is Map) {
          message =
              responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              message;
        }

        showError('$message (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Save Expense Error: $e');
      showError('Unable to connect to the server');
    } finally {
      isLoading.value = false;
    }
  }

  // SHOW ERROR
  void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // REFRESH CATEGORIES
  Future<void> refreshCategories() async {
    await getExpenseCategories();
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
