import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/loan_chitfund/controllers/loans_controller.dart';
import 'package:budget_book_2026/app/modules/loan_chitfund/views/loans_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches authenticated upcoming loan installments', () async {
    http.Request? receivedRequest;
    final controller = LoansController(
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
                    'loan_name': 'Home loan',
                    'installment_amount': '500.00',
                    'due_date': '2026-12-05',
                  },
                ],
              },
            }),
            200,
          );
        }),
      ),
    );

    await controller.fetchUpcomingInstallments();

    expect(receivedRequest?.method, 'GET');
    expect(
      receivedRequest?.url.toString(),
      ApiService.upcomingLoanInstallmentsUrl,
    );
    expect(receivedRequest?.headers['Authorization'], isNotEmpty);
    expect(controller.upcomingInstallments, hasLength(1));
    expect(controller.upcomingInstallments.single['loan_name'], 'Home loan');
    expect(controller.upcomingInstallmentsError.value, isEmpty);
  });

  test('fetches authenticated loan summary for the current quarter', () async {
    final requests = <http.Request>[];
    final controller = LoansController(
      clock: () => DateTime(2026, 10, 27),
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'summary': {
                  'total_principal': '25000.00',
                  'total_repaid': '5000.00',
                  'total_outstanding': '20000.00',
                  'total_loans': 3,
                },
              },
            }),
            200,
          );
        }),
      ),
    );

    await controller.fetchLoanSummary();

    expect(requests.first.method, 'GET');
    expect(
      requests.first.url.toString(),
      '${ApiService.loanSummaryUrl}'
      '?from_date=2026-10-01&to_date=2026-12-31',
    );
    expect(requests.first.headers['Authorization'], isNotEmpty);
    expect(controller.summaryPeriodLabel, '2026-10-01 to 2026-12-31');
    expect(controller.loanSummary['total_principal'], '25000.00');
    expect(controller.loanSummaryError.value, isEmpty);

    await controller.setSummaryPeriod(
      DateTime(2026, 1, 5),
      DateTime(2026, 1, 31),
    );

    expect(
      requests.last.url.toString(),
      '${ApiService.loanSummaryUrl}'
      '?from_date=2026-01-05&to_date=2026-01-31',
    );
    expect(controller.summaryPeriodDisplayLabel, 'Jan 5 – Jan 31, 2026');
  });

  test('fetches authenticated overdue loan installments', () async {
    http.Request? receivedRequest;
    final controller = LoansController(
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
                    'uuid': 'installment-uuid',
                    'loan_uuid': 'loan-uuid',
                    'loan_name': 'Home loan',
                    'amount_due': '450.00',
                    'due_date': '2026-10-01',
                    'days_overdue': 26,
                  },
                ],
              },
            }),
            200,
          );
        }),
      ),
    );

    await controller.fetchOverdueInstallments();

    expect(receivedRequest?.method, 'GET');
    expect(
      receivedRequest?.url.toString(),
      ApiService.overdueLoanInstallmentsUrl,
    );
    expect(receivedRequest?.headers['Authorization'], isNotEmpty);
    expect(controller.overdueInstallments, hasLength(1));
    expect(controller.overdueInstallments.single['amount_due'], '450.00');
    expect(controller.overdueInstallmentsError.value, isEmpty);
  });

  test('fetches authenticated loan pages and parses pagination', () async {
    final requests = <http.Request>[];
    final controller = LoansController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(jsonEncode(_loansResponse(page)), 200);
        }),
      ),
    );

    await controller.fetchLoans();

    expect(requests.first.method, 'GET');
    expect(
      requests.first.url.toString(),
      '${ApiService.loansUrl}?page=1&per_page=20',
    );
    expect(requests.first.headers['Authorization'], isNotEmpty);
    expect(controller.loans, hasLength(1));
    expect(controller.lenderName(controller.loans.first), 'Jamie Example');
    expect(controller.totalRecords.value, 2);
    expect(controller.hasMore, isTrue);

    await controller.loadNextPage();

    expect(requests.last.url.queryParameters, {'page': '2', 'per_page': '20'});
    expect(controller.loans, hasLength(2));
    expect(controller.currentPage.value, 2);
    expect(controller.hasMore, isFalse);
    expect(controller.loadMoreError.value, isEmpty);
  });

  testWidgets('renders loan fields returned by the v1 API', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(
      LoansController(
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((request) async {
            if (request.url.toString() ==
                ApiService.upcomingLoanInstallmentsUrl) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'items': [
                      {
                        'loan_name': 'Home loan',
                        'installment_amount': '500.00',
                        'due_date': '2026-12-05',
                      },
                    ],
                  },
                }),
                200,
              );
            }
            if (request.url.toString() ==
                ApiService.overdueLoanInstallmentsUrl) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'items': [
                      {
                        'uuid': 'installment-uuid',
                        'loan_uuid': 'loan-1',
                        'loan_name': 'Overdue home loan',
                        'amount_due': '450.00',
                        'due_date': '2026-10-01',
                        'days_overdue': 26,
                      },
                    ],
                  },
                }),
                200,
              );
            }
            if (request.url.path == Uri.parse(ApiService.loanSummaryUrl).path) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'total_principal': '25000.00',
                    'total_repaid': '5000.00',
                    'total_outstanding': '20000.00',
                    'total_loans': 3,
                  },
                }),
                200,
              );
            }
            final page = int.parse(request.url.queryParameters['page']!);
            return http.Response(
              jsonEncode(_loansResponse(page, lastPage: 1)),
              200,
            );
          }),
        ),
      ),
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: LoansView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(Get.find<LoansController>().loanSummary, isNotEmpty);
    expect(Get.find<LoansController>().loans, isNotEmpty);
    expect(find.text('Loans'), findsNWidgets(2));
    expect(find.text('Loan summary'), findsOneWidget);
    expect(find.text('Total repaid'), findsOneWidget);
    expect(find.text('₹5000.00'), findsAtLeastNWidgets(1));
    expect(find.text('Total loans'), findsOneWidget);
    await tester.tap(find.text('Loans').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Partial EMI payment'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Partial EMI payment'), findsOneWidget);
    expect(find.text('Principal payment'), findsOneWidget);

    await tester.tap(find.text('Overdue').first);
    await tester.pumpAndSettle();
    expect(find.text('Overdue installments'), findsOneWidget);
    expect(find.text('Overdue home loan'), findsOneWidget);
    expect(find.textContaining('Overdue by 26 days'), findsOneWidget);
    expect(find.text('₹450.00'), findsOneWidget);

    await tester.tap(find.text('Upcoming').first);
    await tester.pumpAndSettle();
    expect(find.text('Upcoming installments'), findsOneWidget);
    expect(find.textContaining('Home loan'), findsAtLeastNWidgets(1));
    expect(find.text('₹500.00'), findsOneWidget);
    expect(find.textContaining('05 Dec 2026'), findsOneWidget);
    await tester.tap(find.text('Loans').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Jamie Example'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Home loan'), findsAtLeastNWidgets(1));
    expect(find.text('Jamie Example'), findsOneWidget);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('₹4500.00'), findsOneWidget);
    expect(find.text('₹5000.00'), findsAtLeastNWidgets(1));
    expect(find.textContaining('8.5000% p.a.'), findsOneWidget);
    expect(find.textContaining('12 months'), findsOneWidget);
    expect(find.textContaining('2026-12-05'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}

Map<String, dynamic> _loansResponse(int page, {int lastPage = 2}) => {
  'success': true,
  'status': 200,
  'message': 'Loan records fetched successfully.',
  'data': {
    'items': [
      {
        'uuid': 'loan-$page',
        'name': page == 1 ? 'Home loan' : 'Auto loan',
        'lender_name': page == 1 ? 'Jamie Example' : 'Taylor Example',
        'loan_type': page == 1 ? 'home' : 'auto',
        'sanctioned_amount': '5000.00',
        'principal_amount': '4500.00',
        'annual_interest_rate': '8.5000',
        'tenure_months': 12,
        'first_due_date': '2026-12-05',
      },
    ],
    'pagination': {
      'current_page': page,
      'per_page': 20,
      'total': 2,
      'last_page': lastPage,
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
