import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:budget_book_2026/app/modules/loan_payment/controllers/loan_payment_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('posts a loan payment using selected account and installment', (
    tester,
  ) async {
    http.Request? paymentRequest;
    final controller = LoanPaymentController(
      loan: {
        'uuid': 'loan-uuid',
        'name': 'Home loan',
        'due_amount': '12000.00',
        'installments': {
          'items': [
            {
              'uuid': 'paid-installment-uuid',
              'installment_number': 1,
              'status': 'paid',
            },
            {
              'uuid': 'installment-uuid',
              'installment_number': 2,
              'due_date': '2026-10-15',
              'due_amount': '3000.00',
              'status': 'due',
            },
            {
              'uuid': 'second-installment-uuid',
              'installment_number': 3,
              'due_date': '2026-11-15',
              'due_amount': '3000.00',
              'status': 'upcoming',
            },
          ],
        },
      },
      initialInstallmentUuid: 'installment-uuid',
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/accounts') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'uuid': 'bank-account-uuid',
                      'name': 'Main account',
                      'type': 'bank',
                      'status': 'active',
                    },
                  ],
                },
              }),
              200,
            );
          }
          paymentRequest = request;
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Validation failed.',
              'errors': [],
            }),
            422,
          );
        }),
      ),
    );
    addTearDown(controller.onClose);
    Get.testMode = true;
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox())),
    );

    await controller.loadAccounts();
    controller.amountController.text = '1000';
    controller.paymentDate.value = DateTime(2026, 10, 15);
    controller.referenceController.text = 'PM-EMI-PARTIAL';
    controller.descriptionController.text = 'Partial test payment';

    expect(controller.installments, hasLength(2));
    expect(controller.selectedInstallmentUuid.value, 'installment-uuid');
    expect(await controller.submitPayment(), isFalse);
    expect(paymentRequest?.method, 'POST');
    expect(
      paymentRequest?.url.toString(),
      '${ApiService.loansUrl}/loan-uuid/payments',
    );
    expect(paymentRequest?.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(paymentRequest!.body), {
      'amount': '1000.00',
      'payment_date': '2026-10-15',
      'source_account_uuid': 'bank-account-uuid',
      'installment_uuid': 'installment-uuid',
      'reference': 'PM-EMI-PARTIAL',
      'description': 'Partial test payment',
    });

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    Get.reset();
  });

  test('loads installments for a loan opened from the loan list', () async {
    http.Request? scheduleRequest;
    final controller = LoanPaymentController(
      loan: {'uuid': 'loan-uuid', 'name': 'Home loan'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          scheduleRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'schedule': [
                  {
                    'uuid': 'paid-installment-uuid',
                    'installment_number': 1,
                    'status': 'paid',
                  },
                  {
                    'uuid': 'installment-uuid',
                    'installment_number': 2,
                    'status': 'due',
                  },
                ],
              },
            }),
            200,
          );
        }),
      ),
    );

    await controller.loadInstallments();

    expect(scheduleRequest?.method, 'GET');
    expect(scheduleRequest?.url.path, '/api/v1/loans/loan-uuid/schedule');
    expect(controller.installments, hasLength(1));
    expect(controller.selectedInstallmentUuid.value, 'installment-uuid');
    expect(controller.installmentError.value, isEmpty);
    controller.onClose();
  });

  test('loads installments from a nested schedule response', () async {
    final controller = LoanPaymentController(
      loan: {'uuid': 'loan-uuid', 'name': 'Home loan'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'loan': {
                  'installment_schedule': {
                    'data': [
                      {
                        'uuid': 'installment-uuid',
                        'installment_number': 1,
                        'status': 'due',
                      },
                    ],
                  },
                },
              },
            }),
            200,
          );
        }),
      ),
    );

    await controller.loadInstallments();

    expect(controller.installments, hasLength(1));
    expect(controller.installments.single['uuid'], 'installment-uuid');
    expect(controller.installmentError.value, isEmpty);
    controller.onClose();
  });

  test('finds installment UUIDs in an unfamiliar schedule wrapper', () async {
    final controller = LoanPaymentController(
      loan: {'uuid': 'loan-uuid', 'name': 'Home loan'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'repayment_plan': {
                  'entries': [
                    {
                      'installment_uuid': 'loan-installment-uuid',
                      'installment_number': 4,
                      'due_date': '2026-10-15',
                      'status': 'due',
                    },
                  ],
                },
              },
            }),
            200,
          );
        }),
      ),
    );

    await controller.loadInstallments();

    expect(controller.installments, hasLength(1));
    expect(
      controller.installmentUuid(controller.installments.single),
      'loan-installment-uuid',
    );
    expect(controller.selectedInstallmentUuid.value, 'loan-installment-uuid');
    expect(controller.installmentError.value, isEmpty);
    controller.onClose();
  });

  test('loads installments returned as a top-level list', () async {
    final controller = LoanPaymentController(
      loan: {'uuid': 'loan-uuid', 'name': 'Home loan'},
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode([
              {
                'uuid': 'installment-uuid',
                'installment_number': 1,
                'status': 'due',
              },
            ]),
            200,
          );
        }),
      ),
    );

    await controller.loadInstallments();

    expect(controller.installments, hasLength(1));
    expect(controller.installmentError.value, isEmpty);
    controller.onClose();
  });

  test('retries loan payment with the same idempotency key', () async {
    final requests = <http.Request>[];
    var attempts = 0;
    final apiService = ApiService(
      credentialStorage: _MemoryCredentialStorage(),
      client: MockClient((request) async {
        requests.add(request);
        attempts++;
        if (attempts == 1) {
          throw http.ClientException('Connection closed', request.url);
        }
        return http.Response(jsonEncode({'success': true}), 201);
      }),
    );

    await apiService.postLoanPayment('loan-uuid', {
      'amount': '1000.00',
    }, idempotencyKey: 'loan-payment-request-key');

    expect(requests, hasLength(2));
    expect(requests[0].url, requests[1].url);
    expect(requests[0].url.path, '/api/v1/loans/loan-uuid/payments');
    expect(requests[0].headers['Idempotency-Key'], 'loan-payment-request-key');
    expect(requests[1].headers['Idempotency-Key'], 'loan-payment-request-key');
  });

  testWidgets('rejects invalid and over-balance amounts without posting', (
    tester,
  ) async {
    var postCount = 0;
    final controller = LoanPaymentController(
      loan: {
        'uuid': 'loan-uuid',
        'due_amount': '500.00',
        'installments': [
          {'uuid': 'installment-uuid'},
        ],
      },
      apiService: ApiService(
        credentialStorage: _MemoryCredentialStorage(),
        client: MockClient((request) async {
          postCount++;
          return http.Response(jsonEncode({'success': true}), 201);
        }),
      ),
    );
    controller.amountController.text = '0';
    controller.selectedAccountUuid.value = 'account-uuid';

    Get.testMode = true;
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox())),
    );
    controller.amountController.text = '1000';
    expect(await controller.submitPayment(), isFalse);
    expect(postCount, 0);

    controller.amountController.text = '0';
    expect(await controller.submitPayment(), isFalse);
    expect(postCount, 0);

    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    controller.onClose();
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
