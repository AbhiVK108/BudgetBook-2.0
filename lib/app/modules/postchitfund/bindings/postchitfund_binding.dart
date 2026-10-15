import 'package:get/get.dart';

import '../controllers/postchitfund_controller.dart';

class PostchitfundBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostchitfundController>(
      () => PostchitfundController(),
    );
  }
}
