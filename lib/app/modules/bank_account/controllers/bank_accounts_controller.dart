import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class BankAccountsController extends GetxController {
  BankAccountsController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;
  final isLoading = false.obs;
  final isUpdating = false.obs;
  final errorMessage = ''.obs;
  final accounts = <BankAccount>[].obs;
  final selectedAccountFilter = 'all'.obs;

  List<BankAccount> get filteredAccounts {
    switch (selectedAccountFilter.value) {
      case 'bank':
        return accounts
            .where((account) => account.type.toLowerCase() == 'bank')
            .toList();
      case 'cash':
        return accounts
            .where((account) => account.type.toLowerCase() == 'cash')
            .toList();
      default:
        return accounts.toList();
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await apiService.getAccounts(includeArchived: true);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Accounts request failed (${response.statusCode}).');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map ||
          decoded['data']['items'] is! List) {
        throw const FormatException('The accounts response was invalid.');
      }

      accounts.value = (decoded['data']['items'] as List)
          .whereType<Map>()
          .map(
            (item) => BankAccount.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (error, stackTrace) {
      debugPrint('Unable to fetch bank accounts: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage.value = 'Unable to load accounts. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openAddAccount({String accountType = 'bank'}) async {
    final result = await Get.toNamed(
      '/add-bank-account',
      arguments: {'accountType': accountType},
    );
    if (result != null) await fetchAccounts();
  }

  Future<bool> updateAccount(
    BankAccount account, {
    required String name,
    required String type,
    required String institution,
    required String currency,
    required bool allowNegative,
    required String notes,
  }) async {
    if (isUpdating.value) return false;
    final uuid = account.uuid?.trim();
    if (uuid == null || uuid.isEmpty) {
      Get.snackbar(
        'Unable to update account',
        'This account does not have a valid identifier.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isUpdating.value = true;
    try {
      final response = await apiService.put(
        '${ApiService.accountsUrl}/${Uri.encodeComponent(uuid)}',
        {
          'name': name.trim(),
          'type': type,
          'institution': institution.trim(),
          'currency': currency,
          'allow_negative': allowNegative,
          'notes': notes.trim(),
        },
      );

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final payload = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          payload['success'] != true) {
        Get.snackbar(
          'Unable to update account',
          payload['message']?.toString() ??
              'The account could not be updated. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      Get.snackbar(
        'Account updated',
        payload['message']?.toString() ?? 'Account details saved.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchAccounts();
      return true;
    } on FormatException {
      Get.snackbar(
        'Unable to update account',
        'The server returned an invalid response.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (error, stackTrace) {
      debugPrint('Unable to update bank account: $error');
      debugPrintStack(stackTrace: stackTrace);
      Get.snackbar(
        'Unable to update account',
        'Unable to connect to the server. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}

class BankAccount {
  const BankAccount({
    required this.uuid,
    required this.name,
    required this.type,
    required this.institution,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.balance,
    required this.allowNegative,
    required this.notes,
  });

  final String? uuid;
  final String name;
  final String type;
  final String? institution;
  final String currency;
  final String status;
  final String? createdAt;
  final String balance;
  final bool allowNegative;
  final String? notes;

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    String? readOptional(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return BankAccount(
      uuid: readOptional('uuid'),
      name: readOptional('name') ?? 'Unnamed account',
      type: readOptional('type') ?? 'account',
      institution: readOptional('institution'),
      currency: readOptional('currency') ?? 'INR',
      status: readOptional('status') ?? 'unknown',
      createdAt: readOptional('created_at'),
      balance: readOptional('balance') ?? '0.00',
      allowNegative: _parseBool(json['allow_negative']),
      notes: readOptional('notes'),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == true || value == 1) return true;
    return const {'true', '1', 'yes'}.contains(
      value?.toString().trim().toLowerCase(),
    );
  }
}
