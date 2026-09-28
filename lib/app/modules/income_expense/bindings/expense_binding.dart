import 'package:budget_book_2026/app/modules/income_expense/controllers/expense_controller.dart';
import 'package:get/get.dart';

class ExpenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExpenseController>(
      () => ExpenseController(),
    );
  }
}
