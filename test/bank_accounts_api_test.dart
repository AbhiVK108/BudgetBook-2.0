import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/bank_account/controllers/bank_accounts_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and parses authenticated bank account list', () async {
    http.Request? request;
    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({
            'success': true,
            'status': 200,
            'data': {
              'items': [
                {
                  'uuid': 'bank-uuid',
                  'name': 'Primary Bank',
                  'type': 'bank',
                  'institution': 'Example Bank',
                  'currency': 'INR',
                  'status': 'active',
                  'created_at': '2026-10-14 18:08:59',
                  'balance': '30000.00',
                },
                {
                  'uuid': 'cash-uuid',
                  'name': 'Cash',
                  'type': 'cash',
                  'institution': null,
                  'currency': 'INR',
                  'status': 'active',
                  'created_at': '2026-10-14 18:07:39',
                  'balance': '0.00',
                },
                {
                  'uuid': 'archived-bank-uuid',
                  'name': 'Archived Bank',
                  'type': 'bank',
                  'institution': 'Closed Bank',
                  'currency': 'INR',
                  'status': 'archived',
                  'created_at': '2026-10-13 12:00:00',
                  'balance': '0.00',
                },
              ],
            },
          }),
          200,
        );
      }),
    );
    final controller = BankAccountsController(apiService: apiService);

    await controller.fetchAccounts();

    expect(request?.method, 'GET');
    expect(
      request?.url.toString(),
      '${ApiService.accountsUrl}?include_archived=1',
    );
    expect(request?.headers['Authorization'], isNotEmpty);
    expect(controller.errorMessage.value, isEmpty);
    expect(controller.accounts, hasLength(3));
    expect(controller.accounts.first.name, 'Primary Bank');
    expect(controller.accounts.first.balance, '30000.00');
    expect(controller.accounts[1].type, 'cash');
    expect(controller.accounts.last.status, 'archived');

    controller.selectedAccountFilter.value = 'bank';
    expect(controller.filteredAccounts.map((account) => account.name), [
      'Primary Bank',
      'Archived Bank',
    ]);
    controller.selectedAccountFilter.value = 'cash';
    expect(controller.filteredAccounts.map((account) => account.name), [
      'Cash',
    ]);
    controller.selectedAccountFilter.value = 'all';
    expect(controller.filteredAccounts, hasLength(3));
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
