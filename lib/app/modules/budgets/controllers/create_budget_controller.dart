import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api_services.dart';

class CreateBudgetController extends GetxController {
  CreateBudgetController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;
  final nameController = TextEditingController(text: 'Monthly Groceries');
  final limitController = TextEditingController(text: '30000.00');
  final notesController = TextEditingController(
    text: 'Standard grocery & household supply allowance for Nov 2026',
  );
  final financialParameterController = TextEditingController(
    text:
        'Keep this monthly budget within the planned spending cap, review essential expenses regularly, '
        'and move any unused balance toward savings at the end of the month.',
  );
  final yearController = TextEditingController(text: '${DateTime.now().year}');
  final monthController = TextEditingController(
    text: '${DateTime.now().month}',
  );
  final isSaving = false.obs;
  final selectedThresholds = <int>[50, 75, 90, 100].obs;

  @override
  void onClose() {
    for (final field in [
      nameController,
      limitController,
      notesController,
      financialParameterController,
      yearController,
      monthController,
    ]) {
      field.dispose();
    }
    super.onClose();
  }

  Future<void> createBudget() async {
    final name = nameController.text.trim();
    final year = int.tryParse(yearController.text.trim());
    final month = int.tryParse(monthController.text.trim());
    final limit = limitController.text.trim();
    final financialParameter = financialParameterController.text.trim();
    if (name.isEmpty ||
        year == null ||
        month == null ||
        month < 1 ||
        month > 12) {
      Get.snackbar('Check your details', 'Enter a name, valid year and month.');
      return;
    }
    if (double.tryParse(limit) == null || double.parse(limit) <= 0) {
      Get.snackbar('Check your details', 'Enter a valid overall limit.');
      return;
    }
    if (financialParameter.length < 120) {
      Get.snackbar(
        'Check your details',
        'Financial parameter must be at least 120 characters.',
      );
      return;
    }
    if (await _hasExistingBudget(year: year, month: month)) {
      await _openExistingBudget();
      return;
    }
    isSaving.value = true;
    try {
      final requestBody = {
        'name': name,
        'year': year,
        'month': month,
        'currency': 'INR',
        'overall_limit': limit,
        'warning_thresholds': selectedThresholds.toList(),
        'notes': notesController.text.trim(),
        'financial': financialParameter,
      };
      debugPrint('[CreateBudget] Request body: ${jsonEncode(requestBody)}');

      final response = await apiService.postBudget(
        requestBody,
        idempotencyKey: ApiService.createIdempotencyKey(),
      );
      debugPrint('[CreateBudget] Status code: ${response.statusCode}');
      debugPrint('[CreateBudget] Headers: ${response.headers}');
      debugPrint('[CreateBudget] Response body: ${response.body}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 409) {
          await _openExistingBudget();
          return;
        }
        throw FormatException(
          _message(response.body) ?? 'Unable to create budget.',
        );
      }

      Get.snackbar('Budget created', 'Your monthly budget is ready.');
      Get.back(result: true);
    } catch (error) {
      Get.snackbar(
        'Budget not created',
        error is FormatException ? error.message : 'Please try again.',
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _openExistingBudget() async {
    Get.snackbar(
      'Budget already exists',
      'Opening the existing budget for this month and currency.',
      snackPosition: SnackPosition.BOTTOM,
    );
    await Future<void>.delayed(Duration.zero);
    Get.back(result: true);
  }

  Future<bool> _hasExistingBudget({
    required int year,
    required int month,
  }) async {
    try {
      final response = await apiService.getBudgets();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[CreateBudget] Existing-budget check failed (${response.statusCode}).',
        );
        return false;
      }
      final decoded = jsonDecode(response.body);
      return _budgetsFrom(decoded).any(
        (budget) =>
            _intValue(budget['year']) == year &&
            _intValue(budget['month']) == month &&
            (budget['currency'] ?? 'INR').toString().toUpperCase() == 'INR',
      );
    } catch (error) {
      debugPrint('[CreateBudget] Existing-budget check failed: $error');
      return false;
    }
  }

  List<Map<String, dynamic>> _budgetsFrom(dynamic decoded) {
    if (decoded is Map) {
      for (final key in const ['data', 'budgets', 'items']) {
        final nested = decoded[key];
        if (nested is List || nested is Map) {
          return _budgetsFrom(nested);
        }
      }
      if (decoded.values.any((value) => value is List)) return const [];
      return [Map<String, dynamic>.from(decoded)];
    }
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((budget) => Map<String, dynamic>.from(budget))
        .toList();
  }

  int? _intValue(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  String? _message(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
