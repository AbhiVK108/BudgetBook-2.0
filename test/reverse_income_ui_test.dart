import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/income_expense_controller.dart';
import 'package:budget_book_2026/app/modules/income_expense/views/income_expense_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;
  late IncomeExpenseController controller;

  setUp(() {
    requests = [];
    controller = IncomeExpenseController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/reverse')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Income reversed successfully.',
              }),
              200,
            );
          }
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      ),
    );
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> showIncomeTile(
    WidgetTester tester, {
    Map<String, dynamic> transaction = const {
      'uuid': 'income-transaction-uuid',
      'type': 'income',
      'amount': '125.00',
      'currency': 'INR',
      'transaction_date': '2026-10-14',
    },
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => GetMaterialApp(
          home: Scaffold(
            body: TransactionTile(income: transaction, controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers reversal action for an eligible income transaction', (
    tester,
  ) async {
    await showIncomeTile(tester);

    expect(find.byTooltip('Transaction actions'), findsOneWidget);

    await tester.tap(find.byTooltip('Transaction actions'));
    await tester.pumpAndSettle();

    expect(find.text('Reverse income'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('hides reversal for an already reversed transaction', (
    tester,
  ) async {
    await showIncomeTile(
      tester,
      transaction: const {
        'uuid': 'income-transaction-uuid',
        'type': 'income',
        'is_reversed': true,
      },
    );

    expect(find.byTooltip('Transaction actions'), findsOneWidget);
    await tester.tap(find.byTooltip('Transaction actions'));
    await tester.pumpAndSettle();
    expect(find.text('Edit income'), findsOneWidget);
    expect(find.text('Delete income'), findsOneWidget);
    expect(find.text('Reverse income'), findsNothing);
    expect(requests, isEmpty);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('hides reversal for non-income or UUID-less records', (
    tester,
  ) async {
    await showIncomeTile(
      tester,
      transaction: const {
        'uuid': 'expense-transaction-uuid',
        'type': 'expense',
      },
    );

    expect(find.byTooltip('Transaction actions'), findsOneWidget);
    await tester.tap(find.byTooltip('Transaction actions'));
    await tester.pumpAndSettle();
    expect(find.text('Reverse income'), findsNothing);
    expect(requests, isEmpty);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await showIncomeTile(tester, transaction: const {'type': 'income'});

    expect(find.byTooltip('Transaction actions'), findsOneWidget);
    await tester.tap(find.byTooltip('Transaction actions'));
    await tester.pumpAndSettle();
    expect(find.text('Reverse income'), findsNothing);
    expect(requests, isEmpty);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('cancel dismisses confirmation without making a request', (
    tester,
  ) async {
    await showIncomeTile(tester);
    await tester.tap(find.byTooltip('Transaction actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reverse income'));
    await tester.pumpAndSettle();

    expect(find.text('Reverse this income?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reverse this income?'), findsNothing);
    expect(requests, isEmpty);
  });
}

class _MemoryCredentialStorage implements AuthCredentialStorage {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
