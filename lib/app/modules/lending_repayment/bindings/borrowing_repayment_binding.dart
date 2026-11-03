import 'package:get/get.dart';

import '../controllers/lending_repayment_controller.dart';

class BorrowingRepaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LendingRepaymentController>(
      () => LendingRepaymentController(isBorrowing: true),
    );
  }
}
