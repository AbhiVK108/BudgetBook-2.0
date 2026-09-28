import 'package:get/get.dart';

import '../controllers/income_expense_controller.dart';

class IncomeExpenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IncomeExpenseController>(
      () => IncomeExpenseController(),
    );
  }
}
