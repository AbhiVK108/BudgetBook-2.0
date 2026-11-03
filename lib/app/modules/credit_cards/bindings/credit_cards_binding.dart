import 'package:get/get.dart';

import '../controllers/credit_cards_controller.dart';

class CreditCardsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreditCardsController>(() => CreditCardsController());
  }
}
