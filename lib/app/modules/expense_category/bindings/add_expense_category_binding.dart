import 'package:get/get.dart';

import '../../../core/services/expense_category_service.dart';
import '../controllers/add_expense_category_controller.dart';

class AddExpenseCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExpenseCategoryService>(() => ExpenseCategoryService());
    Get.lazyPut<AddExpenseCategoryController>(
      () => AddExpenseCategoryController(Get.find<ExpenseCategoryService>()),
    );
  }
}
