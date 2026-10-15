import 'package:get/get.dart';

import '../controllers/postborrow_controller.dart';

class PostborrowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostborrowController>(
      () => PostborrowController(),
    );
  }
}
