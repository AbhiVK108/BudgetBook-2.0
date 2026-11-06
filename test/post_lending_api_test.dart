import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/post_lend/controllers/post_lend_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:budget_book_2026/app/modules/post_lend/views/post_lend_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates lending with the v1 payload and selected entities', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final controller = PostLendController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET' &&
              request.url.path.endsWith('/categories')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'income-category-uuid',
                      'name': 'Interest income',
                      'type': 'income',
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
              request.url.toString() == ApiService.lendingUrl) {
            return http.Response(
              jsonEncode({
                'success': true,
                'status': 201,
                'message': 'Lending record created successfully.',
                'data': {'uuid': 'lending-uuid'},
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
          return const GetMaterialApp(
            home: Scaffold(body: Center(child: Text('Lending list'))),
          );
        },
      ),
    );
    final postRoute = Get.to(() => const PostLendView());
    expect(postRoute, isNotNull);
    await tester.pumpAndSettle();
    expect(find.text('Borrower name'), findsOneWidget);
    expect(find.text('Interest income category'), findsOneWidget);
    expect(find.text('Source account'), findsOneWidget);

    controller.personController.text = 'Jamie Example';
    controller.amountController.text = '1000';
    controller.interestController.text = '50';
    controller.giveDate.value = DateTime(2026, 10, 1);
    controller.returnDate.value = DateTime(2026, 12, 1);
    controller.selectedInterestCategoryUuid.value = 'income-category-uuid';
    controller.selectedSourceAccountUuid.value = 'bank-account-uuid';
    controller.descriptionController.text = 'Phase 4 test';

    await controller.postLend();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final request = requests.singleWhere((item) => item.method == 'POST');
    expect(request.url.toString(), ApiService.lendingUrl);
    expect(request.headers['Authorization'], isNotEmpty);
    expect(request.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(request.body), {
      'borrower_name': 'Jamie Example',
      'principal_amount': '1000.00',
      'lending_date': '2026-10-01',
      'interest_method': 'fixed',
      'fixed_interest_amount': '50.00',
      'interest_category_uuid': 'income-category-uuid',
      'expected_repayment_date': '2026-12-01',
      'source_account_uuid': 'bank-account-uuid',
      'notes': 'Phase 4 test',
    });

    expect(find.text('Lending list'), findsOneWidget);
    Get.closeAllSnackbars();
    await tester.pump(const Duration(seconds: 5));
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
