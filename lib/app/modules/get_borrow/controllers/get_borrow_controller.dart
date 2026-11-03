import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:budget_book_2026/app/core/constants/api_endpoints.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class GetBorrowController extends GetxController {
  GetBorrowController({
    ApiService? apiService,
    Map<String, dynamic>? initialBorrow,
  }) : apiService = apiService ?? ApiService(),
       _initialBorrow = initialBorrow;

  final ApiService apiService;
  final Map<String, dynamic>? _initialBorrow;
  final String url = ApiEndpoints.legacyCreditUrl;

  final isLoading = false.obs;
  final isLoadingRepayments = false.obs;
  final borrows = <Map<String, dynamic>>[].obs;
  final selectedBorrow = <String, dynamic>{}.obs;
  final errorMessage = ''.obs;
  final repayments = <Map<String, dynamic>>[].obs;
  final repaymentError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final argument = _initialBorrow ?? Get.arguments;
    if (argument is Map) {
      selectedBorrow.addAll(Map<String, dynamic>.from(argument));
    }
    fetchBorrows();
    fetchRepayments();
  }

  // ================= RECORD ID =================

  dynamic _recordId(Map<String, dynamic> record) {
    return record['id'] ??
        record['creditId'] ??
        record['credit_id'] ??
        record['uuid'] ??
        record['borrowing_uuid'];
  }

  Future<void> fetchRepayments() async {
    final uuidValue =
        selectedBorrow['uuid'] ?? selectedBorrow['borrowing_uuid'];
    final uuid = uuidValue?.toString().trim();
    if (uuid == null || uuid.isEmpty) {
      repaymentError.value = 'This borrowing record is missing its UUID.';
      return;
    }

    try {
      isLoadingRepayments.value = true;
      repaymentError.value = '';
      final response = await apiService.getBorrowingRepayments(uuid);
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
      debugPrint('Fetch borrowing repayment history error: ${error.message}');
      repaymentError.value = error.message;
    } catch (error, stackTrace) {
      debugPrint('Fetch borrowing repayment history error: $error');
      debugPrintStack(stackTrace: stackTrace);
      repaymentError.value = 'Unable to load repayment history. Please retry.';
    } finally {
      isLoadingRepayments.value = false;
    }
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

  Map<String, dynamic>? _findById(dynamic id) {
    if (id == null) return null;

    for (final record in borrows) {
      if (_recordId(record)?.toString() == id.toString()) {
        return record;
      }
    }

    return null;
  }

  // ================= FETCH BORROW RECORDS =================

  Future<void> fetchBorrows() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final previousId = _recordId(selectedBorrow);

      final response = await apiService.get(url);

      debugPrint('Get borrow status: ${response.statusCode}');
      debugPrint('Get borrow response: ${response.body}');

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        errorMessage.value = 'Invalid response received from server.';
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? (decoded['message'] ?? 'Failed to fetch borrow details.')
                  .toString()
            : 'Failed to fetch borrow details.';

        errorMessage.value = response.statusCode == 401
            ? 'Session expired. Please login again.'
            : message;

        // Get.snackbar('Error', errorMessage.value);
        return;
      }

      dynamic records;

      if (decoded is List) {
        records = decoded;
      } else if (decoded is Map) {
        records =
            decoded['data'] ??
            decoded['credits'] ??
            decoded['credit'] ??
            decoded['records'];
      }

      // The API response contains a list inside "data".
      if (records is Map) {
        if (records['data'] is List) {
          records = records['data'];
        } else {
          records = [records];
        }
      }

      records ??= <dynamic>[];

      if (records is! List) {
        throw const FormatException(
          'Borrow records are missing from the response.',
        );
      }

      borrows.assignAll(
        records
            .whereType<Map>()
            .map((record) => Map<String, dynamic>.from(record))
            .toList(),
      );

      // Restore the selected record if possible.
      final argument = _initialBorrow ?? Get.arguments;

      if (argument is Map) {
        final passedRecord = Map<String, dynamic>.from(argument);
        final matchedRecord = _findById(_recordId(passedRecord));

        selectedBorrow.assignAll(matchedRecord ?? passedRecord);
      } else {
        final matchedRecord = _findById(previousId);

        if (matchedRecord != null) {
          selectedBorrow.assignAll(matchedRecord);
        } else if (borrows.isNotEmpty) {
          selectedBorrow.assignAll(borrows.first);
        } else {
          selectedBorrow.clear();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch borrow details error: $e');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage.value = 'Unable to load borrow details.';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // ================= SELECT RECORD =================

  void selectBorrow(Map<String, dynamic> borrow) {
    selectedBorrow.assignAll(borrow);
  }

  // ================= DISPLAY FIELDS =================

  String get personName =>
      (selectedBorrow['lender_name'] ??
              selectedBorrow['person_name'] ??
              selectedBorrow['givenTo'] ??
              '')
          .toString();

  String get phone => (selectedBorrow['phone'] ?? '').toString();

  String get amount =>
      (selectedBorrow['principal_amount'] ?? selectedBorrow['amount'] ?? '0')
          .toString();

  String get interest =>
      (selectedBorrow['fixed_interest_amount'] ??
              selectedBorrow['interest_amount'] ??
              selectedBorrow['rateOfInterest'] ??
              '0')
          .toString();

  String get interestAmount =>
      (selectedBorrow['fixed_interest_amount'] ??
              selectedBorrow['interestAmount'] ??
              '0')
          .toString();

  String get paidAmount =>
      (selectedBorrow['principal_repaid'] ??
              selectedBorrow['paidAmount'] ??
              '0')
          .toString();

  String get dueAmount =>
      (selectedBorrow['total_outstanding'] ??
              selectedBorrow['principal_outstanding'] ??
              selectedBorrow['dueAmount'] ??
              '0')
          .toString();

  String get receiveDate =>
      (selectedBorrow['borrowing_date'] ?? selectedBorrow['givenDate'] ?? '')
          .toString();

  String get returnDate =>
      (selectedBorrow['expected_repayment_date'] ??
              selectedBorrow['returnDate'] ??
              '')
          .toString();

  String get description =>
      (selectedBorrow['notes'] ?? selectedBorrow['description'] ?? '')
          .toString();

  void applyRepaymentAgreement(Map<String, dynamic> agreement) {
    selectedBorrow.assignAll({...selectedBorrow, ...agreement});
  }

  // ================= UPDATE BORROW =================

  Future<bool> updateBorrow({
    required String personName,
    required String phone,
    required String amount,
    required String interest,
    required String receiveDate,
    required String returnDate,
    required String description,
  }) async {
    final id = _recordId(selectedBorrow);

    if (id == null) {
      Get.snackbar('Unable to update', 'The selected record has no ID.');
      return false;
    }

    final amountValue = double.tryParse(amount.trim());
    final interestValue = double.tryParse(interest.trim());
    final givenDateValue = DateTime.tryParse(receiveDate.trim());
    final returnDateValue = DateTime.tryParse(returnDate.trim());

    if (personName.trim().isEmpty ||
        !RegExp(r'^[0-9]{10}$').hasMatch(phone.trim()) ||
        amountValue == null ||
        !amountValue.isFinite ||
        amountValue <= 0 ||
        interestValue == null ||
        !interestValue.isFinite ||
        interestValue < 0 ||
        givenDateValue == null ||
        returnDateValue == null ||
        returnDateValue.isBefore(givenDateValue)) {
      Get.snackbar('Invalid details', 'Check the borrow details and dates.');
      return false;
    }

    try {
      isLoading.value = true;

      // Field names match the Credit API.
      final body = <String, dynamic>{
        'givenTo': personName.trim(),
        'phone': phone.trim(),
        'amount': amountValue,
        'givenDate': _formatDate(givenDateValue),
        'rateOfInterest': interestValue,
        'returnDate': _formatDate(returnDateValue),
        'description': description.trim(),
      };

      debugPrint('Update borrow URL: $url/$id');
      debugPrint('Update borrow body: ${jsonEncode(body)}');

      final response = await apiService.put('$url/$id', body);

      debugPrint('Update borrow status: ${response.statusCode}');
      debugPrint('Update borrow response: ${response.body}');

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        Get.snackbar('Update failed', 'Invalid server response.');
        return false;
      }

      final bool success =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded is Map &&
          decoded['status']?.toString().toLowerCase() == 'success';

      if (!success) {
        final message = decoded is Map
            ? (decoded['message'] ?? 'Unable to update borrow details.')
                  .toString()
            : 'Unable to update borrow details.';

        Get.snackbar('Update failed', message);
        return false;
      }

      selectedBorrow.addAll(body);

      await fetchBorrows();

      Get.snackbar('Success', 'Borrow details updated.');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Update borrow error: $e');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar('Error', 'Unable to update borrow details.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ================= DATE FORMAT =================

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
