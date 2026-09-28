import 'package:budget_book_2026/app/modules/income_expense/controllers/post_expense_controller.dart';
import 'package:get/get.dart';

class PostExpenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostExpenseController>(
      () => PostExpenseController(),
    );
  }
}
