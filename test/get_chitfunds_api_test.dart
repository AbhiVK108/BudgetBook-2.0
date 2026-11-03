import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/get_chitfunds/controllers/get_chitfunds_controller.dart';
import 'package:budget_book_2026/app/modules/get_chitfunds/views/get_chitfunds_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches authenticated chit pages and parses pagination', () async {
    final requests = <http.Request>[];
    final controller = GetChitfundsController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(jsonEncode(_chitsResponse(page)), 200);
        }),
      ),
    );

    await controller.fetchChits();

    expect(requests.first.method, 'GET');
    expect(
      requests.first.url.toString(),
      '${ApiService.chitsUrl}?page=1&per_page=20',
    );
    expect(requests.first.headers['Authorization'], isNotEmpty);
    expect(controller.chits, hasLength(1));
    expect(controller.valueFor(controller.chits.first, ['name']), 'Festival Chit');
    expect(controller.totalRecords.value, 2);
    expect(controller.hasMore, isTrue);

    await controller.loadNextPage();

    expect(requests.last.url.queryParameters, {'page': '2', 'per_page': '20'});
    expect(controller.chits, hasLength(2));
    expect(controller.currentPage.value, 2);
    expect(controller.hasMore, isFalse);
    expect(controller.loadMoreError.value, isEmpty);
  });

  testWidgets('renders chit details returned by the v1 API', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(
      GetChitfundsController(
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((_) async {
            return http.Response(jsonEncode(_chitsResponse(1, lastPage: 1)), 200);
          }),
        ),
      ),
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: GetChitfundsView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Festival Chit'), findsOneWidget);
    expect(find.text('Organizer: City Cooperative'), findsOneWidget);
    expect(find.text('₹50000.00'), findsOneWidget);
    expect(find.text('₹2500.00'), findsOneWidget);
    expect(find.textContaining('20 instalments'), findsOneWidget);
    expect(find.textContaining('Starts 1 Jan 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });

  testWidgets('opens and renders the selected chit summary', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <http.Request>[];
    Get.put(
      GetChitfundsController(
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((request) async {
            requests.add(request);
            if (request.url.path.endsWith('/summary')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'summary': {
                      'total_contributed': '12500.00',
                      'remaining_installments': 15,
                      'next_due_date': '2026-03-01',
                    },
                  },
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode(_chitsResponse(1, lastPage: 1)),
              200,
            );
          }),
        ),
      ),
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: GetChitfundsView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Festival Chit'));
    await tester.pumpAndSettle();

    expect(
      requests.any(
        (request) =>
            request.url.path == '/api/v1/chits/chit-1/summary' &&
            request.headers['Authorization'] == 'Bearer test-access-token',
      ),
      isTrue,
    );
    expect(find.text('Chit summary'), findsOneWidget);
    expect(find.text('TOTAL CONTRIBUTED'), findsOneWidget);
    expect(find.text('₹12,500.00'), findsOneWidget);
    expect(find.text('REMAINING INSTALLMENTS'), findsOneWidget);
    expect(find.text('1 Mar 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}

Map<String, dynamic> _chitsResponse(int page, {int lastPage = 2}) => {
  'success': true,
  'status': 200,
  'message': 'Chit records fetched successfully.',
  'data': {
    'items': [
      {
        'uuid': 'chit-$page',
        'name': page == 1 ? 'Festival Chit' : 'Family Chit',
        'organizer_name': 'City Cooperative',
        'chit_value': '50000.00',
        'installment_amount': '2500.00',
        'installment_count': 20,
        'start_date': '2026-01-01',
        'first_due_date': '2026-02-01',
        'chit_type': 'auction',
        'status': 'active',
      },
    ],
    'pagination': {
      'current_page': page,
      'per_page': 20,
      'total': 2,
      'last_page': lastPage,
    },
  },
};

class _MemoryCredentialStorage implements AuthCredentialStorage {
  @override
  Future<String?> read(String key) async =>
      key == 'accessToken' ? 'test-access-token' : null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
