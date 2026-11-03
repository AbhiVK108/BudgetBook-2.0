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

  testWidgets('creates cash account with cash-specific request payload', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    http.Request? request;
    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({
            'success': true,
            'status': 201,
            'message': 'Account created successfully.',
            'data': {
              'uuid': 'cash-account-uuid',
              'name': 'Cash Account',
              'type': 'cash',
              'currency': 'INR',
              'allow_negative': '0',
              'notes': 'Test account created by Postman collection',
              'status': 'active',
              'balance': '0.00',
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
          home: Scaffold(body: Center(child: Text('Accounts'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Get.to(
      () => AddBankAccountView(
        apiService: apiService,
        initialAccountType: 'cash',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Cash Account'), findsOneWidget);
    await tester.tap(find.text('Save Cash Account'));
    await tester.pumpAndSettle();

    expect(request, isNotNull);
    expect(request!.method, 'POST');
    expect(request!.url.toString(), ApiService.accountsUrl);
    expect(request!.headers['Authorization'], isNotEmpty);
    expect(jsonDecode(request!.body), {
      'name': 'Cash Account',
      'type': 'cash',
      'currency': 'INR',
      'opening_balance': '0.00',
      'allow_negative': false,
      'notes': 'Test account created by Postman collection',
    });
    expect(find.text('Accounts'), findsOneWidget);

    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    Get.reset();
    expect(tester.takeException(), isNull);
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
