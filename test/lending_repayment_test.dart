import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/lending_repayment/controllers/lending_repayment_controller.dart';
import 'package:budget_book_2026/app/modules/lending_repayment/views/lending_repayment_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retries lending POSTs with the same idempotency key', () async {
    final requests = <http.Request>[];
    final attemptsByUrl = <String, int>{};
    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        requests.add(request);
        final url = request.url.toString();
        final attempt = (attemptsByUrl[url] ?? 0) + 1;
        attemptsByUrl[url] = attempt;
        if (attempt == 1) {
          throw http.ClientException('Connection closed', request.url);
        }
        return http.Response(jsonEncode({'success': true, 'data': {}}), 201);
      }),
    );

    await apiService.postLending({
      'borrower_name': 'Jamie',
    }, idempotencyKey: 'lending-request-key');
    await apiService.postLendingRepayment('lending-uuid', {
      'amount_received': '500.00',
    }, idempotencyKey: 'repayment-request-key');

    expect(requests, hasLength(4));
    expect(requests[0].url, requests[1].url);
    expect(requests[0].headers['Idempotency-Key'], 'lending-request-key');
    expect(requests[1].headers['Idempotency-Key'], 'lending-request-key');
    expect(requests[2].url, requests[3].url);
    expect(requests[2].headers['Idempotency-Key'], 'repayment-request-key');
    expect(requests[3].headers['Idempotency-Key'], 'repayment-request-key');
  });

  testWidgets('submits the repayment contract for the selected lending', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final controller = LendingRepaymentController(
      lending: {'uuid': 'lending-uuid', 'person_name': 'Jamie Example'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/v1/accounts') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'cash-account-uuid',
                      'name': 'Wallet cash',
                      'type': 'cash',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'success': false,
              'status': 422,
              'message': 'Validation failed.',
              'errors': [],
            }),
            422,
          );
        }),
      ),
    );
    addTearDown(controller.onClose);
    Get.testMode = true;
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox())),
    );

    await controller.loadAccounts();
    controller.amountController.text = '500';
    controller.referenceController.text = 'POSTMAN-LEND-REPAYMENT';
    controller.repaymentDate.value = DateTime(2026, 10, 15);

    expect(await controller.submitRepayment(), isFalse);
    final repaymentRequest = requests.last;
    expect(repaymentRequest.method, 'POST');
    expect(
      repaymentRequest.url.toString(),
      '${ApiService.lendingUrl}/lending-uuid/repayments',
    );
    expect(repaymentRequest.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(repaymentRequest.body), {
      'amount_received': '500.00',
      'repayment_date': '2026-10-15',
      'receiving_account_uuid': 'cash-account-uuid',
      'reference': 'POSTMAN-LEND-REPAYMENT',
    });

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    Get.reset();
    Get.reset();
  });

  testWidgets('renders the standalone repayment form', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LendingRepaymentController(
      lending: {
        'uuid': 'lending-uuid',
        'person_name': 'Jamie Example',
        'currency': 'INR',
        'total_outstanding': '550.00',
      },
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'items': []},
            }),
            200,
          );
        }),
      ),
    );
    Get.put(controller);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: LendingRepaymentView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jamie Example'), findsOneWidget);
    expect(find.text('INR 550.00'), findsOneWidget);
    expect(find.text('Repayment details'), findsOneWidget);
    expect(find.text('Amount received'), findsOneWidget);
    expect(find.text('Repayment date'), findsOneWidget);
    expect(find.text('Receiving account'), findsOneWidget);
    expect(find.text('Reference'), findsOneWidget);
    expect(tester.takeException(), isNull);

    Get.reset();
  });

  testWidgets('closes repayment form after successful submission', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LendingRepaymentController(
      lending: {'uuid': 'lending-uuid', 'person_name': 'Jamie Example'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'cash-account-uuid',
                      'name': 'Wallet cash',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Repayment recorded.',
              'data': {
                'agreement': {'amount_received': '500.00'},
              },
            }),
            201,
          );
        }),
      ),
    );
    Get.put(controller);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(
          home: Scaffold(body: Center(child: Text('Lending details'))),
        ),
      ),
    );
    final repaymentRoute = Get.to(() => const LendingRepaymentView());
    await tester.pumpAndSettle();
    controller.amountController.text = '500';

    expect(await controller.submitRepayment(), isTrue);
    await repaymentRoute;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Lending details'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}

class _MemoryCredentialStorage implements AuthCredentialStorage {
  @override
  Future<String?> read(String key) async =>
      key == 'accessToken' ? 'test-access-token' : null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
