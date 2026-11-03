import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/get_chitfunds/controllers/get_chitfunds_controller.dart';
import 'package:budget_book_2026/app/modules/loan_chitfund/controllers/chitfunds_controller.dart';
import 'package:budget_book_2026/app/modules/loan_chitfund/views/chitfunds_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches the authenticated overall chit summary', () async {
    late http.Request request;
    final controller = ChitfundController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(jsonEncode(_summaryResponse), 200);
        }),
      ),
    );

    await controller.fetchSummary();

    expect(request.method, 'GET');
    expect(request.url.toString(), ApiService.chitsSummaryUrl);
    expect(request.headers['Authorization'], isNotEmpty);
    expect(controller.summary['total_chits'], 2);
    expect(controller.summaryMetrics.map((metric) => metric.label), [
      'Total Chits',
      'Total Chit Value',
      'Monthly Installment Total',
    ]);
    expect(controller.summaryError.value, isEmpty);
  });

  testWidgets('renders summary and chit list data from the APIs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <http.Request>[];
    ApiService createApiService() => ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/chits/summary') {
          return http.Response(jsonEncode(_dashboardSummaryResponse), 200);
        }
        return http.Response(jsonEncode(_chitsResponse), 200);
      }),
    );

    Get.put(ChitfundController(apiService: createApiService()));
    Get.put(GetChitfundsController(apiService: createApiService()));
    addTearDown(Get.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: ChitfundView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      requests.any(
        (request) =>
            request.url.toString() == ApiService.chitsSummaryUrl &&
            request.headers['Authorization']?.isNotEmpty == true,
      ),
      isTrue,
    );
    expect(find.text('Chit fund overview'), findsOneWidget);
    expect(find.text('Chit summary'), findsNothing);
    expect(find.text('TOTAL CHIT VALUE'), findsOneWidget);
    expect(find.text('Total chits'), findsOneWidget);
    expect(find.text('Overdue instalments'), findsOneWidget);
    expect(find.text('Upcoming instalments'), findsOneWidget);
    expect(find.text('Payouts'), findsOneWidget);
    expect(find.text('₹47500.00'), findsOneWidget);
    expect(find.text('Your chit funds'), findsOneWidget);
    expect(find.text('Festival Chit'), findsWidgets);
    expect(find.textContaining('Organizer: City Cooperative'), findsOneWidget);
    await tester.ensureVisible(find.text('Winning payout'));
    expect(find.text('Winning payout'), findsOneWidget);
    expect(find.text('₹12000.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens a chit detail directly from the overall summary', (
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
        if (request.url.path == '/api/v1/chits/summary') {
          return http.Response(jsonEncode(_summaryResponse), 200);
        }
        if (request.url.path == '/api/v1/chits/chit-1/summary') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'summary': {
                  'total_contributed': '12500.00',
                  'remaining_installments': 15,
                },
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode(_chitsResponse), 200);
      }),
    );

    Get.put(ChitfundController(apiService: apiService));
    Get.put(GetChitfundsController(apiService: apiService));
    addTearDown(Get.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: ChitfundView()),
      ),
    );
    await tester.pumpAndSettle();

    final chitName = find.text('Festival Chit').last;
    await tester.ensureVisible(chitName);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(chitName);
    await tester.pumpAndSettle();

    expect(
      requests.any(
        (request) => request.url.path == '/api/v1/chits/chit-1/summary',
      ),
      isTrue,
    );
    expect(find.text('Chit summary'), findsOneWidget);
    expect(find.text('TOTAL CONTRIBUTED'), findsOneWidget);
    expect(find.text('₹12,500.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final Map<String, dynamic> _summaryResponse = {
  'success': true,
  'status': 200,
  'message': 'Chit summary fetched successfully.',
  'data': {
    'total_chits': 2,
    'total_chit_value': '47500.00',
    'monthly_installment_total': '7500.00',
  },
};

final Map<String, dynamic> _dashboardSummaryResponse = {
  ..._summaryResponse,
  'data': {
    ...(_summaryResponse['data'] as Map<String, dynamic>),
    'overdue_installment_count': 1,
    'overdue_installments': [
      {
        'chit_name': 'Festival Chit',
        'installment_amount': '2500.00',
        'due_date': '2026-10-01',
      },
    ],
    'upcoming_installment_count': 1,
    'upcoming_installments': [
      {
        'chit_name': 'Festival Chit',
        'installment_amount': '2500.00',
        'due_date': '2026-11-01',
      },
    ],
    'payouts': [
      {
        'payout_name': 'Winning payout',
        'payout_amount': '12000.00',
        'payout_date': '2026-10-15',
      },
    ],
  },
};

final Map<String, dynamic> _chitsResponse = {
  'success': true,
  'data': {
    'items': [
      {
        'uuid': 'chit-1',
        'name': 'Festival Chit',
        'organizer_name': 'City Cooperative',
        'chit_value': '50000.00',
      },
    ],
    'pagination': {
      'current_page': 1,
      'per_page': 20,
      'total': 1,
      'last_page': 1,
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
