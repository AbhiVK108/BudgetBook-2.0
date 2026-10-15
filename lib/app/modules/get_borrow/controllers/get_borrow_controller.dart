
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:budget_book_2026/app/core/services/api_services.dart';

class GetBorrowController extends GetxController {
  final ApiService apiService = ApiService();

  final String url = 'https://budgetbook.in/api/api/credit';

  final isLoading = false.obs;
  final borrows = <Map<String, dynamic>>[].obs;
  final selectedBorrow = <String, dynamic>{}.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBorrows();
  }

  // ================= RECORD ID =================

  dynamic _recordId(Map<String, dynamic> record) {
    return record['id'] ??
        record['creditId'] ??
        record['credit_id'];
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

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final message = decoded is Map
            ? (decoded['message'] ??
                    'Failed to fetch borrow details.')
                .toString()
            : 'Failed to fetch borrow details.';

        errorMessage.value = response.statusCode == 401
            ? 'Session expired. Please login again.'
            : message;

        Get.snackbar('Error', errorMessage.value);
        return;
      }

      dynamic records;

      if (decoded is List) {
        records = decoded;
      } else if (decoded is Map) {
        records = decoded['data'] ??
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
      final argument = Get.arguments;

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
      (selectedBorrow['givenTo'] ?? '').toString();

  String get phone =>
      (selectedBorrow['phone'] ?? '').toString();

  String get amount =>
      (selectedBorrow['amount'] ?? '0').toString();

  String get interest =>
      (selectedBorrow['rateOfInterest'] ?? '0').toString();

  String get interestAmount =>
      (selectedBorrow['interestAmount'] ?? '0').toString();

  String get paidAmount =>
      (selectedBorrow['paidAmount'] ?? '0').toString();

  String get dueAmount =>
      (selectedBorrow['dueAmount'] ?? '0').toString();

  String get receiveDate =>
      (selectedBorrow['givenDate'] ?? '').toString();

  String get returnDate =>
      (selectedBorrow['returnDate'] ?? '').toString();

  String get description =>
      (selectedBorrow['description'] ?? '').toString();

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
      Get.snackbar(
        'Unable to update',
        'The selected record has no ID.',
      );
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
      Get.snackbar(
        'Invalid details',
        'Check the borrow details and dates.',
      );
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

      final bool success = response.statusCode >= 200 &&
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
