import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/expense_controller.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/post_expense_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads paginated v1 expense transactions and filters by date', () async {
    final storage = _MemoryCredentialStorage()
      ..values['accessToken'] = 'saved-access-token';
    late http.Request request;
    final controller = ExpenseController(
      apiService: ApiService(
        credentialStorage: storage,
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'success': true,
              'status': 200,
              'message': 'Expense transactions fetched successfully.',
              'data': {
                'items': [
                  {
                    'uuid': 'expense-october',
                    'type': 'expense',
                    'amount': '8000.00',
                    'currency': 'INR',
                    'transaction_date': '2026-10-14',
                    'description': 'Rent',
                    'counterparty': 'Landlord',
                    'category_uuid': 'rent-category-uuid',
                    'category_name': 'Rent',
                    'source_account_uuid': 'source-account-uuid',
                  },
                  {
                    'uuid': 'expense-september',
                    'type': 'expense',
                    'amount': '1200.00',
                    'currency': 'INR',
                    'transaction_date': '2026-09-30',
                    'description': 'Utilities',
                    'counterparty': 'Utility provider',
                    'category_uuid': 'utility-category-uuid',
                    'category_name': 'Utilities',
                    'source_account_uuid': 'source-account-uuid',
                  },
                ],
                'pagination': {
                  'current_page': 1,
                  'per_page': 20,
                  'total': 2,
                  'last_page': 1,
                },
              },
              '_meta': {'request_id': 'test-expense-list'},
              'errors': [],
              'timestamp': '2026-10-14 18:37:15',
            }),
            200,
          );
        }),
      ),
    )..selectedMonth.value = DateTime(2026, 10);

    await controller.getExpenses();

    expect(request.method, 'GET');
    expect(request.url.path, '/api/v1/expenses');
    expect(request.url.queryParameters, {'page': '1', 'per_page': '20'});
    expect(request.headers['Authorization'], isNotEmpty);
    expect(request.headers['Accept'], 'application/json');
    expect(controller.expenses, hasLength(2));
    expect(controller.filteredExpenses, hasLength(1));
    expect(controller.filteredExpenses.single['uuid'], 'expense-october');
    expect(controller.filteredExpenses.single['category_name'], 'Rent');
    expect(controller.filteredTotalExpense, 8000);
    controller.onClose();
  });

  testWidgets(
    'expense form loads UUID choices and posts authenticated v1 JSON',
    (tester) async {
      final storage = _MemoryCredentialStorage()
        ..values['accessToken'] = 'saved-access-token';
      final expenseRequests = <http.Request>[];
      final api = ApiService(
        credentialStorage: storage,
        client: MockClient((request) async {
          if (request.url.toString() ==
              '${ApiService.categoriesUrl}?type=expense') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'rent-category-uuid',
                      'name': 'Rent',
                      'type': 'expense',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (request.url.toString() == ApiService.accountsUrl) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {'uuid': 'source-account-uuid', 'name': 'Everyday account'},
                  ],
                },
              }),
              200,
            );
          }

          expenseRequests.add(request);
          return http.Response(
            jsonEncode({
              'success': true,
              'status': 201,
              'message': 'Expense transaction created successfully.',
              'data': {
                'transaction': {
                  'uuid': 'created-expense-uuid',
                  'type': 'expense',
                  'amount': '8000.00',
                  'currency': 'INR',
                  'transaction_date': '2026-10-14',
                  'description': 'October rent',
                  'counterparty': 'Test landlord',
                  'status': 'posted',
                  'category_uuid': 'rent-category-uuid',
                  'source_account_uuid': 'source-account-uuid',
                },
                'idempotent_replay': false,
              },
              '_meta': {'request_id': 'test-request'},
              'errors': [],
              'timestamp': '2026-10-14 18:36:57',
            }),
            201,
          );
        }),
      );
      final controller = PostExpenseController(apiService: api)
        ..selectedDate.value = '2026-10-14'
        ..amountController.text = '8000'
        ..counterpartyController.text = 'Test landlord'
        ..noteController.text = 'October rent';

      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: SizedBox())),
      );
      await controller.getExpenseCategories();
      await controller.getSourceAccounts();

      expect(controller.categories.single['uuid'], 'rent-category-uuid');
      controller.selectCategory(0);
      expect(controller.selectedCategoryId.value, 'rent-category-uuid');
      expect(controller.selectedSourceAccountUuid.value, 'source-account-uuid');

      final firstSave = controller.saveExpense();
      await controller.saveExpense();
      await firstSave;

      expect(expenseRequests, hasLength(1));
      final request = expenseRequests.single;
      expect(request.method, 'POST');
      expect(request.url.toString(), ApiService.expenseTransactionsUrl);
      expect(request.headers['Authorization'], isNotEmpty);
      expect(request.headers['Content-Type'], 'application/json');
      expect(request.headers['Accept'], 'application/json');
      expect(
        request.headers['Idempotency-Key'],
        matches(RegExp(r'^[0-9a-f-]{36}$')),
      );
      expect(jsonDecode(request.body), {
        'amount': '8000.00',
        'transaction_date': '2026-10-14',
        'source_account_uuid': 'source-account-uuid',
        'category_uuid': 'rent-category-uuid',
        'counterparty': 'Test landlord',
        'description': 'October rent',
      });
      expect(controller.amountController.text, isEmpty);
      expect(controller.counterpartyController.text, isEmpty);
      expect(controller.noteController.text, isEmpty);
      expect(controller.selectedCategoryId.value, isNull);
      expect(controller.selectedSourceAccountUuid.value, isNull);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      controller.onClose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reuses expense idempotency key after authentication refresh', (
    tester,
  ) async {
    final storage = _MemoryCredentialStorage()
      ..values['accessToken'] = 'expired-access-token'
      ..values['refreshToken'] = 'saved-refresh-token';
    final expenseRequests = <http.Request>[];
    final api = ApiService(
      credentialStorage: storage,
      client: MockClient((request) async {
        if (request.url.toString() == ApiService.refreshTokenUrl) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'access_token': 'refreshed-access-token'},
            }),
            200,
          );
        }

        expenseRequests.add(request);
        if (expenseRequests.length == 1) {
          return http.Response('{"message":"Unauthenticated"}', 401);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'status': 201,
            'message': 'Expense transaction created successfully.',
            'data': {
              'transaction': {
                'uuid': 'created-expense-uuid',
                'type': 'expense',
              },
            },
          }),
          201,
        );
      }),
    );
    final controller = PostExpenseController(apiService: api)
      ..selectedDate.value = '2026-10-14'
      ..amountController.text = '8000'
      ..counterpartyController.text = 'Test landlord'
      ..noteController.text = 'October rent'
      ..selectedCategoryId.value = 'rent-category-uuid'
      ..selectedSourceAccountUuid.value = 'source-account-uuid';
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox())),
    );
    await controller.saveExpense();

    expect(expenseRequests, hasLength(2));
    expect(
      expenseRequests.first.headers['Idempotency-Key'],
      expenseRequests.last.headers['Idempotency-Key'],
    );
    expect(expenseRequests.last.headers['Authorization'], isNotEmpty);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    controller.onClose();
    expect(tester.takeException(), isNull);
  });
}

class _MemoryCredentialStorage implements AuthCredentialStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
