import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/bank_account/views/add_bank_account_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('submits the authenticated bank account request', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = _MemoryCredentialStorage()
      ..values['accessToken'] = 'saved-access-token'
      ..values['refreshToken'] = 'saved-refresh-token';
    final accountRequests = <http.Request>[];
    final api = ApiService(
      credentialStorage: storage,
      client: MockClient((incoming) async {
        if (incoming.url.toString() == ApiService.refreshTokenUrl) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'access_token': 'refreshed-access-token'},
            }),
            200,
          );
        }

        accountRequests.add(incoming);
        if (accountRequests.length == 1) {
          return http.Response('{"message":"Unauthenticated"}', 401);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'status': 201,
            'message': 'Account created successfully.',
            'data': {
              'uuid': 'created-account-uuid',
              'name': 'Postman Test Bank',
            },
          }),
          201,
        );
      }),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(
          home: Scaffold(body: Center(child: Text('Account list'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    Get.to(() => AddBankAccountView(apiService: api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Bank Account'));
    await tester.pumpAndSettle();

    expect(accountRequests, hasLength(2));
    final request = accountRequests.last;
    expect(request.method, 'POST');
    expect(request.url.toString(), ApiService.accountsUrl);
    expect(request.headers['Authorization'], 'Bearer refreshed-access-token');
    expect(request.headers['Content-Type'], 'application/json');
    final idempotencyKey = request.headers['Idempotency-Key'];
    expect(idempotencyKey, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(accountRequests.first.headers['Idempotency-Key'], idempotencyKey);
    expect(jsonDecode(request.body), {
      'name': 'Postman Test Bank',
      'type': 'bank',
      'institution': 'Postman test data',
      'currency': 'INR',
      'opening_balance': '30000.00',
      'opening_balance_date': '2026-10-14',
      'allow_negative': false,
      'notes': 'Test account created by Postman collection',
    });
    expect(find.text('Account list'), findsOneWidget);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
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
