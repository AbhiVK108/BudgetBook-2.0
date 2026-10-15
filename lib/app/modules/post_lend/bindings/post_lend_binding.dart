import 'package:get/get.dart';

import '../controllers/post_lend_controller.dart';

class PostLendBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostLendController>(
      () => PostLendController(),
    );
  }
}
