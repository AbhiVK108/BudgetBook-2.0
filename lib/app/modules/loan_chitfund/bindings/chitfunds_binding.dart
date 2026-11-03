import 'package:get/get.dart';

import '../../get_chitfunds/controllers/get_chitfunds_controller.dart';
import '../controllers/chitfunds_controller.dart';
import '../controllers/loans_controller.dart';

class ChitfundBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChitfundController>(() => ChitfundController());
    Get.lazyPut<GetChitfundsController>(() => GetChitfundsController());
    Get.lazyPut<LoansController>(() => LoansController());
  }
}
