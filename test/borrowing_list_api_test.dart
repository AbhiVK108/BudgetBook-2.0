import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/lend_and_borrow/controllers/borrow_controller.dart';
import 'package:budget_book_2026/app/modules/lend_and_borrow/views/borrow_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches borrowing pages and parses pagination', () async {
    final requests = <http.Request>[];
    final controller = BorrowController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          requests.add(request);
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(jsonEncode(_borrowingResponse(page)), 200);
        }),
      ),
    );

    await controller.fetchBorrows();

    expect(requests.first.method, 'GET');
    expect(
      requests.first.url.toString(),
      '${ApiService.borrowingUrl}?page=1&per_page=20',
    );
    expect(requests.first.headers['Authorization'], isNotEmpty);
    expect(controller.borrows, hasLength(1));
    expect(controller.nameFor(controller.borrows.first), 'Postman lender');
    expect(controller.amountFor(controller.borrows.first), 2000);
    expect(controller.totalRecords.value, 2);
    expect(controller.hasMore, isTrue);

    await controller.loadNextPage();

    expect(requests.last.url.queryParameters, {'page': '2', 'per_page': '20'});
    expect(controller.borrows, hasLength(2));
    expect(controller.currentPage.value, 2);
    expect(controller.hasMore, isFalse);
    expect(controller.loadMoreError.value, isEmpty);
  });

  test('fetches the borrowing summary and parses totals', () async {
    late http.Request request;
    final controller = BorrowController(
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(jsonEncode(_borrowingSummaryResponse), 200);
        }),
      ),
    );

    await controller.fetchBorrowingSummary();

    expect(request.method, 'GET');
    expect(request.url.toString(), '${ApiService.borrowingUrl}/summary');
    expect(request.headers['Authorization'], isNotEmpty);
    expect(controller.borrowingSummary, hasLength(1));
    expect(controller.borrowingSummary.single.currency, 'INR');
    expect(controller.borrowingSummary.single.principalTotal, 2000);
    expect(controller.borrowingSummary.single.principalRepaid, 475);
    expect(controller.borrowingSummary.single.principalOutstanding, 1525);
    expect(controller.borrowingSummary.single.interestPaid, 25);
    expect(controller.borrowingSummary.single.interestOutstanding, 0);
    expect(controller.borrowingSummary.single.totalOutstanding, 1525);
    expect(controller.activeRecordCount.value, 1);
    expect(controller.overdueRecordCount.value, 0);
    expect(controller.summaryError.value, isEmpty);
  });

  testWidgets('renders borrowing list and summary from the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(
      BorrowController(
        apiService: ApiService(
          credentialStorage: _MemoryCredentialStorage(),
          client: MockClient((request) async {
            if (request.url.path.endsWith('/summary')) {
              return http.Response(jsonEncode(_borrowingSummaryResponse), 200);
            }
            final page = int.parse(request.url.queryParameters['page']!);
            return http.Response(
              jsonEncode(_borrowingResponse(page, lastPage: 1)),
              200,
            );
          }),
        ),
      ),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: BorrowView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Borrow'), findsOneWidget);
    expect(find.text('Borrowing summary'), findsOneWidget);
    expect(find.text('Active records'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('INR'), findsOneWidget);
    expect(find.text('Repaid'), findsOneWidget);
    expect(find.text('Total due'), findsOneWidget);
    expect(find.text('1525.00'), findsNWidgets(2));
    expect(find.text('Postman lender'), findsOneWidget);
    expect(find.textContaining('Principal: ₹2000'), findsOneWidget);
    expect(Get.find<BorrowController>().totalRecords.value, 2);
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}

Map<String, dynamic> _borrowingResponse(int page, {int lastPage = 2}) => {
  'success': true,
  'status': 200,
  'message': 'Borrowing records fetched successfully.',
  'data': {
    'items': [
      {
        'uuid': 'borrowing-$page',
        'lender_name': page == 1 ? 'Postman lender' : 'Other lender',
        'lender_phone': '9876543210',
        'principal_amount': page == 1 ? '2000.00' : '1000.00',
        'principal_repaid': page == 1 ? '475.00' : '0.00',
        'principal_outstanding': page == 1 ? '1525.00' : '1000.00',
        'interest_paid': '25.00',
        'interest_outstanding': '0.00',
        'total_outstanding': page == 1 ? '1525.00' : '1000.00',
        'borrowing_date': '2026-10-01',
        'expected_repayment_date': '2026-12-01',
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

final Map<String, dynamic> _borrowingSummaryResponse = {
  'success': true,
  'status': 200,
  'message': 'Borrowing summary fetched successfully.',
  'data': {
    'type': 'borrowing',
    'totals_by_currency': [
      {
        'currency': 'INR',
        'principal_total': '2000.00',
        'principal_repaid': '475.00',
        'principal_outstanding': '1525.00',
        'interest_paid': '25.00',
        'interest_outstanding': '0.00',
        'total_outstanding': '1525.00',
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
