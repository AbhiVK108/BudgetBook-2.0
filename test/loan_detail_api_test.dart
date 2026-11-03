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

  test('loads the selected loan by UUID from the v1 API', () async {
    http.Request? receivedRequest;
    final controller = GetLoansController(
      initialLoan: {'uuid': 'loan-detail-uuid'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          receivedRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'uuid': 'loan-detail-uuid',
                'name': 'Home loan',
                'lender_name': 'Jamie Example',
                'loan_type': 'home',
                'principal_amount': '4500.00',
                'sanctioned_amount': '5000.00',
                'annual_interest_rate': '8.5000',
                'tenure_months': 12,
                'first_due_date': '2026-12-05',
                'date_of_disbursement': '2026-11-20',
                'paid_amount': '1000.00',
                'currency': 'INR',
                'reference_code': 'LN-42',
              },
            }),
            200,
          );
        }),
      ),
    );
    controller.loan.addAll({'uuid': 'loan-detail-uuid'});

    await controller.fetchLoan();

    expect(receivedRequest?.method, 'GET');
    expect(
      receivedRequest?.url.toString(),
      '${ApiService.loansUrl}/loan-detail-uuid',
    );
    expect(receivedRequest?.headers['Authorization'], isNotEmpty);
    expect(controller.valueFor(['name']), 'Home loan');
    expect(controller.value('nameOfLender'), 'Jamie Example');
    expect(controller.value('principalAmount'), '4500.00');
    expect(controller.value('sanctionedAmount'), '5000.00');
    expect(controller.value('rateOfInterest'), '8.5000');
    expect(controller.value('loanTerms'), '12');
    expect(controller.value('startEMI'), '2026-12-05');
    expect(controller.value('dateOfDisbursement'), '2026-11-20');
    expect(controller.value('paidAmount'), '1000.00');
    expect(controller.loan['currency'], 'INR');
    expect(controller.loadError.value, isEmpty);
  });

  test('fetches the selected loan repayment schedule by UUID', () async {
    http.Request? receivedRequest;
    final controller = GetLoansController(
      initialLoan: {'uuid': 'loan-detail-uuid'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          receivedRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    'installment_number': 1,
                    'uuid': 'installment-uuid',
                    'due_date': '2026-12-05',
                    'installment_amount': '500.00',
                    'principal_amount': '450.00',
                    'interest_amount': '50.00',
                    'status': 'upcoming',
                  },
                ],
              },
            }),
            200,
          );
        }),
      ),
    );
    controller.loan.addAll({'uuid': 'loan-detail-uuid'});

    await controller.fetchSchedule();

    expect(receivedRequest?.method, 'GET');
    expect(
      receivedRequest?.url.toString(),
      '${ApiService.loansUrl}/loan-detail-uuid/schedule',
    );
    expect(receivedRequest?.headers['Authorization'], isNotEmpty);
    expect(controller.schedule, hasLength(1));
    expect(controller.schedule.single['due_date'], '2026-12-05');
    expect(controller.scheduleError.value, isEmpty);
  });

  testWidgets('shows selected loan details using v1 API fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(
      GetLoansController(
        initialLoan: {
          'uuid': 'loan-detail-uuid',
          'focus_installment_type': 'overdue',
          'focus_installment': {
            'amount_due': '450.00',
            'due_date': '2026-10-01',
            'days_overdue': 26,
          },
        },
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((request) async {
            if (request.url.path.endsWith('/schedule')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'items': [
                      {
                        'uuid': 'installment-uuid',
                        'installment_number': 1,
                        'due_date': '2026-12-05',
                        'installment_amount': '500.00',
                        'principal_amount': '450.00',
                        'interest_amount': '50.00',
                        'status': 'upcoming',
                      },
                    ],
                  },
                }),
                200,
              );
            }
            if (request.url.path.endsWith('/payments')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'items': [],
                    'pagination': {
                      'current_page': 1,
                      'last_page': 1,
                      'total': 0,
                    },
                  },
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'uuid': 'loan-detail-uuid',
                  'name': 'Home loan',
                  'lender_name': 'Jamie Example',
                  'loan_type': 'home',
                  'principal_amount': '4500.00',
                  'sanctioned_amount': '5000.00',
                  'annual_interest_rate': '8.5000',
                  'tenure_months': 12,
                  'first_due_date': '2026-12-05',
                  'date_of_disbursement': '2026-11-20',
                  'paid_amount': '1000.00',
                  'due_amount': '3500.00',
                  'loan_status': 'active',
                  'currency': 'INR',
                  'reference_code': 'LN-42',
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
        builder: (_, _) => const GetMaterialApp(home: GetLoansView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loan details'), findsOneWidget);
    expect(find.text('Home loan'), findsOneWidget);
    expect(find.text('Jamie Example'), findsOneWidget);
    expect(find.text('Overdue instalment'), findsOneWidget);
    expect(find.textContaining('Overdue by 26 days'), findsOneWidget);
    expect(find.text('₹450.00'), findsOneWidget);
    expect(find.text('Record EMI Payment'), findsOneWidget);
    final loanDetailsList = find.byType(SingleChildScrollView).first;
    await tester.dragUntilVisible(
      find.text('Principal Prepayment'),
      loanDetailsList,
      const Offset(0, -350),
    );
    expect(find.text('Loan actions'), findsOneWidget);
    expect(find.text('Principal Prepayment'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Repayment schedule'),
      loanDetailsList,
      const Offset(0, -350),
    );
    expect(find.text('Pay this installment'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('₹5,000.00'),
      loanDetailsList,
      const Offset(0, -350),
    );
    expect(find.text('₹4,500.00'), findsAtLeastNWidgets(1));
    expect(find.text('₹5,000.00'), findsAtLeastNWidgets(1));
    expect(find.textContaining('8.5000% p.a.'), findsOneWidget);
    expect(find.textContaining('12 months'), findsOneWidget);
    expect(find.textContaining('2026-12-05'), findsAtLeastNWidgets(1));
    expect(find.text('2026-11-20'), findsOneWidget);
    expect(find.text('₹1,000.00'), findsOneWidget);
    for (
      var attempt = 0;
      attempt < 4 && find.text('Additional backend details').evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(loanDetailsList, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('INR'), findsOneWidget);
    expect(find.text('Reference code'), findsOneWidget);
    expect(find.text('LN-42'), findsOneWidget);
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
