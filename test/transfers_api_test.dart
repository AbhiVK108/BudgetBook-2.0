import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/bank_account/controllers/bank_accounts_controller.dart';
import 'package:budget_book_2026/app/modules/bank_account/controllers/transfers_controller.dart';
import 'package:budget_book_2026/app/modules/bank_account/views/transfers_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads authenticated transfers with pagination', () async {
    final requests = <http.Request>[];
    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        requests.add(request);
        final page = int.parse(request.url.queryParameters['page']!);
        return http.Response(jsonEncode(_transferResponse(page)), 200);
      }),
    );
    final controller = TransfersController(apiService: apiService);

    await controller.fetchTransfers();

    expect(requests.first.method, 'GET');
    expect(
      requests.first.url.toString(),
      '${ApiService.transfersUrl}?page=1&per_page=20',
    );
    expect(requests.first.headers['Authorization'], isNotEmpty);
    expect(controller.transfers, hasLength(1));
    expect(controller.transfers.first.description, 'Postman test transfer');
    expect(controller.transfers.first.sourceAccountName, 'Postman Test Bank');
    expect(
      controller.transfers.first.destinationAccountName,
      'Postman Test Cash',
    );
    expect(controller.total.value, 2);
    expect(controller.hasMore, isTrue);

    await controller.loadNextPage();

    expect(requests.last.url.queryParameters, {'page': '2', 'per_page': '20'});
    expect(controller.transfers, hasLength(2));
    expect(controller.currentPage.value, 2);
    expect(controller.hasMore, isFalse);
    expect(controller.errorMessage.value, isEmpty);
  });

  test('creates transfer with authenticated idempotent POST payload', () async {
    final requests = <http.Request>[];
    var postAttempts = 0;
    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          postAttempts++;
          if (postAttempts == 1) {
            return http.Response(
              jsonEncode({'success': false, 'message': 'Please retry.'}),
              503,
            );
          }
          return http.Response(jsonEncode(_createTransferResponse()), 201);
        }
        return http.Response(jsonEncode(_transferResponse(1)), 200);
      }),
    );
    final controller = TransfersController(apiService: apiService);
    final date = DateTime(2026, 10, 14);

    final firstAttempt = await controller.createTransfer(
      amount: '5000',
      transactionDate: date,
      sourceAccountUuid: 'bank-uuid',
      destinationAccountUuid: 'cash-uuid',
      description: 'Postman test transfer',
    );
    expect(firstAttempt, isFalse);
    expect(controller.createError.value, 'Please retry.');

    final retry = await controller.createTransfer(
      amount: '5000.00',
      transactionDate: date,
      sourceAccountUuid: 'bank-uuid',
      destinationAccountUuid: 'cash-uuid',
      description: 'Postman test transfer',
    );

    expect(retry, isTrue);
    expect(requests, hasLength(2));
    expect(requests.first.url.toString(), ApiService.transfersUrl);
    expect(requests.first.headers['Authorization'], isNotEmpty);
    expect(requests.first.headers['Idempotency-Key'], isNotEmpty);
    expect(
      requests.last.headers['Idempotency-Key'],
      requests.first.headers['Idempotency-Key'],
    );
    expect(jsonDecode(requests.last.body), {
      'amount': '5000.00',
      'transaction_date': '2026-10-14',
      'source_account_uuid': 'bank-uuid',
      'destination_account_uuid': 'cash-uuid',
      'description': 'Postman test transfer',
    });
    expect(controller.transfers.first.uuid, 'created-transfer-uuid');
    expect(controller.createError.value, isEmpty);
  });

  test(
    'rejects same source and destination without making a request',
    () async {
      var requestCount = 0;
      final controller = TransfersController(
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((_) async {
            requestCount++;
            return http.Response('', 500);
          }),
        ),
      );

      final created = await controller.createTransfer(
        amount: '20.00',
        transactionDate: DateTime(2026, 10, 14),
        sourceAccountUuid: 'same-account',
        destinationAccountUuid: 'same-account',
        description: 'Invalid transfer',
      );

      expect(created, isFalse);
      expect(controller.createError.value, contains('must be different'));
      expect(requestCount, 0);
    },
  );

  testWidgets('shows transfer summary in its own account section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(
      TransfersController(
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((_) async {
            return http.Response(
              jsonEncode(_transferResponse(1, lastPage: 1)),
              200,
            );
          }),
        ),
      ),
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TransfersSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transfers'), findsOneWidget);
    expect(find.text('Postman test transfer'), findsOneWidget);
    expect(find.textContaining('Postman Test Bank'), findsOneWidget);
    expect(find.text('₹5000.00'), findsOneWidget);
    expect(find.text('Posted'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });

  testWidgets('submits a transfer from the Transfers section', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <http.Request>[];
    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(jsonEncode(_createTransferResponse()), 201);
        }
        if (request.url.path == Uri.parse(ApiService.accountsUrl).path) {
          return http.Response(jsonEncode(_accountsResponse()), 200);
        }
        return http.Response(
          jsonEncode(_transferResponse(1, lastPage: 1)),
          200,
        );
      }),
    );
    Get.put(BankAccountsController(apiService: apiService));
    Get.put(TransfersController(apiService: apiService));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TransfersSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New transfer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '125.50');
    await tester.enterText(find.byType(TextFormField).at(1), 'Rent transfer');
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    final post = requests.singleWhere((request) => request.method == 'POST');
    expect(post.url.toString(), ApiService.transfersUrl);
    expect(post.headers['Authorization'], isNotEmpty);
    expect(post.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(post.body), {
      'amount': '125.50',
      'transaction_date': _dateString(DateTime.now()),
      'source_account_uuid': 'bank-uuid',
      'destination_account_uuid': 'cash-uuid',
      'description': 'Rent transfer',
    });
    expect(find.text('New transfer'), findsOneWidget);
    expect(find.text('Postman test transfer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    Get.reset();
  });
}

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Map<String, dynamic> _transferResponse(int page, {int lastPage = 2}) => {
  'success': true,
  'status': 200,
  'message': 'Transfer transactions fetched successfully.',
  'data': {
    'items': [
      {
        'uuid': 'transfer-$page',
        'type': 'transfer',
        'amount': '5000.00',
        'currency': 'INR',
        'transaction_date': '2026-10-14',
        'description': page == 1 ? 'Postman test transfer' : 'Second transfer',
        'counterparty': null,
        'reference': null,
        'status': 'posted',
        'source_account_uuid': 'bank-uuid',
        'source_account_name': 'Postman Test Bank',
        'destination_account_uuid': 'cash-uuid',
        'destination_account_name': 'Postman Test Cash',
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
        'uuid': 'bank-uuid',
        'name': 'Postman Test Bank',
        'type': 'bank',
        'currency': 'INR',
        'status': 'active',
        'balance': '30000.00',
      },
      {
        'uuid': 'cash-uuid',
        'name': 'Postman Test Cash',
        'type': 'cash',
        'currency': 'INR',
        'status': 'active',
        'balance': '0.00',
      },
    ],
  },
};

Map<String, dynamic> _createTransferResponse() => {
  'success': true,
  'status': 201,
  'message': 'Transfer transaction created successfully.',
  'data': {
    'transaction': {
      'uuid': 'created-transfer-uuid',
      'type': 'transfer',
      'amount': '5000.00',
      'currency': 'INR',
      'transaction_date': '2026-10-14',
      'description': 'Postman test transfer',
      'counterparty': null,
      'reference': null,
      'status': 'posted',
      'source_account_uuid': 'bank-uuid',
      'source_account_name': 'Postman Test Bank',
      'destination_account_uuid': 'cash-uuid',
      'destination_account_name': 'Postman Test Cash',
      'reversed_transaction_uuid': null,
      'reversal_uuid': null,
    },
    'idempotent_replay': false,
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
