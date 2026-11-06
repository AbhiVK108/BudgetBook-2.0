import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/expense_category_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostExpenseController extends GetxController {
  PostExpenseController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;
  late final ExpenseCategoryService _expenseCategoryService =
      ExpenseCategoryService(apiService: apiService);

  String get categoryUrl => '${ApiService.categoriesUrl}?type=expense';

  // CATEGORIES
  final categories = <Map<String, dynamic>>[].obs;

  final selectedIndex = (-1).obs;
  final selectedCategoryId = RxnString();
  final accounts = <Map<String, dynamic>>[].obs;
  final isLoadingAccounts = false.obs;
  final selectedSourceAccountUuid = RxnString();

  final isLoadingCategories = false.obs;
  final isCreatingCategory = false.obs;
  final isLoading = false.obs;

  // FORM CONTROLLERS
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final counterpartyController = TextEditingController();

  final selectedDate = ''.obs;
  String? _pendingExpenseIdempotencyKey;
  String? _pendingExpenseRequestBody;

  @override
  void onInit() {
    super.onInit();

    selectedDate.value = _formatDate(DateTime.now());
    getExpenseCategories();
    getSourceAccounts();
  }

  // GET ACTIVE EXPENSE CATEGORIES
  Future<void> getExpenseCategories() async {
    try {
      isLoadingCategories.value = true;

      final response = await apiService.get(categoryUrl);

      if (response.statusCode == 401) {
        showError('Session expired. Please login again.');
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        showError('Unable to fetch expense categories.');
        return;
      }

      if (response.body.isEmpty) {
        showError('Empty response from server');
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
        throw const FormatException('Invalid expense categories response.');
      }

      final expenseCategories = data
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .where((category) {
            final type =
                (category['category_type'] ??
                        category['categoryType'] ??
                        category['type'])
                    ?.toString()
                    .trim()
                    .toLowerCase();
            final status = category['status']?.toString().trim().toLowerCase();
            final uuid = (category['uuid'] ?? category['category_uuid'])
                ?.toString()
                .trim();
            return (type == null || type == 'expense') &&
                uuid != null &&
                uuid.isNotEmpty &&
                (status == null || status == '1' || status == 'active');
          })
          .toList();

      categories.assignAll(expenseCategories);

      selectedIndex.value = -1;
      selectedCategoryId.value = null;
    } catch (e) {
      debugPrint('Expense category load failed: ${e.runtimeType}');
      showError('Unable to load expense categories.');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<Map<String, dynamic>?> createExpenseCategory({
    required String name,
    required String icon,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || isCreatingCategory.value) return null;

    isCreatingCategory.value = true;
    try {
      final category = await _expenseCategoryService.create(
        name: trimmedName,
        icon: icon,
      );
      final uuid = category['uuid']?.toString().trim();
      if (uuid == null || uuid.isEmpty) {
        showError('The server did not return a valid category.');
        return null;
      }

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
    } on FormatException {
      showError('The server returned an invalid category response.');
      return null;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[Expense] Category creation failed: ${error.runtimeType}: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      showError('Unable to create expense category. Please try again.');
      return null;
    } finally {
      isCreatingCategory.value = false;
    }
  }

  Future<void> getSourceAccounts() async {
    isLoadingAccounts.value = true;
    try {
      final response = await apiService.getAccounts();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        showError('Unable to fetch bank accounts.');
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
      if (accounts.length == 1) selectSourceAccount(accounts.first);
    } catch (error) {
      debugPrint('Expense account load failed: ${error.runtimeType}');
      showError('Unable to load bank accounts.');
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  void selectSourceAccount(Map<String, dynamic> account) {
    selectedSourceAccountUuid.value =
        (account['uuid'] ?? account['account_uuid'])?.toString();
  }

  // SELECT CATEGORY
  void selectCategory(int index) {
    if (index < 0 || index >= categories.length) return;

    final id = categories[index]['uuid'] ?? categories[index]['category_uuid'];

    if (id == null || id.toString().isEmpty) {
      showError('Invalid expense category.');
      return;
    }

    selectedIndex.value = index;
    selectedCategoryId.value = id.toString();
  }

  // Keep the selected date in the YYYY-MM-DD format expected by the API.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // PARSE API DATE
  DateTime? _parseDate(String date) {
    return DateTime.tryParse(date.trim());
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

  Future<void> saveExpense() async {
    final amountText = amountController.text.trim();
    final description = noteController.text.trim();
    final counterparty = counterpartyController.text.trim();
    final categoryId = selectedCategoryId.value;
    final sourceAccountUuid = selectedSourceAccountUuid.value;

    // VALIDATE AMOUNT
    if (amountText.isEmpty) {
      showError('Please enter an amount');
      return;
    }

    final parsedAmount = double.tryParse(amountText);

    if (parsedAmount == null || !parsedAmount.isFinite || parsedAmount <= 0) {
      showError('Please enter a valid amount');
      return;
    }

    // VALIDATE COUNTERPARTY AND DESCRIPTION
    if (counterparty.isEmpty) {
      showError('Please enter the counterparty.');
      return;
    }

    if (description.isEmpty) {
      showError('Please enter a description');
      return;
    }

    if (categoryId == null || categoryId.isEmpty) {
      showError('Please select an expense category.');
      return;
    }

    if (sourceAccountUuid == null || sourceAccountUuid.isEmpty) {
      showError('Please select a source bank account.');
      return;
    }

    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final parsedDate = _parseDate(selectedDate.value);
      if (parsedDate == null) {
        showError('Please select a valid transaction date.');
        return;
      }

      final requestBody = <String, dynamic>{
        'amount': parsedAmount.toStringAsFixed(2),
        'transaction_date': _formatDate(parsedDate),
        'source_account_uuid': sourceAccountUuid,
        'category_uuid': categoryId,
        'counterparty': counterparty,
        'description': description,
      };
      final encodedRequestBody = jsonEncode(requestBody);
      if (_pendingExpenseIdempotencyKey == null ||
          _pendingExpenseRequestBody != encodedRequestBody) {
        _pendingExpenseIdempotencyKey = ApiService.createIdempotencyKey();
        _pendingExpenseRequestBody = encodedRequestBody;
      }

      if (kDebugMode) {
        debugPrint('[Expense] POST ${ApiService.expenseTransactionsUrl}');
        debugPrint('[Expense] Request body: $encodedRequestBody');
      }

      final response = await apiService.postExpense(
        requestBody,
        idempotencyKey: _pendingExpenseIdempotencyKey!,
      );
      if (kDebugMode) {
        debugPrint('[Expense] HTTP ${response.statusCode}');
        debugPrint('[Expense] Response body: ${response.body}');
      }

      dynamic decoded;
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body);
      }
      final payload = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      final data = payload['data'];
      final transaction = data is Map ? data['transaction'] : null;
      final transactionUuid = transaction is Map
          ? transaction['uuid']?.toString().trim()
          : null;
      final transactionType = transaction is Map
          ? transaction['type']?.toString().trim().toLowerCase()
          : null;
      final confirmedSuccess =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['success'] == true &&
          transactionUuid != null &&
          transactionUuid.isNotEmpty &&
          transactionType == 'expense';

      if (confirmedSuccess) {
        _pendingExpenseIdempotencyKey = null;
        _pendingExpenseRequestBody = null;
        Get.snackbar(
          'Success',
          payload['message']?.toString() ??
              'Expense transaction created successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        amountController.clear();
        noteController.clear();
        counterpartyController.clear();

        selectedIndex.value = -1;
        selectedCategoryId.value = null;
        selectedSourceAccountUuid.value = null;
        selectedDate.value = _formatDate(DateTime.now());

        _closePostExpensePage();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        showError(
          'Your session does not allow this action. Please sign in again.',
        );
      } else {
        if (response.statusCode >= 400 && response.statusCode < 500) {
          _pendingExpenseIdempotencyKey = null;
          _pendingExpenseRequestBody = null;
        }
        final message =
            payload['message']?.toString() ??
            payload['error']?.toString() ??
            (response.statusCode >= 200 && response.statusCode < 300
                ? 'The server returned an unexpected expense response.'
                : 'Unable to save expense. Please try again.');
        final details = _formatBackendErrors(payload['errors']);
        showError(details.isEmpty ? message : '$message\n$details');
      }
    } on FormatException {
      showError('The server returned an invalid expense response.');
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Expense] Request failed: ${error.runtimeType}: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      showError('Unable to connect to the server');
    } finally {
      isLoading.value = false;
    }
  }

  void _closePostExpensePage() {
    final context = Get.context;
    final navigator = context == null
        ? null
        : Navigator.maybeOf(context, rootNavigator: true);

    if (navigator != null && navigator.canPop()) {
      navigator.pop(true);
      return;
    }

    Get.back(result: true);
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
    counterpartyController.dispose();
    super.onClose();
  }
}
