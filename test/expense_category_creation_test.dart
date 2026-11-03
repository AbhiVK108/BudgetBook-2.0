import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/post_expense_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates and selects an expense category', () async {
    late http.Request request;
    final controller = PostExpenseController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'success': true,
              'status': 201,
              'message': 'Category created successfully.',
              'data': {
                'uuid': 'rent-category-uuid',
                'name': 'Postman Rent Test',
                'type': 'expense',
                'icon': 'home',
                'status': 'active',
              },
            }),
            201,
          );
        }),
      ),
    );

    final createdCategory = await controller.createExpenseCategory(
      name: ' Postman Rent Test ',
      icon: 'home',
    );

    expect(request.method, 'POST');
    expect(request.url.toString(), ApiService.categoriesUrl);
    expect(request.headers['Authorization'], isNotEmpty);
    expect(jsonDecode(request.body), {
      'name': 'Postman Rent Test',
      'type': 'expense',
      'icon': 'home',
      'sort_order': 100,
    });
    expect(createdCategory?['uuid'], 'rent-category-uuid');
    expect(controller.categories.single['name'], 'Postman Rent Test');
    expect(controller.selectedCategoryId.value, 'rent-category-uuid');
    expect(controller.selectedIndex.value, 0);

    controller.onClose();
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
