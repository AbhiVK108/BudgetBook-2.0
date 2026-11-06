import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/api_services.dart';

class IncomeCategoryCreationException implements Exception {
  IncomeCategoryCreationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class IncomeCategoryService {
  IncomeCategoryService({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;

  Future<Map<String, dynamic>> create({
    required String name,
    required String icon,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw IncomeCategoryCreationException('Enter a category name.');
    }

    try {
      final response = await apiService.postCategory({
        'name': trimmedName,
        'type': 'income',
        'icon': icon,
        'sort_order': 100,
      });

      final body = jsonDecode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          body is! Map ||
          body['success'] != true ||
          body['data'] is! Map) {
        throw IncomeCategoryCreationException(
          response.statusCode == 401
              ? 'Your session has expired. Please sign in again.'
              : 'Unable to create the income category. Please try again.',
        );
      }

      final category = Map<String, dynamic>.from(body['data'] as Map);
      final uuid = category['uuid'] ?? category['category_uuid'];
      final categoryName =
          category['name'] ??
          category['category_name'] ??
          category['categoryName'];

      if (uuid == null || uuid.toString().trim().isEmpty) {
        throw IncomeCategoryCreationException(
          'The category was created but its details were incomplete.',
        );
      }

      category['uuid'] ??= category['category_uuid'];
      category['name'] ??= categoryName;
      return category;
    } on IncomeCategoryCreationException {
      rethrow;
    } catch (error) {
      debugPrint('INCOME CATEGORY CREATE ERROR: $error');
      throw IncomeCategoryCreationException(
        'Unable to create the category. Check your connection and try again.',
      );
    }
  }
}
