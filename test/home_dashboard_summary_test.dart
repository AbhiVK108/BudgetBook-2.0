import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/home/controllers/home_controller.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requests this-month dashboard summary and maps aliases', () async {
    SharedPreferences.setMockInitialValues({});

    late http.Request request;

    final controller = HomeController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(jsonEncode(_summaryResponse), 200);
        }),
      ),
      clock: () => DateTime(2026, 10, 24),
    );

    await controller.fetchTotals();

    expect(request.method, 'GET');

    expect(
      request.url.toString(),
      '${ApiService.dashboardSummaryUrl}'
      '?period=this_month',
    );

    expect(request.headers['Authorization'], 'Bearer test-access-token');

    expect(controller.summaryPeriodLabel, 'This month');
    expect(controller.totalIncome.value, 12345.67);
    expect(controller.totalExpense.value, 2345.67);
    expect(controller.available.value, 8000);
    expect(controller.loanDue.value, 750);
    expect(controller.debitDue.value, 250);

    expect(controller.hasIncomeSummary.value, isTrue);
    expect(controller.hasExpenseSummary.value, isTrue);
    expect(controller.errorMessage.value, isEmpty);
  });

  test('maps nested total aliases and formatted numeric values', () async {
    final controller = HomeController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'totals': {
                  'total_income_amount': {'amount': '₹12,345.67'},
                  'expense_total': {'value': '-2,345.67'},
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
      clock: () => DateTime(2026, 10, 24),
    );

    await controller.fetchTotals();

    expect(controller.totalIncome.value, 12345.67);
    expect(controller.totalExpense.value, -2345.67);
    expect(controller.errorMessage.value, isEmpty);
  });

  test('maps totals_by_currency from dashboard API shape', () async {
    final controller = HomeController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'income': {
                  'totals_by_currency': [
                    {'currency': 'INR', 'total_amount': '50000.00'},
                  ],
                },
                'expenses': {
                  'totals_by_currency': [
                    {'currency': 'INR', 'total_amount': '100.00'},
                  ],
                },
                'net_cash_flow_by_currency': [
                  {'currency': 'INR', 'amount': '49900.00'},
                ],
                'receivables': {
                  'totals_by_currency': [
                    {'currency': 'INR', 'total_amount': '750.00'},
                  ],
                },
                'payables': {
                  'totals_by_currency': [
                    {'currency': 'INR', 'total_amount': '250.00'},
                  ],
                },
              },
            }),
            200,
          );
        }),
      ),
      clock: () => DateTime(2026, 11, 3),
    );

    await controller.fetchTotals();

    expect(controller.totalIncome.value, 50000);
    expect(controller.totalExpense.value, 100);
    expect(controller.available.value, 49900);
    expect(controller.loanDue.value, 750);
    expect(controller.debitDue.value, 250);
    expect(controller.errorMessage.value, isEmpty);
  });

  test('maps lending and borrowing outstanding currency totals', () async {
    final controller = HomeController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'income': {
                  'totals_by_currency': [
                    {'currency': 'INR', 'total_amount': '5000.00'},
                  ],
                },
                'expenses': {
                  'totals_by_currency': [
                    {'currency': 'INR', 'total_amount': '500.00'},
                  ],
                },
                'lending': {
                  'totals_by_currency': [
                    {'currency': 'INR', 'total_outstanding': '12500.50'},
                  ],
                },
                'borrowing': {
                  'totals_by_currency': [
                    {'currency': 'INR', 'total_outstanding': '2750.25'},
                  ],
                },
              },
            }),
            200,
          );
        }),
      ),
      clock: () => DateTime(2026, 11, 3),
    );

    await controller.fetchTotals();

    expect(controller.loanDue.value, 12500.50);
    expect(controller.debitDue.value, 2750.25);
    expect(controller.hasLoanDueSummary.value, isTrue);
    expect(controller.hasDebitDueSummary.value, isTrue);
    expect(controller.errorMessage.value, isEmpty);
  });

  testWidgets('displays compact available balance in home banner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});

    Get.put(
      HomeController(
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((_) async {
            return http.Response(jsonEncode(_summaryResponse), 200);
          }),
        ),
        clock: () => DateTime(2026, 10, 24),
      ),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(
          home: Scaffold(
            body: Padding(padding: EdgeInsets.all(16), child: HomeBanner()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Available balance'), findsOneWidget);
    expect(find.text('₹8000.00'), findsOneWidget);
    expect(find.text('Across your accounts'), findsOneWidget);

    expect(tester.takeException(), isNull);

    Get.reset();
  });

  testWidgets('displays and handles home quick actions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var incomeTapped = false;
    var expenseTapped = false;
    var transferTapped = false;
    var moreTapped = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => GetMaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: HomeQuickActions(
                onAddIncome: () => incomeTapped = true,
                onAddExpense: () => expenseTapped = true,
                onTransfer: () => transferTapped = true,
                onMore: () => moreTapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all actions are visible.
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Verify Income action.
    await tester.tap(find.text('Income'));
    await tester.pump();

    expect(incomeTapped, isTrue);

    // Verify Expense action.
    await tester.tap(find.text('Expense'));
    await tester.pump();

    expect(expenseTapped, isTrue);

    // Verify Transfer action.
    await tester.tap(find.text('Transfer'));
    await tester.pump();

    expect(transferTapped, isTrue);

    // Verify More action.
    await tester.tap(find.text('More'));
    await tester.pump();

    expect(moreTapped, isTrue);

    expect(tester.takeException(), isNull);
  });
}

final Map<String, dynamic> _summaryResponse = {
  'success': true,
  'status': 200,
  'data': {
    'income': {'monthly_breakdown': []},
    'totals': {'total_income': '12345.67', 'total_expense': '2345.67'},
    'balances': {'net_balance': '8000.00'},
    'receivables': {'total_receivable': '750.00'},
    'payables': {'total_payable': '250.00'},
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
