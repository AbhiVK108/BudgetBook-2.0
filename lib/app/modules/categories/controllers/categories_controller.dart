import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:budget_book_2026/app/core/constants/api_endpoints.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class CategoriesController extends GetxController {
  // =========================
  // API SERVICE
  // =========================

  final ApiService apiService = ApiService();

  // =========================
  // API URL
  // =========================

  final String categoryUrl = ApiEndpoints.categoriesUrl;

  // =========================
  // STATE
  // =========================

  final isLoading = false.obs;

  // Income = true
  // Expense = false
  final isIncome = true.obs;

  // All categories from API
  final categories = <Map<String, dynamic>>[].obs;

  // =========================
  // INIT
  // =========================

  @override
  void onInit() {
    super.onInit();

    getCategories();
  }

  // =========================
  // TOGGLE INCOME / EXPENSE
  // =========================

  void toggle(bool income) {
    isIncome.value = income;
  }

  // =========================
  // GET CATEGORIES
  // =========================

  Future<void> getCategories() async {
    try {
      isLoading.value = true;

      final response = await apiService.get(categoryUrl);

      debugPrint("Category Status Code: ${response.statusCode}");

      debugPrint("Category Response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check API data
        final dataValue = responseData["data"];
        final data = dataValue is Map ? dataValue["categories"] : dataValue;
        if (data is List) {
          categories.value = List<Map<String, dynamic>>.from(
            data.whereType<Map>().map(Map<String, dynamic>.from),
          );

          debugPrint("Categories Loaded: ${categories.length}");
        } else {
          categories.clear();

          Get.snackbar(
            "Error",
            "No category data found",
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else if (response.statusCode == 401) {
        // Get.snackbar(
        //   "Session Expired",
        //   "Please login again",
        //   snackPosition: SnackPosition.BOTTOM,
        // );
      } else {
        Get.snackbar(
          "Error",
          "Failed to load categories",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint("Category Error: $e");

      Get.snackbar(
        "Error",
        "Unable to load categories",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =========================
  // FILTER INCOME / EXPENSE
  // =========================

  List<Map<String, dynamic>> get filteredCategories {
    final type = isIncome.value ? "income" : "expense";

    return categories
        .where(
          (category) =>
              (category["categoryType"] ??
                      category["category_type"] ??
                      category["type"])
                  ?.toString()
                  .toLowerCase() ==
              type,
        )
        .map(
          (category) => {
            "id": category["id"]?.toString() ?? "",
            "title":
                category["categoryName"] ??
                category["category_name"] ??
                category["name"] ??
                "",
            "amount": "₹ 0",
          },
        )
        .toList();
  }

  // =========================
  // REFRESH
  // =========================

  Future<void> refreshCategories() async {
    await getCategories();
  }

  Future<bool> createCategory({
    required String name,
    required String type,
    String icon = 'category',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || isLoading.value) return false;

    try {
      isLoading.value = true;
      final response = await apiService.postCategory({
        'name': trimmedName,
        'type': type.toLowerCase(),
        'icon': icon,
        'sort_order': 100,
      });
      if (response.statusCode < 200 || response.statusCode >= 300) {
        Get.snackbar(
          'Unable to add category',
          'Please check your connection and try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
      await getCategories();
      Get.snackbar(
        'Category added',
        '$trimmedName is now available.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (_) {
      Get.snackbar(
        'Unable to add category',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
