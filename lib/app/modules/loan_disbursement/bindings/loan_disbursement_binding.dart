import 'package:get/get.dart';

import '../controllers/loan_disbursement_controller.dart';

class LoanDisbursementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanDisbursementController>(
      () => LoanDisbursementController(),
    );
  }
}
