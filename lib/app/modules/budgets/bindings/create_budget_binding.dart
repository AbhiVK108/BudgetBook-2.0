import 'package:get/get.dart';

import '../controllers/create_budget_controller.dart';

class CreateBudgetBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut<CreateBudgetController>(CreateBudgetController.new);
}
