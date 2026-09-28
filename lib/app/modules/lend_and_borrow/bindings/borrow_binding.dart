import 'package:budget_book_2026/app/modules/lend_and_borrow/controllers/borrow_controller.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';

class BorrowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BorrowController>(() => BorrowController());
  }
}