import 'package:get/get.dart';

import '../controllers/get_borrow_controller.dart';

class GetBorrowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GetBorrowController>(
      () => GetBorrowController(),
    );
  }
}
