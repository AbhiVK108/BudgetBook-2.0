
import 'dart:convert';
import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpenseController extends GetxController {
  // ================= API SERVICE =================

  final ApiService apiService = ApiService();

  final String baseUrl =
      'https://budgetbook.in/api/api/expense';

  // ================= OBSERVABLE VARIABLES =================

  final isLoading = false.obs;
  final isDeleting = false.obs;

  final expenses = <Map<String, dynamic>>[].obs;

  final selectedMonth = DateTime.now().obs;

  // ================= INITIALIZATION =================

  @override
  void onInit() {
    super.onInit();
    getExpenses();
  }

  // ================= GET EXPENSES =================

  Future<void> getExpenses() async {
    try {
      isLoading.value = true;

      final response = await apiService.get(baseUrl);

      debugPrint('EXPENSE STATUS: ${response.statusCode}');
      debugPrint('EXPENSE RESPONSE: ${response.body}');

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
          'Unable to load expenses',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (response.body.isEmpty) {
        expenses.clear();
        return;
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> records = [];

      if (decoded is List) {
        records = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is List) {
          records = decoded['data'];
        } else if (decoded['data'] is Map &&
            decoded['data']['data'] is List) {
          records = decoded['data']['data'];
        } else if (decoded['expenses'] is List) {
          records = decoded['expenses'];
        }
      }

      expenses.assignAll(
        records
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList(),
      );

      debugPrint('EXPENSES LOADED: ${expenses.length}');
    } catch (e) {
      debugPrint('GET EXPENSE ERROR: $e');

      Get.snackbar(
        'Error',
        'Failed to load expenses',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= FILTER EXPENSES BY MONTH =================

  List<Map<String, dynamic>> get filteredExpenses {
    return expenses.where((expense) {
      final dateValue =
          expense['expenseDate'] ??
          expense['expense_date'] ??
          expense['date'] ??
          expense['created_at'];

      if (dateValue == null) return false;

      final date = _parseExpenseDate(dateValue.toString());

      if (date == null) return false;

      return date.year == selectedMonth.value.year &&
          date.month == selectedMonth.value.month;
    }).toList();
  }

  // ================= MONTHLY TOTAL =================

  double get filteredTotalExpense {
    return filteredExpenses.fold<double>(
      0.0,
      (total, expense) {
        final amount = double.tryParse(
              expense['amount']?.toString() ?? '0',
            ) ??
            0.0;

        return total + amount;
      },
    );
  }

  // ================= DATE PARSER =================

  DateTime? _parseExpenseDate(String value) {
    try {
      final parsed = DateTime.tryParse(value);

      if (parsed != null) return parsed;

      // Supports dd-MM-yyyy
      final parts = value.split('-');

      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      debugPrint('DATE PARSE ERROR: $e');
    }

    return null;
  }

  // ================= EDIT EXPENSE =================

  Future<void> editExpense({
    required dynamic expenseId,
    required double amount,
    required String description,
    required String category,
    required String date,
  }) async {
    try {
      isLoading.value = true;

      final updateUrl = '$baseUrl/$expenseId';

      final body = {
        'amount': amount,
        'description': description,
        'category': category,
        'date': date,
      };

      debugPrint('UPDATE URL: $updateUrl');
      debugPrint('UPDATE BODY: ${jsonEncode(body)}');

      final response = await apiService.put(
        updateUrl,
        body,
      );

      debugPrint('UPDATE STATUS: ${response.statusCode}');
      debugPrint('UPDATE RESPONSE: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        Get.snackbar(
          'Success',
          'Expense updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );

        await getExpenses();
      } else if (response.statusCode == 401) {
        Get.snackbar(
          'Session Expired',
          'Please login again',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Unable to update expense',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('UPDATE EXPENSE ERROR: $e');

      Get.snackbar(
        'Error',
        'Failed to update expense',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= DELETE EXPENSE =================

  Future<void> deleteExpense(dynamic expenseId) async {
    try {
      isDeleting.value = true;

      final deleteUrl = '$baseUrl/$expenseId';

      debugPrint('DELETE URL: $deleteUrl');

      final response = await apiService.delete(deleteUrl);

      debugPrint('DELETE STATUS: ${response.statusCode}');
      debugPrint('DELETE RESPONSE: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        Get.snackbar(
          'Success',
          'Expense deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );

        await getExpenses();
      } else if (response.statusCode == 401) {
        Get.snackbar(
          'Session Expired',
          'Please login again',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Unable to delete expense',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('DELETE EXPENSE ERROR: $e');

      Get.snackbar(
        'Error',
        'Failed to delete expense',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDeleting.value = false;
    }
  }

  // ================= DELETE CONFIRMATION =================

  void confirmDelete(dynamic expenseId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteExpense(expenseId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ================= PREVIOUS MONTH =================

  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
  }

  // ================= NEXT MONTH =================

  void nextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
  }
}

