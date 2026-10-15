import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostIncomeController extends GetxController {
  // ================= API SERVICE =================

  final ApiService apiService = ApiService();

  final String categoryUrl =
      'https://budgetbook.in/api/api/categories';

  final String incomeUrl =
      'https://budgetbook.in/api/api/income';

  // ================= CATEGORIES =================

  final categories = <Map<String, dynamic>>[].obs;

  final isLoadingCategories = false.obs;

  // Selected category index
  final selectedIndex = (-1).obs;

  // Selected category ID
  final selectedCategoryId = RxnString();

  // ================= FORM =================

  final amountController = TextEditingController();

  final noteController = TextEditingController();

  final selectedDate = ''.obs;

  final isSavingIncome = false.obs;

  // ================= INIT =================

  @override
  void onInit() {
    super.onInit();

    selectedDate.value =
        _formatDate(DateTime.now());

    getIncomeCategories();
  }

  // ============================================================
  // GET INCOME CATEGORIES
  // ============================================================

  Future<void> getIncomeCategories() async {
    try {
      isLoadingCategories.value = true;

      final response = await apiService.get(
        categoryUrl,
      );

      debugPrint(
        'CATEGORY STATUS: ${response.statusCode}',
      );

      debugPrint(
        'CATEGORY RESPONSE: ${response.body}',
      );

      if (response.statusCode == 401) {
        Get.snackbar(
          'Session Expired',
          'Please login again',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (response.statusCode != 200) {
        Get.snackbar(
          'Error',
          'Unable to fetch categories',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (response.body.isEmpty) {
        Get.snackbar(
          'Error',
          'Empty response from server',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is! Map<String, dynamic> ||
          decoded['data'] is! List) {
        throw const FormatException(
          'Invalid categories response',
        );
      }

      final List<dynamic> data =
          decoded['data'];

      // Only active income categories
      final incomeCategories = data
          .where((item) {
            if (item is! Map) {
              return false;
            }

            final type = item['categoryType']
                ?.toString()
                .trim()
                .toLowerCase();

            final status = item['status']
                ?.toString()
                .trim();

            return type == 'income' &&
                status == '1';
          })
          .map<Map<String, dynamic>>(
            (item) {
              return Map<String, dynamic>.from(
                item as Map,
              );
            },
          )
          .toList();

      categories.assignAll(
        incomeCategories,
      );

      // Reset selection after loading
      selectedIndex.value = -1;
      selectedCategoryId.value = null;

      debugPrint(
        'Income categories loaded: '
        '${categories.length}',
      );

      for (int i = 0;
          i < categories.length;
          i++) {
        debugPrint(
          'Category $i : '
          '${categories[i]['categoryName']} '
          'ID=${categories[i]['id']}',
        );
      }
    } catch (e) {
      debugPrint(
        'CATEGORY API ERROR: $e',
      );

      Get.snackbar(
        'Error',
        'Failed to load income categories',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // ============================================================
  // SELECT CATEGORY
  // ============================================================

  void selectCategory(int index) {
    debugPrint(
      'Category tapped: $index',
    );

    if (index < 0 ||
        index >= categories.length) {
      debugPrint(
        'Invalid category index',
      );
      return;
    }

    final category =
        categories[index];

    final categoryId =
        category['id']?.toString();

    if (categoryId == null ||
        categoryId.isEmpty) {
      debugPrint(
        'Category ID is missing',
      );
      return;
    }

    // Update selected index
    selectedIndex.value = index;

    // Update selected category ID
    selectedCategoryId.value =
        categoryId;

    debugPrint(
      '================================',
    );

    debugPrint(
      'SELECTED CATEGORY',
    );

    debugPrint(
      'Index: $index',
    );

    debugPrint(
      'Category: '
      '${category['categoryName']}',
    );

    debugPrint(
      'Category ID: $categoryId',
    );

    debugPrint(
      '================================',
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day}-'
        '${date.month}-'
        '${date.year}';
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime? _parseDate(String date) {
    try {
      final parts =
          date.split('-');

      if (parts.length != 3) {
        return null;
      }

      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> pickDate() async {
    final now =
        DateTime.now();

    final picked =
        await showDatePicker(
      context: Get.context!,
      initialDate:
          _parseDate(
                selectedDate.value,
              ) ??
              now,
      firstDate:
          DateTime(2020),
      lastDate:
          DateTime(2030),
    );

    if (picked != null) {
      selectedDate.value =
          _formatDate(picked);
    }
  }

  // ============================================================
  // API DATE FORMAT
  // ============================================================

  String _formatApiDate(
    DateTime date,
  ) {
    final year =
        date.year.toString();

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final hour =
        date.hour
            .toString()
            .padLeft(2, '0');

    final minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final second =
        date.second
            .toString()
            .padLeft(2, '0');

    return '$year-$month-$day '
        '$hour:$minute:$second';
  }

  // ============================================================
  // SAVE INCOME
  // ============================================================

  Future<void> saveIncome() async {
    final amount =
        amountController.text.trim();

    final description =
        noteController.text.trim();

    // ================= CATEGORY =================

    if (selectedCategoryId.value ==
            null ||
        selectedCategoryId.value!
            .isEmpty) {
      Get.snackbar(
        'Required',
        'Please select an income category',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    // ================= AMOUNT =================

    if (amount.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter amount',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    final parsedAmount =
        double.tryParse(amount);

    if (parsedAmount == null ||
        parsedAmount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid amount',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    // ================= PREVENT DOUBLE TAP =================

    if (isSavingIncome.value) {
      return;
    }

    try {
      isSavingIncome.value =
          true;

      final date =
          _parseDate(
                selectedDate.value,
              ) ??
              DateTime.now();

      final incomeDate =
          _formatApiDate(date);

      // ================= FORM DATA =================

      final requestBody =
          <String, String>{
        'categoryId':
            selectedCategoryId.value!,

        'amount':
            amount,

        'incomeDate':
            incomeDate,

        'description':
            description,

        'receipt':
            '',
      };

      debugPrint(
        'INCOME REQUEST: '
        '${jsonEncode(requestBody)}',
      );

      // ================= API =================

      final response =
          await apiService.postFormData(
        incomeUrl,
        requestBody,
      );

      debugPrint(
        'INCOME STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'INCOME RESPONSE: '
        '${response.body}',
      );

      if (response.body.isEmpty) {
        Get.snackbar(
          'Server Error',
          'Empty response from server',
          snackPosition:
              SnackPosition.BOTTOM,
        );
        return;
      }

      final decoded =
          jsonDecode(response.body);

      final Map<String, dynamic>
          data =
          decoded
                  is Map<String, dynamic>
              ? decoded
              : <String, dynamic>{};

      // ================= SUCCESS =================

      if (response.statusCode >=
              200 &&
          response.statusCode < 300) {
        Get.snackbar(
          'Success',
          data['message']
                  ?.toString() ??
              'Income saved successfully',
          snackPosition:
              SnackPosition.BOTTOM,
        );

        amountController.clear();
        noteController.clear();

        selectedIndex.value = -1;

        selectedCategoryId.value =
            null;

        Get.back();
      }

      // ================= UNAUTHORIZED =================

      else if (response.statusCode ==
          401) {
        Get.snackbar(
          'Session Expired',
          'Please login again',
          snackPosition:
              SnackPosition.BOTTOM,
        );
      }

      // ================= ERROR =================

      else {
        Get.snackbar(
          'Error',
          data['message']
                  ?.toString() ??
              'Unable to save income',
          snackPosition:
              SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint(
        'INCOME API ERROR: $e',
      );

      Get.snackbar(
        'Connection Error',
        'Unable to save income. Please try again.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
    } finally {
      isSavingIncome.value =
          false;
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshCategories() async {
    await getIncomeCategories();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();

    super.onClose();
  }
}

