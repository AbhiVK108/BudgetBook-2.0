import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/postborrow/controllers/postborrow_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:budget_book_2026/app/modules/postborrow/views/postborrow_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates borrowing with the v1 payload and selected entities', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final controller = PostborrowController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET' &&
              request.url.path.endsWith('/categories')) {
            expect(request.url.queryParameters['type'], 'expense');
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'expense-category-uuid',
                      'name': 'Interest expense',
                      'type': 'expense',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/accounts')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'bank-account-uuid',
                      'name': 'Everyday account',
                      'type': 'bank',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (request.method == 'POST' &&
              request.url.toString() == ApiService.borrowingUrl) {
            return http.Response(
              jsonEncode({
                'success': true,
                'status': 201,
                'message': 'Borrowing record created successfully.',
                'data': {'uuid': 'borrowing-uuid'},
              }),
              201,
            );
          }
          return http.Response('Unexpected request', 404);
        }),
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) {
          Get.put(controller);
          return const GetMaterialApp(home: PostborrowView());
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lender name'), findsOneWidget);
    expect(find.text('Interest expense category'), findsOneWidget);
    expect(find.text('Receiving account'), findsOneWidget);

    controller.personController.text = 'Postman lender';
    controller.amountController.text = '2000';
    controller.interestController.text = '25';
    controller.receiveDate.value = DateTime(2026, 10, 1);
    controller.returnDate.value = DateTime(2026, 12, 1);
    controller.selectedInterestCategoryUuid.value = 'expense-category-uuid';
    controller.selectedReceivingAccountUuid.value = 'bank-account-uuid';
    controller.descriptionController.text = 'Phase 4 Postman test';

    await controller.postBorrow();

    final request = requests.singleWhere((item) => item.method == 'POST');
    expect(request.url.toString(), ApiService.borrowingUrl);
    expect(request.headers['Authorization'], isNotEmpty);
    expect(request.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(request.body), {
      'lender_name': 'Postman lender',
      'principal_amount': '2000.00',
      'borrowing_date': '2026-10-01',
      'interest_method': 'fixed',
      'fixed_interest_amount': '25.00',
      'interest_category_uuid': 'expense-category-uuid',
      'expected_repayment_date': '2026-12-01',
      'receiving_account_uuid': 'bank-account-uuid',
      'notes': 'Phase 4 Postman test',
    });

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
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
