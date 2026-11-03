import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/postloan/controllers/postloan_controller.dart';
import 'package:budget_book_2026/app/modules/postloan/views/postloan_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('posts a loan with the v1 JSON payload', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <http.Request>[];
    final controller = PostloanController(
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
                      'uuid': 'account-uuid',
                      'name': 'Main account',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (request.url.path == '/api/v1/categories') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'category-uuid',
                      'name': 'Interest',
                      'type': 'expense',
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
              'message': 'Loan created.',
              'data': {'uuid': 'loan-uuid'},
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
        builder: (_, _) => const GetMaterialApp(home: Scaffold()),
      ),
    );
    Get.to(() => PostloanView());
    await tester.pumpAndSettle();

    expect(find.text('Post a loan'), findsOneWidget);
    expect(find.text('First due date'), findsOneWidget);
    expect(find.text('Repayment account'), findsOneWidget);
    expect(find.text('Interest expense category'), findsOneWidget);

    controller.loanNameController.text = 'Postman home loan';
    controller.lenderNameController.text = 'Example lender';
    controller.lenderReferenceController.text = 'PM-LOAN-1';
    controller.sanctionedAmountController.text = '500000';
    controller.principalAmountController.text = '500000';
    controller.annualInterestRateController.text = '8.5';
    controller.tenureMonthsController.text = '12';
    controller.firstDueDate.value = DateTime(2026, 12, 5);
    controller.notesController.text = 'Phase 5 Postman test';
    expect(controller.selectedAccountUuid.value, 'account-uuid');
    expect(controller.selectedExpenseCategoryUuid.value, 'category-uuid');

    expect(await controller.postLoan(), isTrue);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    final request = requests.last;
    expect(request.method, 'POST');
    expect(request.url.toString(), ApiService.loansUrl);
    expect(request.headers['Content-Type'], 'application/json');
    expect(request.headers['Authorization'], isNotEmpty);
    expect(request.headers['Idempotency-Key'], isNotEmpty);
    expect(
      requests
          .singleWhere((request) => request.url.path == '/api/v1/categories')
          .url
          .queryParameters,
      {'type': 'expense'},
    );
    expect(jsonDecode(request.body), {
      'loan_type': 'home',
      'name': 'Postman home loan',
      'lender_name': 'Example lender',
      'lender_reference': 'PM-LOAN-1',
      'sanctioned_amount': '500000.00',
      'principal_amount': '500000.00',
      'currency': 'INR',
      'annual_interest_rate': '8.5000',
      'tenure_months': 12,
      'first_due_date': '2026-12-05',
      'repayment_account_uuid': 'account-uuid',
      'interest_category_uuid': 'category-uuid',
      'notes': 'Phase 5 Postman test',
    });
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
