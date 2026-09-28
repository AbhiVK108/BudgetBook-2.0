import 'package:budget_book_2026/app/modules/income_expense/controllers/post_income_controller.dart';
import 'package:get/get.dart';

class PostIncomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostIncomeController>(
      () => PostIncomeController(),
    );
  }
}
