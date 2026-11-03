import 'package:get/get.dart';

import '../controllers/transfers_controller.dart';
import '../controllers/bank_accounts_controller.dart';

class BankAccountsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BankAccountsController>(() => BankAccountsController());
    Get.lazyPut<TransfersController>(
      () => TransfersController(
        apiService: Get.find<BankAccountsController>().apiService,
      ),
    );
  }
}
