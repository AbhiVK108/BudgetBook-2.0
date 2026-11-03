import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/postchitfund/controllers/postchitfund_controller.dart';
import 'package:budget_book_2026/app/modules/postchitfund/views/postchitfund_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('posts chit creation with v1 payload and account UUID', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final controller = PostchitfundController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET' &&
              request.url.path.endsWith('/accounts')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'bank-account-uuid',
                      'name': 'Everyday account',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (request.method == 'POST' &&
              request.url.toString() == ApiService.chitsUrl) {
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Chit created successfully.',
                'data': {'uuid': 'chit-uuid'},
              }),
              201,
            );
          }
          return http.Response('Unexpected request', 404);
        }),
      ),
    );
    Get.testMode = true;
    addTearDown(Get.reset);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) {
          Get.put(controller);
          return const GetMaterialApp(home: PostchitfundView());
        },
      ),
    );
    await tester.pumpAndSettle();
    controller.nameController.text = 'Postman monthly chit';
    controller.organizerNameController.text = 'Example organizer';
    controller.groupReferenceController.text = 'PM-GROUP-1';
    controller.memberReferenceController.text = 'PM-TICKET-1';
    controller.chitValueController.text = '12000';
    controller.installmentAmountController.text = '1000';
    controller.installmentCountController.text = '12';
    controller.startDate.value = DateTime(2026, 10, 1);
    controller.firstDueDate.value = DateTime(2026, 10, 31);
    controller.selectedContributionAccountUuid.value = 'bank-account-uuid';
    controller.notesController.text = 'Phase 6 Postman test';

    await controller.postChit();

    final request = requests.singleWhere((item) => item.method == 'POST');
    expect(request.url.toString(), ApiService.chitsUrl);
    expect(request.headers['Authorization'], isNotEmpty);
    expect(request.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(request.body), {
      'name': 'Postman monthly chit',
      'organizer_name': 'Example organizer',
      'group_reference': 'PM-GROUP-1',
      'member_reference': 'PM-TICKET-1',
      'chit_value': '12000.00',
      'installment_amount': '1000.00',
      'installment_count': 12,
      'currency': 'INR',
      'start_date': '2026-10-01',
      'first_due_date': '2026-10-31',
      'contribution_account_uuid': 'bank-account-uuid',
      'status': 'active',
      'notes': 'Phase 6 Postman test',
      'chit_type': 'auction',
    });
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
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
