import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:get/get.dart';

import '../controllers/account_transactions_controller.dart';
import '../controllers/bank_accounts_controller.dart';

class AccountTransactionsBinding extends Bindings {
  AccountTransactionsBinding({this.apiService});

  final ApiService? apiService;

  @override
  void dependencies() {
    final account = Get.arguments;
    BankAccount resolvedAccount;
    if (account is BankAccount) {
      resolvedAccount = account;
    } else if (account is String && account.trim().isNotEmpty) {
      resolvedAccount = _accountPlaceholder(account.trim());
    } else if (account is Map &&
        account['uuid']?.toString().trim().isNotEmpty == true) {
      resolvedAccount = _accountPlaceholder(account['uuid'].toString().trim());
    } else {
      throw ArgumentError('An account is required to load its transactions.');
    }
    Get.lazyPut<AccountTransactionsController>(
      () => AccountTransactionsController(
        account: resolvedAccount,
        apiService: apiService,
      ),
    );
  }

  BankAccount _accountPlaceholder(String uuid) => BankAccount(
    uuid: uuid,
    name: 'Account transactions',
    type: 'account',
    institution: null,
    currency: 'INR',
    status: 'active',
    createdAt: null,
    balance: '0.00',
    allowNegative: false,
    notes: null,
  );
}
