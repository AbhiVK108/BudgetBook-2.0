
import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IncomeExpenseController extends GetxController {
  final ApiService apiService = ApiService();

  final String baseUrl = 'https://budgetbook.in/api/api/income';

  final count = 0.obs;
  final incomeList = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  // ================= SELECTED MONTH =================

  final selectedMonth = DateTime.now().obs;

  // Previous month
  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
  }

  // Next month
  void nextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
  }

  // ================= SELECTED INCOME DATE =================

  final selectedIncomeDate = DateTime.now().obs;

  // Date format for API: yyyy-MM-dd
  String get formattedIncomeDate {
    final date = selectedIncomeDate.value;

    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  void onInit() {
    super.onInit();
    getIncome();
  }

  // ================= GET INCOME =================

  Future<void> getIncome() async {
    try {
      isLoading.value = true;

      final response = await apiService.get(baseUrl);

      debugPrint('GET INCOME STATUS: ${response.statusCode}');
      debugPrint('GET INCOME RESPONSE: ${response.body}');

      if (response.statusCode == 401) {
        Get.snackbar(
          'Session Expired',
          'Please login again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        Get.snackbar(
          'Error',
          'Unable to get income.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (response.body.isEmpty) {
        incomeList.clear();
        return;
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> records = [];

      if (decoded is List) {
        records = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        records = decoded['data'];
      } else if (decoded is Map && decoded['incomes'] is List) {
        records = decoded['incomes'];
      } else if (decoded is Map &&
          decoded['data'] is Map &&
          decoded['data']['data'] is List) {
        records = decoded['data']['data'];
      } else {
        Get.snackbar(
          'Error',
          'Invalid income data received.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      incomeList.assignAll(
        records
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );

      debugPrint('TOTAL INCOME RECORDS: ${incomeList.length}');
    } catch (e) {
      debugPrint('GET INCOME ERROR: $e');

      Get.snackbar(
        'Error',
        'Something went wrong while loading income.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= PARSE INCOME DATE =================

  DateTime? _parseIncomeDate(Map<String, dynamic> income) {
    final value = income['incomeDate'] ??
        income['incomedate'] ??
        income['income_date'] ??
        income['date'] ??
        income['created_at'];

    if (value == null) return null;

    final dateString = value.toString().trim();

    if (dateString.isEmpty) return null;

    // Supports yyyy-MM-dd and ISO date/time formats.
    final parsedDate = DateTime.tryParse(dateString);

    if (parsedDate != null) {
      return parsedDate;
    }

    // Remove time when the date includes a time portion.
    final dateOnly = dateString.split(' ').first;

    // Supports dd-MM-yyyy.
    final parts = dateOnly.split('-');

    if (parts.length == 3) {
      try {
        if (parts[0].length == 4) {
          // yyyy-MM-dd
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          // dd-MM-yyyy
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // ================= FILTER BY SELECTED MONTH =================

  List<Map<String, dynamic>> get filteredIncome {
    return incomeList.where((income) {
      final date = _parseIncomeDate(income);

      if (date == null) return false;

      return date.year == selectedMonth.value.year &&
          date.month == selectedMonth.value.month;
    }).toList();
  }

  // ================= TOTAL INCOME =================

  // Total for all income records.
  double get totalIncome {
    double total = 0;

    for (final income in incomeList) {
      total += double.tryParse(
            income['amount']?.toString() ?? '0',
          ) ??
          0;
    }

    return total;
  }

  // Total for the selected month only.
  double get filteredTotalIncome {
    double total = 0;

    for (final income in filteredIncome) {
      total += double.tryParse(
            income['amount']?.toString() ?? '0',
          ) ??
          0;
    }

    return total;
  }

  // ================= DATE PICKER =================

  Future<void> pickIncomeDate({String? currentDate}) async {
    DateTime initialDate = selectedIncomeDate.value;

    if (currentDate != null && currentDate.isNotEmpty) {
      final parsedDate = _parseIncomeDate({
        'incomeDate': currentDate,
      });

      if (parsedDate != null) {
        initialDate = parsedDate;
      }
    }

    final pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select income date',
    );

    if (pickedDate != null) {
      selectedIncomeDate.value = pickedDate;
    }
  }

  // Set date when opening an existing income record for editing.
  void setIncomeDate(String? date) {
    if (date == null || date.trim().isEmpty) {
      selectedIncomeDate.value = DateTime.now();
      return;
    }

    final parsedDate = _parseIncomeDate({
      'incomeDate': date,
    });

    if (parsedDate != null) {
      selectedIncomeDate.value = parsedDate;
    } else {
      selectedIncomeDate.value = DateTime.now();
    }
  }

  // ================= EDIT INCOME =================

  Future<void> editIncome({
    required String id,
    required String categoryId,
    required String amount,
    required String incomeDate,
    required String description,
    String receipt = '',
  }) async {
    try {
      if (amount.trim().isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter amount.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isLoading.value = true;

      final response = await apiService.put(
        '$baseUrl/$id',
        {
          'categoryId': categoryId,
          'amount': amount,
          'incomeDate': incomeDate,
          'description': description,
          'receipt': receipt,
        },
      );

      debugPrint('EDIT INCOME STATUS: ${response.statusCode}');
      debugPrint('EDIT INCOME RESPONSE: ${response.body}');

      dynamic data = <String, dynamic>{};

      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        Get.snackbar(
          'Success',
          data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Income updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );

        await getIncome();
      } else if (response.statusCode == 401) {
        Get.snackbar(
          'Session Expired',
          'Please login again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Unable to update income.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('EDIT INCOME ERROR: $e');

      Get.snackbar(
        'Error',
        'Something went wrong while updating income.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= DELETE INCOME =================

  Future<void> deleteIncome(String id) async {
    try {
      isLoading.value = true;

      final response = await apiService.delete('$baseUrl/$id');

      debugPrint('DELETE INCOME STATUS: ${response.statusCode}');
      debugPrint('DELETE INCOME RESPONSE: ${response.body}');

      dynamic data = <String, dynamic>{};

      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        Get.snackbar(
          'Success',
          data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Income deleted successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );

        incomeList.removeWhere(
          (item) => item['id']?.toString() == id,
        );

        await getIncome();
      } else if (response.statusCode == 401) {
        Get.snackbar(
          'Session Expired',
          'Please login again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Unable to delete income.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('DELETE INCOME ERROR: $e');

      Get.snackbar(
        'Error',
        'Something went wrong while deleting income.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= DELETE CONFIRMATION =================

  void confirmDeleteIncome(String id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Income'),
        content: const Text(
          'Are you sure you want to delete this income?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Get.back();
              await deleteIncome(id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ================= REFRESH =================

  Future<void> refreshIncome() async {
    await getIncome();
  }

  void increment() {
    count.value++;
  }
}




