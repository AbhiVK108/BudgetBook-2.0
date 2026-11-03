import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'auth credentials are stored and readable through secure storage',
    () async {
      final storage = _MemoryCredentialStorage();
      final api = ApiService(credentialStorage: storage);

      await api.saveAuthCredentials(
        accessToken: 'access-token',
        userId: 'user-123',
        roleId: 'role-456',
        refreshToken: 'refresh-token',
      );

      expect(await api.getToken(), 'access-token');
      expect(await api.getUserId(), 'user-123');
      expect(await api.getRoleId(), 'role-456');
      expect(await api.getRefreshToken(), 'refresh-token');
    },
  );

  test(
    'session restore accepts a saved access token without a request',
    () async {
      final storage = _MemoryCredentialStorage()
        .._values['accessToken'] = 'saved-access-token';
      var requestCount = 0;
      final api = ApiService(
        credentialStorage: storage,
        client: MockClient((request) async {
          requestCount++;
          return http.Response('{}', 500);
        }),
      );

      expect(await api.restoreSession(), isTrue);
      expect(requestCount, 0);
    },
  );

  test('session restore returns false when no credentials are saved', () async {
    SharedPreferences.setMockInitialValues({});
    var requestCount = 0;
    final api = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        requestCount++;
        return http.Response('{}', 500);
      }),
    );

    expect(await api.restoreSession(), isFalse);
    expect(requestCount, 0);
  });

  test(
    'session restore refreshes when only a refresh token is saved',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = _MemoryCredentialStorage()
        .._values['refreshToken'] = 'saved-refresh-token';
      late http.Request request;
      final api = ApiService(
        credentialStorage: storage,
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': 'restored-access-token',
                'refresh_token': 'rotated-refresh-token',
              },
            }),
            200,
          );
        }),
      );

      expect(await api.restoreSession(), isTrue);
      expect(request.url.toString(), ApiService.refreshTokenUrl);
      expect(jsonDecode(request.body), {
        'refresh_token': 'saved-refresh-token',
      });
      expect(await api.getToken(), 'restored-access-token');
      expect(await api.getRefreshToken(), 'rotated-refresh-token');
    },
  );

  test('Firebase verification sends only the ID token and full name', () async {
    late http.Request request;
    final api = ApiService(
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response('{"success":true}', 200);
      }),
    );

    final response = await api.verifyFirebasePhone(
      idToken: 'firebase-id-token',
      fullName: 'Mobile User',
    );

    expect(response.statusCode, 200);
    expect(request.url.toString(), ApiService.firebaseVerifyUrl);
    expect(request.method, 'POST');
    expect(request.headers['Authorization'], isNull);
    expect(jsonDecode(request.body), {
      'id_token': 'firebase-id-token',
      'full_name': 'Mobile User',
    });
  });

  test(
    'accounts request uses the saved access token as a Bearer token',
    () async {
      final storage = _MemoryCredentialStorage()
        .._values['accessToken'] = 'account-access-token';
      late http.Request request;
      final api = ApiService(
        credentialStorage: storage,
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response('{"data":[]}', 200);
        }),
      );

      final response = await api.getAccounts();

      expect(response.statusCode, 200);
      expect(request.url.toString(), ApiService.accountsUrl);
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer account-access-token');
      expect(request.headers['Accept'], 'application/json');
    },
  );

  test('401 refreshes credentials and retries the original request', () async {
    final storage = _MemoryCredentialStorage()
      .._values['accessToken'] = 'expired-access-token'
      .._values['refreshToken'] = 'saved-refresh-token';
    final accountRequests = <http.Request>[];
    late http.Request refreshRequest;
    final api = ApiService(
      credentialStorage: storage,
      client: MockClient((request) async {
        if (request.url.toString() == ApiService.refreshTokenUrl) {
          refreshRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': 'new-access-token',
                'refresh_token': 'rotated-refresh-token',
              },
            }),
            200,
          );
        }

        accountRequests.add(request);
        if (request.headers['Authorization'] == 'Bearer expired-access-token') {
          return http.Response('{"message":"Unauthenticated"}', 401);
        }
        return http.Response('{"data":[]}', 200);
      }),
    );

    final response = await api.getAccounts();

    expect(response.statusCode, 200);
    expect(refreshRequest.method, 'POST');
    expect(refreshRequest.headers['Authorization'], isNull);
    expect(jsonDecode(refreshRequest.body), {
      'refresh_token': 'saved-refresh-token',
    });
    expect(accountRequests, hasLength(2));
    expect(
      accountRequests.last.headers['Authorization'],
      'Bearer new-access-token',
    );
    expect(await api.getToken(), 'new-access-token');
    expect(await api.getRefreshToken(), 'rotated-refresh-token');
  });

  test(
    '401 without a saved refresh token is returned without refreshing',
    () async {
      final storage = _MemoryCredentialStorage()
        .._values['accessToken'] = 'expired-access-token';
      var requestCount = 0;
      final api = ApiService(
        credentialStorage: storage,
        client: MockClient((request) async {
          requestCount++;
          return http.Response('{"message":"Unauthenticated"}', 401);
        }),
      );

      final response = await api.getAccounts();

      expect(response.statusCode, 401);
      expect(requestCount, 1);
    },
  );

  test('rejected refresh token clears saved credentials', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = _MemoryCredentialStorage()
      .._values['accessToken'] = 'expired-access-token'
      .._values['refreshToken'] = 'expired-refresh-token';
    final api = ApiService(
      credentialStorage: storage,
      client: MockClient((request) async {
        if (request.url.toString() == ApiService.refreshTokenUrl) {
          return http.Response('{"message":"Refresh token expired"}', 401);
        }
        return http.Response('{"message":"Unauthenticated"}', 401);
      }),
    );

    final response = await api.getAccounts();

    expect(response.statusCode, 401);
    expect(await api.getToken(), isNull);
    expect(await api.getRefreshToken(), isNull);
    expect(await api.getUserId(), isNull);
    expect(await api.getRoleId(), isNull);
  });
}

class _MemoryCredentialStorage implements AuthCredentialStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
