import 'dart:convert';

import 'package:budget_book_2026/app/core/constants/api_endpoints.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostIncomeController extends GetxController {
  PostIncomeController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;

  static const String categoryUrl = '${ApiEndpoints.categoriesUrl}?type=income';

  // ================= CATEGORIES =================

  final categories = <Map<String, dynamic>>[].obs;

  final isLoadingCategories = false.obs;
  final isCreatingCategory = false.obs;

  // Selected category index
  final selectedIndex = (-1).obs;

  // Selected category ID
  final selectedCategoryId = RxnString();
  final accounts = <Map<String, dynamic>>[].obs;
  final isLoadingAccounts = false.obs;
  final selectedDestinationAccountUuid = RxnString();

  // ================= FORM =================

  final amountController = TextEditingController();

  final noteController = TextEditingController();
  final counterpartyController = TextEditingController();

  final selectedDate = ''.obs;

  final isSavingIncome = false.obs;
  String? _pendingIncomeIdempotencyKey;
  String? _pendingIncomeRequestBody;

  // ================= INIT =================

  @override
  void onInit() {
    super.onInit();

    selectedDate.value = _formatDate(DateTime.now());

    getIncomeCategories();
    getDestinationAccounts();
  }

  // ============================================================
  // GET INCOME CATEGORIES
  // ============================================================

  Future<void> getIncomeCategories() async {
    try {
      isLoadingCategories.value = true;

      final response = await apiService.get(categoryUrl);

      debugPrint('CATEGORY STATUS: ${response.statusCode}');

      if (response.statusCode == 401) {
        // Get.snackbar(
        //   'Session Expired',
        //   'Please login again',
        //   snackPosition: SnackPosition.BOTTOM,
        // );
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

      final decoded = jsonDecode(response.body);
      final rawData = decoded is Map ? decoded['data'] : null;
      final List<dynamic>? data = rawData is List
          ? rawData
          : rawData is Map && rawData['items'] is List
          ? rawData['items'] as List<dynamic>
          : null;

      if (decoded is! Map || data == null) {
        throw const FormatException('Invalid categories response');
      }

      // Only active income categories
      final incomeCategories = data
          .where((item) {
            if (item is! Map) {
              return false;
            }

            final type =
                (item['category_type'] ?? item['categoryType'] ?? item['type'])
                    ?.toString()
                    .trim()
                    .toLowerCase();

            final status = item['status']?.toString().trim();
            final uuid = (item['uuid'] ?? item['category_uuid'])
                ?.toString()
                .trim();

            return (type == null || type == 'income') &&
                uuid != null &&
                uuid.isNotEmpty &&
                (status == null ||
                    status == '1' ||
                    status.toLowerCase() == 'active');
          })
          .map<Map<String, dynamic>>((item) {
            return Map<String, dynamic>.from(item as Map);
          })
          .toList();

      categories.assignAll(incomeCategories);

      // Reset selection after loading
      selectedIndex.value = -1;
      selectedCategoryId.value = null;

      debugPrint(
        'Income categories loaded: '
        '${categories.length}',
      );
    } catch (e) {
      debugPrint('CATEGORY API ERROR: $e');

      Get.snackbar(
        'Error',
        'Failed to load income categories',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<Map<String, dynamic>?> createIncomeCategory({
    required String name,
    required String icon,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || isCreatingCategory.value) return null;

    try {
      isCreatingCategory.value = true;
      final response = await apiService.postCategory({
        'name': trimmedName,
        'type': 'income',
        'icon': icon,
        'sort_order': 100,
      });

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] != true) return null;
      final data = decoded['data'];
      if (data is! Map) return null;

      final category = Map<String, dynamic>.from(data);
      final uuid = category['uuid']?.toString();
      if (uuid == null || uuid.isEmpty) return null;

      final existingIndex = categories.indexWhere(
        (item) => item['uuid']?.toString() == uuid,
      );
      if (existingIndex >= 0) {
        categories[existingIndex] = category;
        selectCategory(existingIndex);
      } else {
        categories.add(category);
        selectCategory(categories.length - 1);
      }
      return category;
    } catch (error) {
      debugPrint('CATEGORY CREATE ERROR: ${error.runtimeType}');
      return null;
    } finally {
      isCreatingCategory.value = false;
    }
  }

  Future<void> getDestinationAccounts() async {
    isLoadingAccounts.value = true;
    try {
      final response = await apiService.getAccounts();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        Get.snackbar(
          'Error',
          'Unable to fetch bank accounts.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final decoded = jsonDecode(response.body);
      final rawData = decoded is Map ? decoded['data'] : null;
      final List<dynamic>? data = rawData is List
          ? rawData
          : rawData is Map && rawData['items'] is List
          ? rawData['items'] as List<dynamic>
          : null;
      if (decoded is! Map || data == null) {
        throw const FormatException('Invalid bank accounts response.');
      }

      accounts.assignAll(
        data.whereType<Map>().map(Map<String, dynamic>.from).where((account) {
          final uuid = (account['uuid'] ?? account['account_uuid'])
              ?.toString()
              .trim();
          return uuid != null && uuid.isNotEmpty;
        }),
      );
      if (accounts.length == 1) {
        selectDestinationAccount(accounts.first);
      }
    } catch (error) {
      debugPrint('BANK ACCOUNT API ERROR: ${error.runtimeType}');
      Get.snackbar(
        'Error',
        'Failed to load bank accounts.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  void selectDestinationAccount(Map<String, dynamic> account) {
    selectedDestinationAccountUuid.value =
        (account['uuid'] ?? account['account_uuid'])?.toString();
  }

  // ============================================================
  // SELECT CATEGORY
  // ============================================================

  void selectCategory(int index) {
    debugPrint('Category tapped: $index');

    if (index < 0 || index >= categories.length) {
      debugPrint('Invalid category index');
      return;
    }

    final category = categories[index];

    final categoryId = (category['uuid'] ?? category['category_uuid'])
        ?.toString();

    if (categoryId == null || categoryId.isEmpty) {
      debugPrint('Category ID is missing');
      return;
    }

    // Update selected index
    selectedIndex.value = index;

    // Update selected category ID
    selectedCategoryId.value = categoryId;

    debugPrint('================================');

    debugPrint('SELECTED CATEGORY');

    debugPrint('Index: $index');

    debugPrint(
      'Category: '
      '${category['name'] ?? category['category_name'] ?? category['categoryName']}',
    );

    debugPrint('Category ID: $categoryId');

    debugPrint('================================');
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  // Keep the selected date in the same YYYY-MM-DD format expected by the API.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime? _parseDate(String date) {
    return DateTime.tryParse(date.trim());
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

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

  // ============================================================
  // API DATE FORMAT
  // ============================================================

  String _formatApiDate(DateTime date) => _formatDate(date);

  // ============================================================
  // SAVE INCOME
  // ============================================================

  Future<void> saveIncome() async {
    final amount = amountController.text.trim();

    final description = noteController.text.trim();
    final counterparty = counterpartyController.text.trim();

    if (counterparty.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter the counterparty.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (description.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter a description.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // ================= CATEGORY =================

    if (selectedCategoryId.value == null || selectedCategoryId.value!.isEmpty) {
      Get.snackbar(
        'Required',
        'Please select an income category',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedDestinationAccountUuid.value == null ||
        selectedDestinationAccountUuid.value!.isEmpty) {
      Get.snackbar(
        'Required',
        'Please select a destination bank account.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // ================= AMOUNT =================

    if (amount.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter amount',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final parsedAmount = double.tryParse(amount);

    if (parsedAmount == null || parsedAmount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid amount',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // ================= PREVENT DOUBLE TAP =================

    if (isSavingIncome.value) {
      return;
    }

    try {
      isSavingIncome.value = true;

      final date = _parseDate(selectedDate.value) ?? DateTime.now();

      final incomeDate = _formatApiDate(date);

      final requestBody = <String, dynamic>{
        'amount': parsedAmount.toStringAsFixed(2),
        'transaction_date': incomeDate,
        'destination_account_uuid': selectedDestinationAccountUuid.value!,
        'category_uuid': selectedCategoryId.value!,
        'counterparty': counterparty,
        'description': description,
      };

      final encodedRequestBody = jsonEncode(requestBody);
      if (_pendingIncomeIdempotencyKey == null ||
          _pendingIncomeRequestBody != encodedRequestBody) {
        _pendingIncomeIdempotencyKey = ApiService.createIdempotencyKey();
        _pendingIncomeRequestBody = encodedRequestBody;
      }

      if (kDebugMode) {
        debugPrint('[Income] POST ${ApiService.incomeTransactionsUrl}');
        debugPrint('[Income] Request body: $encodedRequestBody');
      }

      final response = await apiService.postIncome(
        requestBody,
        idempotencyKey: _pendingIncomeIdempotencyKey!,
      );
      if (kDebugMode) {
        debugPrint('[Income] HTTP ${response.statusCode}');
        debugPrint('[Income] Response body: ${response.body}');
      }

      if (response.body.isEmpty) {
        Get.snackbar(
          'Server Error',
          'Empty response from server',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final decoded = jsonDecode(response.body);

      final data = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      // ================= SUCCESS =================

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        _pendingIncomeIdempotencyKey = null;
        _pendingIncomeRequestBody = null;
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Income saved successfully',
          snackPosition: SnackPosition.BOTTOM,
        );

        amountController.clear();
        noteController.clear();
        counterpartyController.clear();

        selectedIndex.value = -1;

        selectedCategoryId.value = null;
        selectedDestinationAccountUuid.value = null;

        Get.back(result: true);
      }
      // ================= UNAUTHORIZED =================
      else if (response.statusCode == 401) {
        // Get.snackbar(
        //   'Session Expired',
        //   'Please login again',
        //   snackPosition: SnackPosition.BOTTOM,
        // );
      }
      // ================= ERROR =================
      else {
        if (response.statusCode == 400 || response.statusCode == 422) {
          _pendingIncomeIdempotencyKey = null;
          _pendingIncomeRequestBody = null;
        }
        final message = data['message']?.toString() ?? 'Unable to save income';
        final details = _formatBackendErrors(data['errors']);
        Get.snackbar(
          'Error',
          details.isEmpty ? message : '$message\n$details',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Income] Request failed: ${error.runtimeType}: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      Get.snackbar(
        'Connection Error',
        kDebugMode
            ? 'Request failed: ${error.runtimeType}. See debug console for details.'
            : 'Unable to save income. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSavingIncome.value = false;
    }
  }

  String _formatBackendErrors(dynamic errors) {
    if (errors is Map) {
      return errors.entries
          .map((entry) {
            final value = entry.value;
            final detail = value is List ? value.join(', ') : value.toString();
            return '${entry.key}: $detail';
          })
          .join('\n');
    }
    if (errors is List) {
      return errors
          .map((error) {
            if (error is Map) {
              final field = error['field']?.toString();
              final message = error['message']?.toString();
              if (field != null && message != null) return '$field: $message';
            }
            return error.toString();
          })
          .join('\n');
    }
    return '';
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
    counterpartyController.dispose();

    super.onClose();
  }
}
