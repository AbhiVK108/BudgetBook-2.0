import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/api_services.dart';

class BudgetSpendingController extends GetxController {
  BudgetSpendingController({required this.budgetUuid, ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final String budgetUuid;
  final ApiService apiService;
  final budget = <String, dynamic>{}.obs;
  final spending = <Map<String, dynamic>>[].obs;
  final categories = <Map<String, dynamic>>[].obs;
  final expenseCategories = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isAddingCategory = false.obs;
  final errorMessage = ''.obs;
  final isSavingsMode = false.obs;
  final isCreatingSavingsGoal = false.obs;
  final savingsGoals = <Map<String, dynamic>>[].obs;
  final isLoadingSavingsGoals = false.obs;
  final isAddingSavingsContribution = false.obs;
  final savingsGoalSummaries = <String, Map<String, dynamic>>{}.obs;
  final savingsSummary = <String, dynamic>{}.obs;

  @override
  void onReady() {
    super.onReady();
    _loadBudgetSpending();
    fetchSavingsGoals();
  }

  Future<void> _loadBudgetSpending() async {
    if (budgetUuid.trim().isNotEmpty) {
      await fetchSpending();
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await apiService.getBudgets();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          'Unable to load budgets (${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      final rawData = decoded is Map
          ? (decoded['data'] ?? decoded['budgets'] ?? decoded)
          : decoded;
      final budgets = _listFrom(rawData, const ['items', 'budgets', 'data']);
      if (budgets.isEmpty) {
        throw const FormatException('No budgets found. Create a budget first.');
      }
      final first = budgets.first;
      final uuid = (first['uuid'] ?? first['budget_uuid'] ?? first['id'])
          ?.toString();
      if (uuid == null || uuid.isEmpty) {
        throw const FormatException(
          'The budget response did not include an id.',
        );
      }
      budget.assignAll(first);
      await fetchBudgetSummary(uuid);
    } catch (error, stackTrace) {
      errorMessage.value = error is FormatException
          ? error.message
          : 'Unable to load budget spending.';
      debugPrint('Unable to find a budget: $error\n$stackTrace');
      isLoading.value = false;
    }
  }

  Future<void> reloadBudget() => _loadBudgetSpending();

  Future<bool> createSavingsGoal({
    required String name,
    required String targetAmount,
    required String description,
  }) async {
    final requestBody = {
      'name': name.trim(),
      'currency': 'INR',
      'target_amount': targetAmount.trim(),
      'description': description.trim(),
    };
    isCreatingSavingsGoal.value = true;
    try {
      final response = await apiService.postSavingsGoal(
        requestBody,
        idempotencyKey: ApiService.createIdempotencyKey(),
      );
      debugPrint('[SavingsGoal] Status code: ${response.statusCode}');
      debugPrint('[SavingsGoal] Response body: ${response.body}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(
            response.body,
            fallback: 'Unable to create savings goal (${response.statusCode}).',
          ),
        );
      }
      Get.snackbar('Savings goal created', name.trim());
      await fetchSavingsGoals();
      return true;
    } catch (error) {
      Get.snackbar(
        'Savings goal not created',
        error is FormatException ? error.message : 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isCreatingSavingsGoal.value = false;
    }
  }

  Future<void> fetchSavingsGoals() async {
    if (isLoadingSavingsGoals.value) return;
    isLoadingSavingsGoals.value = true;
    try {
      await fetchSavingsGoalsSummary();
      final response = await apiService.getSavingsGoals();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(
            response.body,
            fallback: 'Unable to load savings goals (${response.statusCode}).',
          ),
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid savings goals response.');
      }
      final rawData =
          decoded['data'] ?? decoded['savings_goals'] ?? decoded['goals'];
      savingsGoals.assignAll(
        _listFrom(rawData, const ['items', 'savings_goals', 'goals', 'data']),
      );
      savingsGoalSummaries.clear();
      await Future.wait(
        savingsGoals
            .map(
              (goal) =>
                  (goal['uuid'] ?? goal['savings_goal_uuid'] ?? goal['id'])
                      ?.toString()
                      .trim(),
            )
            .whereType<String>()
            .where((uuid) => uuid.isNotEmpty)
            .map(fetchSavingsGoalSummary),
      );
    } catch (error) {
      Get.snackbar(
        'Savings goals unavailable',
        error is FormatException ? error.message : 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingSavingsGoals.value = false;
    }
  }

  Future<void> fetchSavingsGoalsSummary() async {
    try {
      final response = await apiService.getSavingsGoalsSummary();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          'Unable to load savings summary (${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid savings summary response.');
      }
      final data = decoded['data'] ?? decoded['summary'] ?? decoded;
      if (data is Map) {
        savingsSummary.assignAll(Map<String, dynamic>.from(data));
      }
    } catch (error) {
      debugPrint('Unable to load savings summary: $error');
    }
  }

  Future<bool> addSavingsGoalContribution({
    required String savingsGoalUuid,
    required String amount,
    required String notes,
  }) async {
    final parsedAmount = double.tryParse(amount.trim());
    if (savingsGoalUuid.trim().isEmpty ||
        parsedAmount == null ||
        parsedAmount <= 0) {
      Get.snackbar(
        'Check contribution',
        'Select a savings goal and enter a valid amount.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (isAddingSavingsContribution.value) return false;

    isAddingSavingsContribution.value = true;
    try {
      final response = await apiService.postSavingsGoalContribution(
        savingsGoalUuid.trim(),
        {'amount': parsedAmount.toStringAsFixed(2), 'notes': notes.trim()},
        idempotencyKey: ApiService.createIdempotencyKey(),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(
            response.body,
            fallback: 'Unable to add contribution (${response.statusCode}).',
          ),
        );
      }
      Get.snackbar(
        'Contribution added',
        '${parsedAmount.toStringAsFixed(2)} was added to the savings goal.',
      );
      await fetchSavingsGoals();
      return true;
    } catch (error) {
      Get.snackbar(
        'Contribution not added',
        error is FormatException ? error.message : 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isAddingSavingsContribution.value = false;
    }
  }

  Future<void> fetchSavingsGoalSummary(String savingsGoalUuid) async {
    final uuid = savingsGoalUuid.trim();
    if (uuid.isEmpty) return;

    try {
      final response = await apiService.getSavingsGoalSummary(uuid);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          'Unable to load savings goal summary (${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid savings goal summary response.');
      }

      final data = decoded['data'] ?? decoded['summary'] ?? decoded;
      if (data is Map) {
        savingsGoalSummaries[uuid] = Map<String, dynamic>.from(data);
      } else {
        throw const FormatException('Savings goal summary data is missing.');
      }
    } catch (error) {
      debugPrint('Unable to load savings goal summary $uuid: $error');
    }
  }

  dynamic savingsGoalSummaryValue(String? uuid, List<String> keys) {
    if (uuid == null) return null;
    final summary = savingsGoalSummaries[uuid.trim()];
    return _nestedValue(summary, keys);
  }

  Future<void> fetchSpending() async {
    await fetchBudgetSummary();
  }

  Future<void> fetchBudgetSummary([String? uuid]) async {
    final budgetUuidValue = (uuid ?? '').trim().isNotEmpty
        ? uuid!.trim()
        : budgetUuid.trim().isNotEmpty
        ? budgetUuid.trim()
        : (budget['uuid'] ?? budget['budget_uuid'])?.toString() ?? '';
    if (budgetUuidValue.trim().isEmpty) {
      errorMessage.value = 'A budget id is required to load the summary.';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await apiService.getBudgetSummary(budgetUuidValue);
      debugPrint('[BudgetSpending] Summary status: ${response.statusCode}');
      debugPrint('[BudgetSpending] Summary body: ${response.body}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          'Unable to load budget summary (${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid budget summary response.');
      }
      _applySummaryResponse(Map<String, dynamic>.from(decoded));
      await loadExpenseCategories();
    } catch (error, stackTrace) {
      errorMessage.value = error is FormatException
          ? error.message
          : 'Unable to load budget summary.';
      debugPrint('Unable to fetch budget spending: $error\n$stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  void _applySummaryResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Budget summary data is missing.');
    }
    final summary = Map<String, dynamic>.from(data);
    final budgetData = summary['budget'];
    if (budgetData is! Map) {
      throw const FormatException('Budget details are missing.');
    }
    budget.assignAll(Map<String, dynamic>.from(budgetData));
    categories.assignAll(_listFrom(summary['categories'], const []));
    spending.clear();
  }

  String get currentBudgetUuid {
    final suppliedUuid = budgetUuid.trim();
    if (suppliedUuid.isNotEmpty) return suppliedUuid;
    return (budget['uuid'] ?? budget['budget_uuid'] ?? budget['id'])
            ?.toString()
            .trim() ??
        '';
  }

  Future<void> loadExpenseCategories() async {
    try {
      final response = await apiService.get(
        '${ApiService.categoriesUrl}?type=expense',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final decoded = jsonDecode(response.body);
      final rawData = decoded is Map ? decoded['data'] : null;
      final data = rawData is List
          ? rawData
          : rawData is Map && rawData['items'] is List
          ? rawData['items'] as List<dynamic>
          : const <dynamic>[];
      expenseCategories.assignAll(
        data.whereType<Map>().map(Map<String, dynamic>.from).where((category) {
          final uuid = (category['uuid'] ?? category['category_uuid'])
              ?.toString()
              .trim();
          final status = category['status']?.toString().toLowerCase();
          return uuid != null &&
              uuid.isNotEmpty &&
              (status == null || status == 'active' || status == '1');
        }).toList(),
      );
    } catch (error) {
      debugPrint('[BudgetSpending] Unable to load expense categories: $error');
    }
  }

  Future<bool> addBudgetCategory({
    required String categoryUuid,
    required String amountLimit,
  }) async {
    final resolvedBudgetUuid = currentBudgetUuid;
    final parsedAmount = double.tryParse(amountLimit.trim());
    if (resolvedBudgetUuid.isEmpty ||
        categoryUuid.trim().isEmpty ||
        parsedAmount == null ||
        parsedAmount <= 0) {
      Get.snackbar(
        'Check category limit',
        'Select a category and enter a valid amount.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (isAddingCategory.value) return false;

    isAddingCategory.value = true;
    try {
      final response = await apiService.postBudgetCategory(resolvedBudgetUuid, {
        'category_uuid': categoryUuid.trim(),
        'amount_limit': parsedAmount.toStringAsFixed(2),
      });
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(_responseMessage(response.body));
      }
      Get.snackbar(
        'Category limit added',
        'The budget category was updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchBudgetSummary(resolvedBudgetUuid);
      return true;
    } catch (error) {
      Get.snackbar(
        'Category limit not added',
        error is FormatException ? error.message : 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isAddingCategory.value = false;
    }
  }

  String _responseMessage(
    String body, {
    String fallback = 'Unable to add category limit.',
  }) {
    if (body.trim().isEmpty) return fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } on FormatException {
      // Use a stable, user-friendly fallback for non-JSON responses.
    }
    return fallback;
  }

  List<Map<String, dynamic>> _listFrom(dynamic value, List<String> mapKeys) {
    dynamic candidate = value;
    if (candidate is Map) {
      var foundNestedValue = false;
      for (final key in mapKeys) {
        final nested = candidate[key];
        if (nested is List || nested is Map) {
          candidate = nested;
          foundNestedValue = true;
          break;
        }
      }
      if (!foundNestedValue) return <Map<String, dynamic>>[];
      if (candidate is Map) return _listFrom(candidate, mapKeys);
    }
    if (candidate is! List) return <Map<String, dynamic>>[];
    return candidate
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  double number(String key, [double fallback = 0]) {
    final value = budget[key];
    return value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? fallback;
  }

  String text(String key, [String fallback = '']) =>
      _nestedText(budget, key) ?? fallback;

  String? _nestedText(dynamic value, String key) {
    if (value is! Map) return null;
    final direct = value[key];
    if (direct != null) return direct.toString();
    for (final nestedKey in const ['budget', 'data', 'item']) {
      final nested = value[nestedKey];
      final result = _nestedText(nested, key);
      if (result != null) return result;
    }
    return null;
  }

  dynamic _nestedValue(dynamic value, List<String> keys) {
    if (value is! Map) return null;

    for (final key in keys) {
      final direct = value[key];
      if (direct != null) return direct;
    }
    for (final nestedKey in const [
      'goal',
      'summary',
      'data',
      'item',
      'savings_goal',
    ]) {
      final nested = _nestedValue(value[nestedKey], keys);
      if (nested != null) return nested;
    }
    return null;
  }

  double get limit =>
      number('overall_limit', number('limit', number('budget_limit')));
  double get spent => number(
    'actual_spending',
    number('spent', number('total_spent', number('amount_spent'))),
  );
  double get remaining => number(
    'remaining_amount',
    number('remaining', number('available', limit - spent)),
  );
  double get percent {
    final percentage = number('percentage_used');
    return percentage > 0 ? (percentage / 100).clamp(0, 1) : 0;
  }
}
