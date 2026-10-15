import 'package:get/get.dart';

import '../controllers/get_loans_controller.dart';

class GetLoansBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GetLoansController>(
      () => GetLoansController(),
    );
  }
}
