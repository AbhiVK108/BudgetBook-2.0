import 'package:get/get.dart';

import '../controllers/get_chitfunds_controller.dart';

class GetChitfundsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GetChitfundsController>(
      () => GetChitfundsController(),
    );
  }
}
