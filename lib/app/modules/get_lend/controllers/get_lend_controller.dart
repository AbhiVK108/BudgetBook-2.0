import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:budget_book_2026/app/core/services/api_services.dart';

class GetLendController extends GetxController {
  final ApiService apiService = ApiService();
  final String url = 'https://budgetbook.in/api/api/debit';

  final isLoading = false.obs;
  final lends = <Map<String, dynamic>>[].obs;
  final selectedLend = <String, dynamic>{}.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLends();
  }

  Future<void> fetchLends() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final previouslySelectedId = _recordId(selectedLend);
      final response = await apiService.get(url);
      debugPrint('Get lend status: ${response.statusCode}');
      debugPrint('Get lend response: ${response.body}');

      if (response.statusCode != 200) {
        errorMessage.value =
            'Failed to fetch lend details (${response.statusCode}).';
        Get.snackbar('Error', errorMessage.value);
        return;
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> data = [];

      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map) {
        final value = decoded['data'];
        if (value is List) {
          data = value;
        } else if (value is Map) {
          if (value['data'] is List) {
            data = value['data'] as List;
          } else {
            data = [value];
          }
        }
      }

      lends.assignAll(
        data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
      );

      final argument = Get.arguments;
      if (argument is Map) {
        final argumentRecord = Map<String, dynamic>.from(argument);
        final matchingRecord = _findById(_recordId(argumentRecord));
        selectedLend.assignAll(matchingRecord ?? argumentRecord);
      } else if (argument is int && argument >= 0 && argument < lends.length) {
        selectedLend.assignAll(lends[argument]);
      } else if (_findById(previouslySelectedId) != null) {
        final matchingRecord = _findById(previouslySelectedId)!;
        selectedLend.assignAll(matchingRecord);
      } else if (lends.isNotEmpty) {
        selectedLend.assignAll(lends.first);
      } else {
        selectedLend.clear();
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch lend error: $e');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage.value = 'Unable to load lend details.';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  String get personName =>
      (selectedLend['receiveFrom'] ??
              selectedLend['givenTo'] ??
              selectedLend['person'] ??
              selectedLend['name'] ??
              '')
          .toString();

  String get phone => (selectedLend['phone'] ?? '').toString();

  String get amount => (selectedLend['amount'] ?? '0').toString();

  String get interest =>
      (selectedLend['rateOfInterest'] ?? selectedLend['interest'] ?? '0')
          .toString();

  String get receiveDate =>
      (selectedLend['receiveDate'] ?? selectedLend['giveDate'] ?? '')
          .toString();

  String get returnDate =>
      (selectedLend['returnDate'] ?? selectedLend['repaymentDate'] ?? '')
          .toString();

  String get description => (selectedLend['description'] ?? '').toString();

  double get amountValue => double.tryParse(amount) ?? 0;

  double get interestValue => double.tryParse(interest) ?? 0;

  dynamic _recordId(Map<String, dynamic> record) =>
      record['id'] ?? record['debitId'] ?? record['debit_id'];

  Map<String, dynamic>? _findById(dynamic id) {
    if (id == null) return null;
    for (final lend in lends) {
      if (_recordId(lend)?.toString() == id.toString()) {
        return lend;
      }
    }
    return null;
  }
}
