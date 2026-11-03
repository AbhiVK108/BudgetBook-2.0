import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/get_loans/controllers/get_loans_controller.dart';
import 'package:budget_book_2026/app/modules/get_loans/views/get_loans_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches authenticated loan payment pages by UUID', () async {
    final requests = <http.Request>[];
    final controller = GetLoansController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(jsonEncode(_paymentsResponse(page)), 200);
        }),
      ),
    );
    controller.loan.addAll({'uuid': 'loan-uuid'});

    await controller.fetchPayments();

    expect(requests.single.method, 'GET');
    expect(requests.single.url.path, '/api/v1/loans/loan-uuid/payments');
    expect(requests.single.url.queryParameters, {
      'page': '1',
      'per_page': '20',
    });
    expect(requests.single.headers['Authorization'], isNotEmpty);
    expect(controller.payments, hasLength(1));
    expect(controller.payments.single['amount_paid'], '450.00');
    expect(controller.currentPaymentPage.value, 1);
    expect(controller.totalPayments.value, 21);
    expect(controller.hasMorePayments, isTrue);

    await controller.loadMorePayments();

    expect(requests.last.url.queryParameters, {'page': '2', 'per_page': '20'});
    expect(controller.payments, hasLength(2));
    expect(controller.payments.last['payment_date'], '2026-10-15');
    expect(controller.currentPaymentPage.value, 2);
    expect(controller.hasMorePayments, isFalse);
    expect(controller.paymentLoadMoreError.value, isEmpty);
  });

  testWidgets('renders loan payment history', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(
      GetLoansController(
        initialLoan: {'uuid': 'loan-uuid', 'name': 'Home loan'},
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((request) async {
            if (request.url.path.endsWith('/payments')) {
              return http.Response(jsonEncode(_paymentsResponse(1)), 200);
            }
            if (request.url.path.endsWith('/schedule')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {'items': []},
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'uuid': 'loan-uuid', 'name': 'Home loan'},
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
        builder: (_, _) => const GetMaterialApp(home: GetLoansView()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Payment history'),
      find.byType(ListView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment history'), findsOneWidget);
    expect(find.text('2026-10-01'), findsOneWidget);
    expect(find.text('Main account'), findsOneWidget);
    expect(find.text('₹450.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}

Map<String, dynamic> _paymentsResponse(int page) => {
  'success': true,
  'message': 'Loan payments fetched successfully.',
  'data': {
    'items': [
      {
        'uuid': 'payment-$page',
        'amount_paid': page == 1 ? '450.00' : '460.00',
        'payment_date': page == 1 ? '2026-10-01' : '2026-10-15',
        'payment_account_name': 'Main account',
        'reference': 'Receipt $page',
      },
    ],
    'pagination': {
      'current_page': page,
      'per_page': 20,
      'total': 21,
      'last_page': 2,
    },
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
