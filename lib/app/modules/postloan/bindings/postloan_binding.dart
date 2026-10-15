import 'package:get/get.dart';

import '../controllers/postloan_controller.dart';

class PostloanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostloanController>(
      () => PostloanController(),
    );
  }
}
