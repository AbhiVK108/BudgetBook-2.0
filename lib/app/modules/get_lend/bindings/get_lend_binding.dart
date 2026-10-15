import 'package:get/get.dart';

import '../controllers/get_lend_controller.dart';

class GetLendBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GetLendController>(
      () => GetLendController(),
    );
  }
}
