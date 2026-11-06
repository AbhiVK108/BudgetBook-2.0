import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/expense_category_service.dart';

class AddExpenseCategoryController extends GetxController {
  AddExpenseCategoryController(this.categoryService);

  final ExpenseCategoryService categoryService;
  final isCreating = false.obs;
  final errorMessage = ''.obs;

  Future<Map<String, dynamic>?> create({
    required String name,
    required String icon,
  }) async {
    if (isCreating.value) return null;

    isCreating.value = true;
    errorMessage.value = '';
    try {
      final category = await categoryService.create(name: name, icon: icon);
      Get.back(result: category);
      return category;
    } on ExpenseCategoryCreationException catch (error) {
      errorMessage.value = error.message;
      return null;
    } catch (error) {
      debugPrint('ADD EXPENSE CATEGORY ERROR: $error');
      errorMessage.value = 'Unable to create the category. Please try again.';
      return null;
    } finally {
      isCreating.value = false;
    }
  }
}
