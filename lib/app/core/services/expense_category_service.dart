import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/api_services.dart';

class ExpenseCategoryCreationException implements Exception {
  ExpenseCategoryCreationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExpenseCategoryService {
  ExpenseCategoryService({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;

  Future<Map<String, dynamic>> create({
    required String name,
    required String icon,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ExpenseCategoryCreationException('Enter a category name.');
    }

    try {
      final response = await apiService.postCategory({
        'name': trimmedName,
        'type': 'expense',
        'icon': icon,
        'sort_order': 100,
      });
      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map) {
        throw ExpenseCategoryCreationException(
          response.statusCode == 401
              ? 'Your session has expired. Please sign in again.'
              : 'Unable to create the expense category. Please try again.',
        );
      }

      final category = Map<String, dynamic>.from(decoded['data'] as Map);
      final uuid = category['uuid'] ?? category['category_uuid'];
      if (uuid == null || uuid.toString().trim().isEmpty) {
        throw ExpenseCategoryCreationException(
          'The category was created but its details were incomplete.',
        );
      }

      category['uuid'] ??= category['category_uuid'];
      category['name'] ??=
          category['category_name'] ?? category['categoryName'];
      return category;
    } on ExpenseCategoryCreationException {
      rethrow;
    } catch (error) {
      debugPrint('EXPENSE CATEGORY CREATE ERROR: $error');
      throw ExpenseCategoryCreationException(
        'Unable to create the category. Check your connection and try again.',
      );
    }
  }
}
