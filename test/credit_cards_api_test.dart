import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/credit_cards/controllers/credit_cards_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fetches authenticated credit cards from the v1 endpoint', () async {
    late http.Request request;
    final controller = CreditCardsController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    'name': 'Rewards Primary',
                    'issuer': 'Example Bank',
                    'last_four': '1234',
                    'credit_limit': '150000.00',
                  },
                ],
              },
            }),
            200,
          );
        }),
      ),
    );

    await controller.fetchCreditCards();

    expect(request.method, 'GET');
    expect(request.url.toString(), ApiService.creditCardsUrl);
    expect(request.headers['Authorization'], 'Bearer test-access-token');
    expect(controller.cards, hasLength(1));
    expect(controller.cards.first['name'], 'Rewards Primary');
    expect(controller.errorMessage.value, isEmpty);
  });

  test('posts credit cards to the credit-card endpoint', () async {
    late http.Request request;
    final api = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(jsonEncode({'success': true, 'data': {}}), 201);
      }),
    );

    await api.postCreditCard({
      'name': 'Postman everyday card',
      'issuer': 'Example Bank',
      'network': 'Visa',
      'last_four': '4242',
      'currency': 'INR',
      'credit_limit': '100000.00',
      'billing_day': 15,
      'due_days_after_statement': 20,
      'minimum_due_percent': '5.00',
      'minimum_due_amount': '0.00',
      'notes': 'Phase 7 test card',
    }, idempotencyKey: 'credit-card-test-key');

    expect(request.method, 'POST');
    expect(request.url.toString(), ApiService.creditCardsUrl);
    expect(request.headers['Authorization'], 'Bearer test-access-token');
    expect(request.headers['Idempotency-Key'], 'credit-card-test-key');
    expect(jsonDecode(request.body), {
      'name': 'Postman everyday card',
      'issuer': 'Example Bank',
      'network': 'Visa',
      'last_four': '4242',
      'currency': 'INR',
      'credit_limit': '100000.00',
      'billing_day': 15,
      'due_days_after_statement': 20,
      'minimum_due_percent': '5.00',
      'minimum_due_amount': '0.00',
      'notes': 'Phase 7 test card',
    });
  });

  test('fetches the credit-card report from the report endpoint', () async {
    late http.Request request;
    final controller = CreditCardsController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'card_count': 2,
                'totals_by_currency': [
                  {
                    'currency': 'INR',
                    'credit_limit': '50000.00',
                    'outstanding_liability': '0.00',
                    'available_credit': '50000.00',
                    'credit_utilization_percent': '0.00',
                  },
                ],
              },
            }),
            200,
          );
        }),
      ),
    );

    await controller.fetchCreditCardsReport();

    expect(request.method, 'GET');
    expect(request.url.toString(), ApiService.creditCardsReportUrl);
    expect(controller.reportCardCount.value, 2);
    expect(controller.reportTotals, hasLength(1));
    expect(controller.reportTotals.first['currency'], 'INR');
    expect(controller.reportErrorMessage.value, isEmpty);
  });

  test('fetches credit card transactions from the v1 endpoint', () async {
    late http.Request request;
    final api = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {'uuid': 'transaction-1', 'description': 'Coffee'},
              ],
            },
          }),
          200,
        );
      }),
    );

    final response = await api.getCreditCardTransactions('card/uuid');

    expect(response.statusCode, 200);
    expect(
      request.url.toString(),
      '${ApiService.creditCardsUrl}/card%2Fuuid/transactions',
    );
    expect(request.headers['Authorization'], 'Bearer test-access-token');
  });

  test('posts a purchase to the credit card transactions endpoint', () async {
    late http.Request request;
    final api = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(jsonEncode({'success': true, 'data': {}}), 201);
      }),
    );

    await api.postCreditCardTransaction('card/uuid', {
      'kind': 'purchase',
      'amount': '100.00',
      'transaction_date': '2026-10-14',
      'category_uuid': 'expense-category-uuid',
      'description': 'Postman card purchase',
      'reference': 'PM-CC-PURCHASE-1',
      'notes': 'Verify bank balance is unchanged',
    }, idempotencyKey: 'credit-card-purchase-test-key');

    expect(request.method, 'POST');
    expect(
      request.url.toString(),
      '${ApiService.creditCardsUrl}/card%2Fuuid/transactions',
    );
    expect(request.headers['Authorization'], 'Bearer test-access-token');
    expect(request.headers['Idempotency-Key'], 'credit-card-purchase-test-key');
    expect(jsonDecode(request.body), {
      'kind': 'purchase',
      'amount': '100.00',
      'transaction_date': '2026-10-14',
      'category_uuid': 'expense-category-uuid',
      'description': 'Postman card purchase',
      'reference': 'PM-CC-PURCHASE-1',
      'notes': 'Verify bank balance is unchanged',
    });
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
