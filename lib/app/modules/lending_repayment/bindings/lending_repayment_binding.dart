import 'package:get/get.dart';

import '../controllers/lending_repayment_controller.dart';

class LendingRepaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LendingRepaymentController>(
      () => LendingRepaymentController(),
    );
  }
}
