import 'package:get/get.dart';

import '../controllers/loan_prepayment_controller.dart';

class LoanPrepaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanPrepaymentController>(() => LoanPrepaymentController());
  }
}
