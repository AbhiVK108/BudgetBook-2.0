import 'dart:async';
import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/loan_prepayment/controllers/loan_prepayment_controller.dart';
import 'package:budget_book_2026/app/modules/loan_prepayment/views/loan_prepayment_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records a principal prepayment with the v1 payload', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    http.Request? prepaymentRequest;
    final controller = LoanPrepaymentController(
      loan: {'uuid': 'loan-uuid', 'nameOfLender': 'Community Bank'},
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
          prepaymentRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Prepayment recorded.',
              'data': {'uuid': 'prepayment-uuid'},
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
    final prepaymentRoute = Get.to(() => const LoanPrepaymentView());
    await tester.pumpAndSettle();

    expect(find.text('Community Bank'), findsOneWidget);
    expect(
      find.text(
        'Resolve any partial installment before recording a principal prepayment.',
      ),
      findsOneWidget,
    );
    expect(find.text('Source account'), findsOneWidget);
    expect(find.text('Reference'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);

    controller.amountController.text = '1000';
    controller.referenceController.text = 'PM-PREPAY';
    controller.descriptionController.text =
        'Test principal prepayment; use after resolving any partial installment';
    controller.prepaymentDate.value = DateTime(2026, 10, 15);

    await tester.tap(find.text('Record prepayment'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm principal prepayment'), findsOneWidget);
    expect(find.textContaining('Outstanding principal'), findsNothing);
    await tester.tap(find.text('Confirm prepayment'));
    await tester.pumpAndSettle();
    await prepaymentRoute;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(prepaymentRequest?.method, 'POST');
    expect(
      prepaymentRequest?.url.toString(),
      '${ApiService.loansUrl}/loan-uuid/prepayments',
    );
    expect(prepaymentRequest?.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(prepaymentRequest!.body), {
      'amount': '1000.00',
      'payment_date': '2026-10-15',
      'source_account_uuid': 'bank-account-uuid',
      'reference': 'PM-PREPAY',
      'description':
          'Test principal prepayment; use after resolving any partial installment',
    });
    expect(find.text('Loan details'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });

  testWidgets('does not post a non-positive prepayment amount', (tester) async {
    var postCount = 0;
    final controller = LoanPrepaymentController(
      loan: {'uuid': 'loan-uuid'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          postCount++;
          return http.Response(jsonEncode({'success': true}), 201);
        }),
      ),
    );
    controller.amountController.text = '0';
    controller.selectedAccountUuid.value = 'account-uuid';

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox())),
    );
    expect(await controller.submitPrepayment(), isFalse);
    expect(postCount, 0);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    controller.onClose();
    Get.reset();
  });

  testWidgets('prevents a duplicate prepayment while the first is pending', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var postCount = 0;
    final controller = LoanPrepaymentController(
      loan: {'uuid': 'loan-uuid'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'items': []},
              }),
              200,
            );
          }
          postCount++;
          return response.future;
        }),
      ),
    );
    controller.amountController.text = '1000';
    controller.selectedAccountUuid.value = 'account-uuid';
    Get.testMode = true;
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox())),
    );

    final firstSubmission = controller.submitPrepayment();
    await tester.pump();
    expect(controller.isSubmitting.value, isTrue);
    expect(await controller.submitPrepayment(), isFalse);
    expect(postCount, 1);

    response.complete(
      http.Response(
        jsonEncode({'success': false, 'message': 'Temporary server error.'}),
        500,
      ),
    );
    expect(await firstSubmission, isFalse);
    expect(postCount, 1);
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
