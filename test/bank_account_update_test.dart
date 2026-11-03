import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/bank_account/controllers/bank_accounts_controller.dart';
import 'package:budget_book_2026/app/modules/bank_account/controllers/transfers_controller.dart';
import 'package:budget_book_2026/app/modules/bank_account/views/bank_accounts_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('updates account using authenticated PUT and refreshes list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <http.Request>[];
    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == Uri.parse(ApiService.transfersUrl).path) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [],
                'pagination': {
                  'current_page': 1,
                  'per_page': 20,
                  'total': 0,
                  'last_page': 1,
                },
              },
            }),
            200,
          );
        }
        if (request.method == 'PUT') {
          return http.Response(
            jsonEncode({
              'success': true,
              'status': 200,
              'message': 'Account updated successfully.',
              'data': {'uuid': 'account-uuid'},
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'uuid': 'account-uuid',
                  'name': 'Updated Bank',
                  'type': 'bank',
                  'institution': 'Updated Institution',
                  'currency': 'INR',
                  'allow_negative': '1',
                  'notes': 'Updated notes',
                  'status': 'active',
                  'balance': '30000.00',
                },
              ],
            },
          }),
          200,
        );
      }),
    );
    final controller = BankAccountsController(apiService: apiService);
    controller.accounts.add(
      const BankAccount(
        uuid: 'account-uuid',
        name: 'Old Bank',
        type: 'bank',
        institution: 'Old Institution',
        currency: 'INR',
        status: 'active',
        createdAt: null,
        balance: '30000.00',
        allowNegative: false,
        notes: null,
      ),
    );
    Get.put(controller);
    Get.put(TransfersController(apiService: apiService));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => GetMaterialApp(
          home: const BankAccountsView(),
          getPages: [
            GetPage(
              name: '/add-bank-account',
              page: () => Scaffold(
                body: Center(
                  child: Text('Add type ${Get.arguments['accountType']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add bank'), findsOneWidget);
    expect(find.text('Add cash'), findsOneWidget);
    await tester.tap(find.text('Add cash'));
    await tester.pumpAndSettle();
    expect(find.text('Add type cash'), findsOneWidget);
    Get.back();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cash (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No cash accounts yet.'), findsOneWidget);
    await tester.tap(find.text('All (1)'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Edit account'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final updateRequest = requests.singleWhere(
      (request) => request.method == 'PUT',
    );
    expect(
      updateRequest.url.toString(),
      '${ApiService.accountsUrl}/account-uuid',
    );
    expect(updateRequest.headers['Authorization'], isNotEmpty);
    expect(jsonDecode(updateRequest.body), {
      'name': 'Updated Bank',
      'type': 'bank',
      'institution': 'Updated Institution',
      'currency': 'INR',
      'allow_negative': true,
      'notes': 'Updated notes',
    });
    expect(requests.last.method, 'GET');
    expect(controller.accounts.single.name, 'Updated Bank');

    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    Get.reset();
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
