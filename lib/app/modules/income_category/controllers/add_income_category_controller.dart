import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/income_category_service.dart';

class AddIncomeCategoryController extends GetxController {
  AddIncomeCategoryController(this.categoryService);

  final IncomeCategoryService categoryService;
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
    } on IncomeCategoryCreationException catch (error) {
      errorMessage.value = error.message;
      return null;
    } catch (error) {
      debugPrint('ADD INCOME CATEGORY ERROR: $error');
      errorMessage.value = 'Unable to create the category. Please try again.';
      return null;
    } finally {
      isCreating.value = false;
    }
  }
}
