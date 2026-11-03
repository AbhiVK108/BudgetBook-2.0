import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/lending_repayment/controllers/lending_repayment_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('submits the borrowing repayment contract', (tester) async {
    final requests = <http.Request>[];
    final controller = LendingRepaymentController(
      isBorrowing: true,
      lending: {'uuid': 'borrowing-uuid', 'lender_name': 'Postman lender'},
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
                      'uuid': 'bank-account-uuid',
                      'name': 'Main bank',
                      'type': 'bank',
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
    controller.referenceController.text = 'POSTMAN-BORROW-REPAYMENT';
    controller.repaymentDate.value = DateTime(2026, 10, 15);

    expect(await controller.submitRepayment(), isFalse);
    final repaymentRequest = requests.last;
    expect(repaymentRequest.method, 'POST');
    expect(
      repaymentRequest.url.toString(),
      '${ApiService.borrowingUrl}/borrowing-uuid/repayments',
    );
    expect(repaymentRequest.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(repaymentRequest.body), {
      'amount_paid': '500.00',
      'repayment_date': '2026-10-15',
      'source_account_uuid': 'bank-account-uuid',
      'reference': 'POSTMAN-BORROW-REPAYMENT',
    });

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    Get.reset();
  });

  test(
    'retries borrowing repayment POST with the same idempotency key',
    () async {
      final requests = <http.Request>[];
      var attempts = 0;
      final apiService = ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          attempts++;
          if (attempts == 1) {
            throw http.ClientException('Connection closed', request.url);
          }
          return http.Response(jsonEncode({'success': true}), 201);
        }),
      );

      await apiService.postBorrowingRepayment('borrowing-uuid', {
        'amount_paid': '500.00',
      }, idempotencyKey: 'borrow-repayment-request-key');

      expect(requests, hasLength(2));
      expect(requests[0].url, requests[1].url);
      expect(
        requests[0].headers['Idempotency-Key'],
        'borrow-repayment-request-key',
      );
      expect(
        requests[1].headers['Idempotency-Key'],
        'borrow-repayment-request-key',
      );
    },
  );
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
