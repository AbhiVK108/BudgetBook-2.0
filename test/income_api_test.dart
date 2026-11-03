import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/income_expense_controller.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/post_income_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads paginated v1 income and filters using transaction_date',
    () async {
      final storage = _MemoryCredentialStorage()
        ..values['accessToken'] = 'saved-access-token';
      late http.Request request;
      final api = ApiService(
        credentialStorage: storage,
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'success': true,
              'status': 200,
              'data': {
                'items': [
                  {
                    'uuid': 'income-october',
                    'type': 'income',
                    'amount': '30000.00',
                    'currency': 'INR',
                    'transaction_date': '2026-10-14',
                    'description': 'Salary',
                    'category_name': 'Salary',
                  },
                  {
                    'uuid': 'income-september',
                    'type': 'income',
                    'amount': '5000.00',
                    'currency': 'INR',
                    'transaction_date': '2026-09-30',
                    'description': 'Bonus',
                    'category_name': 'Bonus',
                  },
                ],
                'pagination': {
                  'current_page': 1,
                  'per_page': 20,
                  'total': 2,
                  'last_page': 1,
                },
              },
            }),
            200,
          );
        }),
      );
      final controller = IncomeExpenseController(apiService: api)
        ..selectedMonth.value = DateTime(2026, 10);

      await controller.getIncome();

      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/income');
      expect(request.url.queryParameters, {'page': '1', 'per_page': '20'});
      expect(request.headers['Authorization'], 'Bearer saved-access-token');
      expect(controller.incomeList, hasLength(2));
      expect(controller.filteredIncome, hasLength(1));
      expect(controller.filteredIncome.single['uuid'], 'income-october');
      expect(controller.filteredIncome.single['category_name'], 'Salary');
      expect(controller.filteredTotalIncome, 30000);
    },
  );

  test('posts v1 income with UUID fields and Bearer token', () async {
    final storage = _MemoryCredentialStorage()
      ..values['accessToken'] = 'saved-access-token';
    late http.Request request;
    final api = ApiService(
      credentialStorage: storage,
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({
            'success': true,
            'status': 201,
            'message': 'Income transaction created successfully.',
            'data': {
              'transaction': {'uuid': 'created-income'},
              'idempotent_replay': false,
            },
          }),
          201,
        );
      }),
    );

    final response = await api.postIncome({
      'amount': '30000.00',
      'transaction_date': '2026-10-14',
      'destination_account_uuid': 'bank-account-uuid',
      'category_uuid': 'income-category-uuid',
      'counterparty': 'Postman test payer',
      'description': 'Postman test income',
    }, idempotencyKey: 'f27d5ba9-d6c2-4be6-9382-5ab82e680a78');

    expect(response.statusCode, 201);
    expect(request.method, 'POST');
    expect(request.url.toString(), ApiService.incomeTransactionsUrl);
    expect(request.headers['Authorization'], 'Bearer saved-access-token');
    expect(request.headers['Content-Type'], 'application/json');
    expect(
      request.headers['Idempotency-Key'],
      'f27d5ba9-d6c2-4be6-9382-5ab82e680a78',
    );
    expect(jsonDecode(request.body), {
      'amount': '30000.00',
      'transaction_date': '2026-10-14',
      'destination_account_uuid': 'bank-account-uuid',
      'category_uuid': 'income-category-uuid',
      'counterparty': 'Postman test payer',
      'description': 'Postman test income',
    });
  });

  test('income POST reuses idempotency key after token refresh', () async {
    final storage = _MemoryCredentialStorage()
      ..values['accessToken'] = 'expired-access-token'
      ..values['refreshToken'] = 'saved-refresh-token';
    final incomeRequests = <http.Request>[];
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

        incomeRequests.add(request);
        if (incomeRequests.length == 1) {
          return http.Response('{"message":"Unauthenticated"}', 401);
        }
        return http.Response('{"success":true}', 201);
      }),
    );
    const idempotencyKey = '91f67831-4956-4715-8d25-c8990103e3dd';

    final response = await api.postIncome({
      'amount': '30000.00',
      'transaction_date': '2026-10-14',
      'destination_account_uuid': 'bank-account-uuid',
      'category_uuid': 'income-category-uuid',
      'counterparty': 'Payer',
      'description': 'Income',
    }, idempotencyKey: idempotencyKey);

    expect(response.statusCode, 201);
    expect(incomeRequests, hasLength(2));
    expect(incomeRequests.first.headers['Idempotency-Key'], idempotencyKey);
    expect(incomeRequests.last.headers['Idempotency-Key'], idempotencyKey);
    expect(
      incomeRequests.last.headers['Authorization'],
      'Bearer refreshed-access-token',
    );
  });

  test('loads active v1 income categories and selects their UUID', () async {
    final storage = _MemoryCredentialStorage()
      ..values['accessToken'] = 'saved-access-token';
    late http.Request request;
    final controller = PostIncomeController(
      apiService: ApiService(
        credentialStorage: storage,
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    'uuid': 'salary-category-uuid',
                    'name': 'Postman Salary Test',
                    'type': 'income',
                    'icon': 'salary',
                    'status': 'active',
                  },
                ],
              },
            }),
            200,
          );
        }),
      ),
    );

    await controller.getIncomeCategories();

    expect(request.method, 'GET');
    expect(request.url.path, '/api/v1/categories');
    expect(request.url.queryParameters, {'type': 'income'});
    expect(request.headers['Authorization'], 'Bearer saved-access-token');
    expect(controller.categories, hasLength(1));
    expect(controller.categories.single['name'], 'Postman Salary Test');

    controller.selectCategory(0);
    expect(controller.selectedCategoryId.value, 'salary-category-uuid');
    controller.onClose();
  });

  test('creates income category and selects returned UUID', () async {
    final storage = _MemoryCredentialStorage()
      ..values['accessToken'] = 'saved-access-token';
    late http.Request request;
    final controller = PostIncomeController(
      apiService: ApiService(
        credentialStorage: storage,
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'success': true,
              'status': 201,
              'message': 'Category created successfully.',
              'data': {
                'uuid': 'created-category-uuid',
                'name': 'Freelance',
                'type': 'income',
                'icon': 'salary',
                'sort_order': '100',
                'status': 'active',
              },
            }),
            201,
          );
        }),
      ),
    );

    final category = await controller.createIncomeCategory(
      name: 'Freelance',
      icon: 'salary',
    );

    expect(request.method, 'POST');
    expect(request.url.toString(), ApiService.categoriesUrl);
    expect(request.headers['Authorization'], 'Bearer saved-access-token');
    expect(request.headers['Content-Type'], 'application/json');
    expect(jsonDecode(request.body), {
      'name': 'Freelance',
      'type': 'income',
      'icon': 'salary',
      'sort_order': 100,
    });
    expect(category?['uuid'], 'created-category-uuid');
    expect(controller.categories.single['name'], 'Freelance');
    expect(controller.selectedCategoryId.value, 'created-category-uuid');
    expect(controller.selectedIndex.value, 0);
    controller.onClose();
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
