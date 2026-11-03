import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/loan_disbursement/controllers/loan_disbursement_controller.dart';
import 'package:budget_book_2026/app/modules/loan_disbursement/views/loan_disbursement_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records a loan disbursement with the v1 payload', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    http.Request? disbursementRequest;
    var expenseCategoryQueryCorrect = false;
    final controller = LoanDisbursementController(
      loan: {'uuid': 'loan-uuid', 'nameOfLender': 'Community Bank'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/accounts') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'bank-account-uuid',
                      'name': 'Main account',
                      'type': 'bank',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (request.url.path == '/api/v1/categories') {
            expenseCategoryQueryCorrect =
                request.url.queryParameters['type'] == 'expense';
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'fee-category-uuid',
                      'name': 'Loan charges',
                      'type': 'expense',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          disbursementRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Disbursement recorded.',
              'data': {'uuid': 'disbursement-uuid'},
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
          home: Scaffold(body: Center(child: Text('Loan details'))),
        ),
      ),
    );
    final disbursementRoute = Get.to(() => const LoanDisbursementView());
    await tester.pumpAndSettle();

    expect(find.text('Community Bank'), findsOneWidget);
    expect(find.text('Gross amount'), findsOneWidget);
    expect(find.text('Processing fee'), findsOneWidget);
    expect(find.text('Fee expense category'), findsOneWidget);
    expect(find.text('Receiving account'), findsOneWidget);
    expect(expenseCategoryQueryCorrect, isTrue);

    controller.grossAmountController.text = '500000';
    controller.processingFeeController.text = '5000';
    controller.disbursementDate.value = DateTime(2026, 10, 15);
    expect(await controller.submitDisbursement(), isTrue);
    await disbursementRoute;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(disbursementRequest?.method, 'POST');
    expect(
      disbursementRequest?.url.toString(),
      '${ApiService.loansUrl}/loan-uuid/disbursements',
    );
    expect(disbursementRequest?.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(disbursementRequest!.body), {
      'gross_amount': '500000.00',
      'processing_fee': '5000.00',
      'fee_category_uuid': 'fee-category-uuid',
      'disbursement_date': '2026-10-15',
      'receiving_account_uuid': 'bank-account-uuid',
    });
    expect(find.text('Loan details'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });

  testWidgets('rejects non-positive gross amounts without posting', (
    tester,
  ) async {
    var postCount = 0;
    final controller = LoanDisbursementController(
      loan: {'uuid': 'loan-uuid'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          postCount++;
          return http.Response(jsonEncode({'success': true}), 201);
        }),
      ),
    );
    controller.grossAmountController.text = '0';
    controller.selectedAccountUuid.value = 'account-uuid';
    controller.selectedCategoryUuid.value = 'category-uuid';

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox())),
    );
    expect(await controller.submitDisbursement(), isFalse);
    expect(postCount, 0);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    controller.onClose();
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
