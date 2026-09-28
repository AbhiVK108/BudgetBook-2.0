import 'package:budget_book_2026/app/modules/loan_chitfund/controllers/loans_controller.dart';
import 'package:get/get.dart';

class LoansBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoansController>(() => LoansController());
  }
}
