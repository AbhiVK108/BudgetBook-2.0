import 'package:get/get.dart';

import '../controllers/get_reminder_controller.dart';

class GetReminderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GetReminderController>(
      () => GetReminderController(),
    );
  }
}
