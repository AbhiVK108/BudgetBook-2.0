import 'package:get/get.dart';

import '../../../core/services/income_category_service.dart';
import '../controllers/add_income_category_controller.dart';

class AddIncomeCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IncomeCategoryService>(() => IncomeCategoryService());
    Get.lazyPut<AddIncomeCategoryController>(
      () => AddIncomeCategoryController(Get.find<IncomeCategoryService>()),
    );
  }
}
