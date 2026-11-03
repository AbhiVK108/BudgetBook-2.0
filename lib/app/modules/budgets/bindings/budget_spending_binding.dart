import 'package:get/get.dart';

import '../controllers/budget_spending_controller.dart';

class BudgetSpendingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BudgetSpendingController>(() {
      final arguments = Get.arguments;
      final uuid =
          Get.parameters['budgetUuid'] ??
          (arguments is Map ? arguments['budgetUuid']?.toString() : null) ??
          (arguments is String ? arguments : '');
      return BudgetSpendingController(budgetUuid: uuid);
    });
  }
}
