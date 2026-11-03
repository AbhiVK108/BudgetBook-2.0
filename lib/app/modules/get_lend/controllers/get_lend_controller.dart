import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:budget_book_2026/app/core/services/api_services.dart';

class GetLendController extends GetxController {
  GetLendController({ApiService? apiService, Map<String, dynamic>? initialLend})
    : apiService = apiService ?? ApiService(),
      _initialLend = initialLend;

  final ApiService apiService;
  final Map<String, dynamic>? _initialLend;

  final isLoading = false.obs;
  final selectedLend = <String, dynamic>{}.obs;
  final errorMessage = ''.obs;
  final repayments = <Map<String, dynamic>>[].obs;
  final isLoadingRepayments = false.obs;
  final repaymentError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final argument = _initialLend ?? Get.arguments;
    if (argument is Map) {
      selectedLend.addAll(Map<String, dynamic>.from(argument));
    }
    fetchLends();
    fetchRepayments();
  }

  Future<void> refreshDetails() async {
    await Future.wait([fetchLends(), fetchRepayments()]);
  }

  Future<void> fetchRepayments() async {
    final lendingUuid = _lendingUuid(selectedLend);
    if (lendingUuid == null) {
      repaymentError.value = 'This lending record is missing its UUID.';
      return;
    }

    try {
      isLoadingRepayments.value = true;
      repaymentError.value = '';

      final response = await apiService.getLendingRepayments(lendingUuid);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Failed to fetch repayment history (${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned invalid repayment history.',
        );
      }
      if (decoded is! Map || decoded['success'] != true) {
        throw FormatException(
          _responseMessage(response.body) ??
              'The repayment history response was invalid.',
        );
      }

      final items = _repaymentsFromResponse(decoded);
      if (items == null) {
        throw const FormatException(
          'The repayment history response was invalid.',
        );
      }
      repayments.assignAll(items);
    } on FormatException catch (error) {
      debugPrint('Fetch lending repayment history error: ${error.message}');
      repaymentError.value = error.message;
    } catch (error, stackTrace) {
      debugPrint('Fetch lending repayment history error: $error');
      debugPrintStack(stackTrace: stackTrace);
      repaymentError.value = 'Unable to load repayment history. Please retry.';
    } finally {
      isLoadingRepayments.value = false;
    }
  }

  Future<void> fetchLends() async {
    final lendingUuid = _lendingUuid(selectedLend);
    if (lendingUuid == null) {
      errorMessage.value = 'This lending record is missing its UUID.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await apiService.getLendingByUuid(lendingUuid);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(response.body) ??
              'Failed to fetch lending details (${response.statusCode}).',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned invalid lending details.',
        );
      }
      if (decoded is! Map || decoded['success'] != true) {
        throw FormatException(
          _responseMessage(response.body) ??
              'The lending response was invalid.',
        );
      }

      final detail = _detailFromResponse(decoded);
      if (detail == null) {
        throw const FormatException('The lending response was invalid.');
      }

      selectedLend.addAll(detail);
    } on FormatException catch (error) {
      debugPrint('Fetch lending details error: ${error.message}');
      errorMessage.value = error.message;
    } catch (e, stackTrace) {
      debugPrint('Fetch lending details error: $e');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage.value = 'Unable to load lending details. Please retry.';
    } finally {
      isLoading.value = false;
    }
  }

  String get personName =>
      (selectedLend['borrower_name'] ??
              selectedLend['person_name'] ??
              selectedLend['receiveFrom'] ??
              selectedLend['receive_from'] ??
              selectedLend['givenTo'] ??
              selectedLend['given_to'] ??
              selectedLend['full_name'] ??
              selectedLend['person'] ??
              selectedLend['name'] ??
              '')
          .toString();

  String get phone => (selectedLend['phone'] ?? '').toString();

  String get amount =>
      (selectedLend['principal_amount'] ?? selectedLend['amount'] ?? '0')
          .toString();

  String get interest =>
      (selectedLend['fixed_interest_amount'] ??
              selectedLend['interest_received'] ??
              selectedLend['rateOfInterest'] ??
              selectedLend['rate_of_interest'] ??
              selectedLend['interest'] ??
              '0')
          .toString();

  String get receiveDate =>
      (selectedLend['lending_date'] ??
              selectedLend['receiveDate'] ??
              selectedLend['receive_date'] ??
              selectedLend['giveDate'] ??
              selectedLend['give_date'] ??
              selectedLend['transaction_date'] ??
              '')
          .toString();

  String get returnDate =>
      (selectedLend['expected_repayment_date'] ??
              selectedLend['returnDate'] ??
              selectedLend['return_date'] ??
              selectedLend['repaymentDate'] ??
              selectedLend['repayment_date'] ??
              '')
          .toString();

  String get description =>
      (selectedLend['notes'] ?? selectedLend['description'] ?? '').toString();

  double get amountValue => double.tryParse(amount) ?? 0;

  double get interestValue => double.tryParse(interest) ?? 0;

  void applyRepaymentAgreement(Map<String, dynamic> agreement) {
    selectedLend.assignAll({...selectedLend, ...agreement});
  }

  String? _lendingUuid(Map<String, dynamic> record) {
    final value = record['uuid'] ?? record['lending_uuid'];
    final uuid = value?.toString().trim();
    return uuid == null || uuid.isEmpty ? null : uuid;
  }

  Map<String, dynamic>? _detailFromResponse(Map<dynamic, dynamic> response) {
    dynamic data = response['data'];
    while (data is Map) {
      if (data['lending'] is Map) {
        data = data['lending'];
      } else if (data['item'] is Map) {
        data = data['item'];
      } else if (data['data'] is Map) {
        data = data['data'];
      } else {
        return Map<String, dynamic>.from(data);
      }
    }
    return null;
  }

  List<Map<String, dynamic>>? _repaymentsFromResponse(
    Map<dynamic, dynamic> response,
  ) {
    dynamic data = response['data'] ?? response['repayments'];
    while (data is Map) {
      final items =
          data['items'] ?? data['repayments'] ?? data['repayment_history'];
      if (items is List) {
        return items.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
      if (data['data'] is Map || data['data'] is List) {
        data = data['data'];
      } else {
        return null;
      }
    }
    if (data is List) {
      return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    return null;
  }

  String? _responseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
