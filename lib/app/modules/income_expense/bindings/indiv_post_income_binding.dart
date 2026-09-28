import 'package:budget_book_2026/app/modules/income_expense/controllers/indiv_post_income_controller.dart';
import 'package:get/get.dart';

class IndivPostIncomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IndivPostIncomeController>(
      () => IndivPostIncomeController(),
    );
  }
}
