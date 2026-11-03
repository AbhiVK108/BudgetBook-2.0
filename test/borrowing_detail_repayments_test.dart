import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/get_borrow/controllers/get_borrow_controller.dart';
import 'package:budget_book_2026/app/modules/get_borrow/views/get_borrow_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches authenticated repayment history by borrowing UUID', () async {
    http.Request? repaymentRequest;
    final controller = GetBorrowController(
      initialBorrow: {'uuid': 'borrowing-uuid', 'lender_name': 'Jamie'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          repaymentRequest = request;
          return http.Response(jsonEncode(_repaymentsResponse), 200);
        }),
      ),
    );
    controller.selectedBorrow.addAll({
      'uuid': 'borrowing-uuid',
      'lender_name': 'Jamie',
    });

    await controller.fetchRepayments();

    expect(repaymentRequest?.method, 'GET');
    expect(
      repaymentRequest?.url.toString(),
      '${ApiService.borrowingUrl}/borrowing-uuid/repayments',
    );
    expect(repaymentRequest?.headers['Authorization'], isNotEmpty);
    expect(controller.repayments, hasLength(1));
    expect(controller.repayments.single['amount_paid'], '475.00');
    expect(controller.repayments.single['repayment_date'], '2026-10-15');
    expect(controller.repaymentError.value, isEmpty);
  });

  testWidgets('renders borrowing repayment history', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final borrow = {
      'uuid': 'borrowing-uuid',
      'lender_name': 'Jamie Example',
      'principal_amount': '2000.00',
      'fixed_interest_amount': '25.00',
      'borrowing_date': '2026-10-01',
      'expected_repayment_date': '2026-12-01',
      'notes': 'Test borrowing',
    };
    Get.put(
      GetBorrowController(
        initialBorrow: borrow,
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((request) async {
            if (request.url.path.endsWith('/repayments')) {
              return http.Response(jsonEncode(_repaymentsResponse), 200);
            }
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [borrow],
              }),
              200,
            );
          }),
        ),
      ),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: GetBorrowView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Repayment history'), findsOneWidget);
    expect(find.text('2026-10-15'), findsOneWidget);
    expect(find.text('Everyday account'), findsOneWidget);
    expect(find.textContaining('475.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}

final Map<String, dynamic> _repaymentsResponse = {
  'success': true,
  'message': 'Repayment history fetched successfully.',
  'data': {
    'items': [
      {
        'uuid': 'repayment-uuid',
        'amount_paid': '475.00',
        'repayment_date': '2026-10-15',
        'payment_account_name': 'Everyday account',
        'reference': 'Receipt 123',
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
