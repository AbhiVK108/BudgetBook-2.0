import 'package:get/get.dart';

import '../controllers/chitfunds_controller.dart';

class ChitfundBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChitfundController>(() => ChitfundController());
  }
}
