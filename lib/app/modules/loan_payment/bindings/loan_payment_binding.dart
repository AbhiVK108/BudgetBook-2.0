import 'package:get/get.dart';

import '../controllers/loan_payment_controller.dart';

class LoanPaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanPaymentController>(() {
      final arguments = Get.arguments;
      final installmentUuid = arguments is Map
          ? arguments['installment_uuid']?.toString()
          : null;
      return LoanPaymentController(initialInstallmentUuid: installmentUuid);
    });
  }
}
