import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/expense_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('posts expense reversal and reloads expenses', (tester) async {
    final requests = <http.Request>[];
    final controller = ExpenseController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/reverse')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'status': 200,
                'message': 'Expense reversed successfully.',
                'data': {'uuid': 'reversal-uuid'},
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'items': []},
            }),
            200,
          );
        }),
      ),
    );

    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    await controller.reverseExpense('expense-transaction-uuid');
    await tester.pumpAndSettle();

    expect(requests, hasLength(2));
    expect(requests.first.method, 'POST');
    expect(
      requests.first.url.toString(),
      '${ApiService.expenseTransactionsUrl}/expense-transaction-uuid/reverse',
    );
    expect(requests.first.headers['Authorization'], isNotEmpty);
    expect(jsonDecode(requests.first.body), isEmpty);
    expect(requests.last.method, 'GET');
    expect(controller.expenses, isEmpty);

    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    controller.onClose();
    expect(tester.takeException(), isNull);
  });

  test('offers reversal only for non-reversed expense transactions', () {
    expect(
      ExpenseController.canOfferExpenseReversal({
        'uuid': 'expense-uuid',
        'type': 'expense',
        'status': 'posted',
      }),
      isTrue,
    );
    expect(
      ExpenseController.canOfferExpenseReversal({
        'uuid': 'expense-uuid',
        'type': 'expense',
        'status': 'reversed',
      }),
      isFalse,
    );
    expect(
      ExpenseController.canOfferExpenseReversal({
        'uuid': 'income-uuid',
        'type': 'income',
      }),
      isFalse,
    );
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
