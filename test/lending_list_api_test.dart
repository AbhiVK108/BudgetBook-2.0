import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/lend_and_borrow/controllers/lend_controller.dart';
import 'package:budget_book_2026/app/modules/lend_and_borrow/views/lend_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches authenticated lending pages and parses pagination', () async {
    final requests = <http.Request>[];
    final controller = LendController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(jsonEncode(_lendingResponse(page)), 200);
        }),
      ),
    );

    await controller.fetchLends();

    expect(requests.first.method, 'GET');
    expect(
      requests.first.url.toString(),
      '${ApiService.lendingUrl}?page=1&per_page=20',
    );
    expect(requests.first.headers['Authorization'], isNotEmpty);
    expect(controller.lends, hasLength(1));
    expect(controller.lendName(controller.lends.first), 'Jamie Example');
    expect(controller.totalAmount, 5000);
    expect(controller.paidAmount, 1000);
    expect(controller.dueAmount, 4000);
    expect(controller.totalRecords.value, 2);
    expect(controller.hasMore, isTrue);

    await controller.loadNextPage();

    expect(requests.last.url.queryParameters, {'page': '2', 'per_page': '20'});
    expect(controller.lends, hasLength(2));
    expect(controller.currentPage.value, 2);
    expect(controller.hasMore, isFalse);
    expect(controller.loadMoreError.value, isEmpty);
  });

  test('fetches the authenticated lending summary and parses totals', () async {
    late http.Request request;
    final controller = LendController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(jsonEncode(_lendingSummaryResponse), 200);
        }),
      ),
    );

    await controller.fetchLendingSummary();

    expect(request.method, 'GET');
    expect(request.url.toString(), ApiService.lendingSummaryUrl);
    expect(request.headers['Authorization'], isNotEmpty);
    expect(controller.lendingSummary, hasLength(1));
    expect(controller.lendingSummary.single.currency, 'INR');
    expect(controller.lendingSummary.single.principalTotal, 1000);
    expect(controller.lendingSummary.single.principalRecovered, 450);
    expect(controller.lendingSummary.single.principalOutstanding, 550);
    expect(controller.lendingSummary.single.interestReceived, 50);
    expect(controller.lendingSummary.single.interestOutstanding, 0);
    expect(controller.lendingSummary.single.totalOutstanding, 550);
    expect(controller.activeRecordCount.value, 1);
    expect(controller.overdueRecordCount.value, 0);
    expect(controller.summaryError.value, isEmpty);
  });

  testWidgets('renders lending list from the API response', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(
      LendController(
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((request) async {
            if (request.url.path.endsWith('/summary')) {
              return http.Response(jsonEncode(_lendingSummaryResponse), 200);
            }
            final page = int.parse(request.url.queryParameters['page']!);
            return http.Response(
              jsonEncode(_lendingResponse(page, lastPage: 1)),
              200,
            );
          }),
        ),
      ),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: LendView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lend'), findsOneWidget);
    expect(find.text('Lending summary'), findsOneWidget);
    expect(find.text('Active records'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('INR'), findsOneWidget);
    expect(find.text('Recovered'), findsOneWidget);
    expect(find.text('Total due'), findsOneWidget);
    expect(find.text('550.00'), findsNWidgets(2));
    expect(find.text('Jamie Example'), findsOneWidget);
    expect(find.text('Principal: ₹5000'), findsOneWidget);
    expect(find.text('Lent: 2026-10-01'), findsOneWidget);
    expect(find.text('₹4000'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(Get.find<LendController>().totalRecords.value, 2);
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}

Map<String, dynamic> _lendingResponse(int page, {int lastPage = 2}) => {
  'success': true,
  'status': 200,
  'message': 'Lending records fetched successfully.',
  'data': {
    'items': [
      {
        'uuid': 'lending-$page',
        'borrower_name': page == 1 ? 'Jamie Example' : 'Taylor Example',
        'phone': '9876543210',
        'principal_amount': page == 1 ? '5000.00' : '2000.00',
        'paid_amount': page == 1 ? '1000.00' : '0.00',
        'due_amount': page == 1 ? '4000.00' : '2000.00',
        'interest': '0.00',
        'transaction_date': '2026-10-01',
        'return_date': '2026-11-01',
        'description': 'Personal lending',
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

final Map<String, dynamic> _lendingSummaryResponse = {
  'success': true,
  'status': 200,
  'message': 'Lending summary fetched successfully.',
  'data': {
    'type': 'lending',
    'totals_by_currency': [
      {
        'currency': 'INR',
        'principal_total': '1000.00',
        'principal_recovered': '450.00',
        'principal_outstanding': '550.00',
        'interest_received': '50.00',
        'interest_outstanding': '0.00',
        'total_outstanding': '550.00',
      },
    ],
    'active_record_count': 1,
    'overdue_record_count': 0,
    'upcoming_expected_repayments': [],
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
