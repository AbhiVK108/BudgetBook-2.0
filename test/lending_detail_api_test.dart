import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/get_lend/controllers/get_lend_controller.dart';
import 'package:budget_book_2026/app/modules/get_lend/views/get_lend_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetches selected lending details by UUID', () async {
    http.Request? request;
    final lending = {
      'uuid': 'lending-detail-uuid',
      'person_name': 'Jamie Example',
    };
    final controller = GetLendController(
      initialLend: lending,
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((receivedRequest) async {
          request = receivedRequest;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Lending record fetched successfully.',
              'data': {
                'uuid': 'lending-detail-uuid',
                'person_name': 'Jamie Example',
                'phone': '9876543210',
                'amount': '5000.00',
                'interest': '100.00',
                'transaction_date': '2026-10-01',
                'return_date': '2026-11-01',
                'description': 'Personal lending details',
              },
            }),
            200,
          );
        }),
      ),
    );
    controller.selectedLend.addAll(lending);

    await controller.fetchLends();

    expect(request?.method, 'GET');
    expect(
      request?.url.toString(),
      '${ApiService.lendingUrl}/lending-detail-uuid',
    );
    expect(request?.headers['Authorization'], isNotEmpty);
    expect(controller.personName, 'Jamie Example');
    expect(controller.amountValue, 5000);
    expect(controller.interestValue, 100);
    expect(controller.receiveDate, '2026-10-01');
    expect(controller.returnDate, '2026-11-01');
    expect(controller.description, 'Personal lending details');
    expect(controller.errorMessage.value, isEmpty);
  });

  test(
    'fetches authenticated repayment history for the selected lending',
    () async {
      http.Request? request;
      final controller = GetLendController(
        initialLend: {'uuid': 'lending-detail-uuid'},
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((receivedRequest) async {
            request = receivedRequest;
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Repayment history fetched successfully.',
                'data': {
                  'items': [
                    {
                      'uuid': 'repayment-uuid',
                      'amount_received': '500.00',
                      'repayment_date': '2026-10-15',
                      'receiving_account_name': 'Wallet cash',
                      'reference': 'Receipt 123',
                    },
                  ],
                },
              }),
              200,
            );
          }),
        ),
      );
      controller.selectedLend.addAll({'uuid': 'lending-detail-uuid'});

      await controller.fetchRepayments();

      expect(request?.method, 'GET');
      expect(
        request?.url.toString(),
        '${ApiService.lendingUrl}/lending-detail-uuid/repayments',
      );
      expect(request?.headers['Authorization'], isNotEmpty);
      expect(controller.repayments, hasLength(1));
      expect(controller.repayments.single['amount_received'], '500.00');
      expect(controller.repayments.single['repayment_date'], '2026-10-15');
      expect(controller.repaymentError.value, isEmpty);
    },
  );

  testWidgets('renders repayment history below lending details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(
      GetLendController(
        initialLend: {
          'uuid': 'lending-detail-uuid',
          'person_name': 'Jamie Example',
          'amount': '5000.00',
        },
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((request) async {
            if (request.url.path.endsWith('/repayments')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'items': [
                      {
                        'amount_received': '500.00',
                        'repayment_date': '2026-10-15',
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
                'data': {
                  'uuid': 'lending-detail-uuid',
                  'person_name': 'Jamie Example',
                  'amount': '5000.00',
                },
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
        builder: (_, _) => const GetMaterialApp(home: GetLendView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Repayment history'), findsOneWidget);
    expect(find.text('2026-10-15'), findsOneWidget);
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
