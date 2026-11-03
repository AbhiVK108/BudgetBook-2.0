import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('posts a savings goal with idempotency key and auth', () async {
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
            'data': {'uuid': 'savings-goal-uuid'},
          }),
          201,
        );
      }),
    );

    final response = await api.postSavingsGoal({
      'name': 'Emergency fund test goal',
      'currency': 'INR',
      'target_amount': '100000.00',
      'description': 'Tracking-only Phase 8 goal',
    }, idempotencyKey: 'phase-8-savings-goal');

    expect(response.statusCode, 201);
    expect(request.method, 'POST');
    expect(request.url.toString(), ApiService.savingsGoalsUrl);
    expect(request.headers['Authorization'], 'Bearer saved-access-token');
    expect(request.headers['Idempotency-Key'], 'phase-8-savings-goal');
    expect(jsonDecode(request.body), {
      'name': 'Emergency fund test goal',
      'currency': 'INR',
      'target_amount': '100000.00',
      'description': 'Tracking-only Phase 8 goal',
    });
  });

  test(
    'posts a savings goal contribution with idempotency key and auth',
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
              'data': {'uuid': 'contribution-uuid'},
            }),
            201,
          );
        }),
      );

      final response = await api.postSavingsGoalContribution(
        'savings-goal-uuid',
        {'amount': '500.00', 'notes': 'Test contribution; no account movement'},
        idempotencyKey: 'savings-contribution-key',
      );

      expect(response.statusCode, 201);
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        '${ApiService.savingsGoalsUrl}/savings-goal-uuid/contributions',
      );
      expect(request.headers['Authorization'], isNotEmpty);
      expect(request.headers['Idempotency-Key'], 'savings-contribution-key');
      expect(jsonDecode(request.body), {
        'amount': '500.00',
        'notes': 'Test contribution; no account movement',
      });
    },
  );

  test('gets a savings goal summary', () async {
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
            'data': {'target_amount': '100000.00', 'saved_amount': '25000.00'},
          }),
          200,
        );
      }),
    );

    final response = await api.getSavingsGoalSummary('savings-goal-uuid');

    expect(response.statusCode, 200);
    expect(request.method, 'GET');
    expect(
      request.url.toString(),
      '${ApiService.savingsGoalsUrl}/savings-goal-uuid/summary',
    );
    expect(request.headers['Authorization'], isNotEmpty);
  });

  test('gets the portfolio savings goals summary', () async {
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
            'data': {
              'total_target_amount': '100000.00',
              'total_saved_amount': '25000.00',
              'total_goals': 3,
            },
          }),
          200,
        );
      }),
    );

    final response = await api.getSavingsGoalsSummary();

    expect(response.statusCode, 200);
    expect(request.method, 'GET');
    expect(request.url.toString(), ApiService.savingsGoalsSummaryUrl);
    expect(request.headers['Authorization'], isNotEmpty);
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
