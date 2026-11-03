import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/bank_account/controllers/account_transactions_controller.dart';
import 'package:budget_book_2026/app/modules/bank_account/controllers/bank_accounts_controller.dart';
import 'package:budget_book_2026/app/modules/bank_account/views/account_transactions_view.dart';
import 'package:budget_book_2026/app/modules/bank_account/bindings/account_transactions_binding.dart';
import 'package:budget_book_2026/app/modules/bank_account/views/bank_accounts_view.dart';
import 'package:budget_book_2026/app/modules/bank_account/controllers/transfers_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads authenticated account transactions page by page', () async {
    final requests = <http.Request>[];
    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        requests.add(request);
        final page = request.url.queryParameters['page'];
        return http.Response(
          jsonEncode(_pageResponse(page == '1' ? 1 : 2)),
          200,
        );
      }),
    );
    final controller = AccountTransactionsController(
      account: _account,
      apiService: apiService,
    );

    await controller.fetchTransactions();

    expect(requests.first.method, 'GET');
    expect(
      requests.first.url.toString(),
      '${ApiService.accountsUrl}/account-uuid/transactions?page=1&per_page=20',
    );
    expect(requests.first.headers['Authorization'], isNotEmpty);
    expect(controller.transactions, hasLength(1));
    expect(controller.transactions.single.description, 'Opening balance');
    expect(controller.transactions.single.isCreditFor('account-uuid'), isTrue);
    expect(controller.total.value, 2);
    expect(controller.hasMore, isTrue);

    await controller.loadNextPage();

    expect(requests.last.url.queryParameters, {'page': '2', 'per_page': '20'});
    expect(controller.transactions, hasLength(2));
    expect(controller.currentPage.value, 2);
    expect(controller.hasMore, isFalse);
    expect(controller.errorMessage.value, isEmpty);
    expect(controller.loadMoreError.value, isEmpty);
  });

  testWidgets('renders account history and transaction details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var requestCount = 0;
    final controller = AccountTransactionsController(
      account: _account,
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((_) async {
          requestCount++;
          return http.Response(jsonEncode(_pageResponse(1, lastPage: 1)), 200);
        }),
      ),
    );
    Get.put<AccountTransactionsController>(controller);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) =>
            const GetMaterialApp(home: AccountTransactionsView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account transactions'), findsOneWidget);
    expect(find.text('Primary Bank'), findsOneWidget);
    expect(find.text('Opening balance'), findsOneWidget);
    expect(find.text('+₹30000.00'), findsOneWidget);
    expect(find.text('Posted'), findsOneWidget);
    expect(requestCount, 1);
    expect(tester.takeException(), isNull);

    Get.reset();
  });

  testWidgets('opens transaction history from an account card', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        if (request.url.path == Uri.parse(ApiService.accountsUrl).path) {
          return http.Response(jsonEncode(_accountsResponse()), 200);
        }
        return http.Response(jsonEncode(_pageResponse(1, lastPage: 1)), 200);
      }),
    );
    Get.put(BankAccountsController(apiService: apiService));
    Get.put(TransfersController(apiService: apiService));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => GetMaterialApp(
          home: const BankAccountsView(),
          getPages: [
            GetPage(
              name: '/account-transactions',
              page: () => const AccountTransactionsView(),
              binding: AccountTransactionsBinding(apiService: apiService),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Primary Bank'), findsOneWidget);

    await tester.tap(find.text('Primary Bank'));
    await tester.pumpAndSettle();

    expect(find.text('Account transactions'), findsOneWidget);
    expect(find.text('Opening balance'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}

final _account = const BankAccount(
  uuid: 'account-uuid',
  name: 'Primary Bank',
  type: 'bank',
  institution: 'Example Bank',
  currency: 'INR',
  status: 'active',
  createdAt: null,
  balance: '30000.00',
  allowNegative: false,
  notes: null,
);

Map<String, dynamic> _pageResponse(int page, {int lastPage = 2}) => {
  'success': true,
  'status': 200,
  'message': 'Account transactions fetched successfully.',
  'data': {
    'items': [
      {
        'uuid': 'transaction-$page',
        'type': page == 1 ? 'opening_balance' : 'expense',
        'amount': page == 1 ? '30000.00' : '45.50',
        'currency': 'INR',
        'transaction_date': '2026-10-14',
        'description': page == 1 ? 'Opening balance' : 'Groceries',
        'counterparty': null,
        'reference': null,
        'status': 'posted',
        'category_uuid': null,
        'category_name': null,
        'source_account_uuid': null,
        'source_account_name': null,
        'destination_account_uuid': 'account-uuid',
        'destination_account_name': 'Primary Bank',
        'reversed_transaction_uuid': null,
        'reversal_uuid': null,
      },
    ],
    'pagination': {
      'current_page': page,
      'per_page': 20,
      'total': 2,
      'last_page': lastPage,
    },
  },
};

Map<String, dynamic> _accountsResponse() => {
  'success': true,
  'data': {
    'items': [
      {
        'uuid': 'account-uuid',
        'name': 'Primary Bank',
        'type': 'bank',
        'institution': 'Example Bank',
        'currency': 'INR',
        'status': 'active',
        'balance': '30000.00',
      },
    ],
  },
};

class _MemoryCredentialStorage implements AuthCredentialStorage {
  @override
  Future<String?> read(String key) async =>
      key == 'accessToken' ? 'test-access-token' : null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
