import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'bank_accounts_controller.dart';

class AccountTransactionsController extends GetxController {
  AccountTransactionsController({required this.account, ApiService? apiService})
    : apiService = apiService ?? ApiService();

  static const int pageSize = 20;

  final BankAccount account;
  final ApiService apiService;
  final transactions = <AccountTransaction>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  final loadMoreError = ''.obs;
  final currentPage = 0.obs;
  final lastPage = 1.obs;
  final total = 0.obs;

  int _requestGeneration = 0;

  bool get hasMore => currentPage.value < lastPage.value;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    if (isLoading.value) return;
    final generation = ++_requestGeneration;
    isLoading.value = true;
    errorMessage.value = '';
    loadMoreError.value = '';

    try {
      final page = 1;
      final result = await _fetchPage(page);
      if (generation != _requestGeneration) return;
      transactions.assignAll(result.items);
      currentPage.value = result.currentPage;
      lastPage.value = result.lastPage;
      total.value = result.total;
    } catch (error, stackTrace) {
      debugPrint('Unable to fetch account transactions: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (generation == _requestGeneration) {
        errorMessage.value = _userMessage(error);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    loadMoreError.value = '';
    final generation = _requestGeneration;

    try {
      final result = await _fetchPage(currentPage.value + 1);
      if (generation != _requestGeneration) return;
      final knownUuids = transactions
          .map((transaction) => transaction.uuid)
          .whereType<String>()
          .toSet();
      transactions.addAll(
        result.items.where(
          (transaction) =>
              transaction.uuid == null || knownUuids.add(transaction.uuid!),
        ),
      );
      currentPage.value = result.currentPage;
      lastPage.value = result.lastPage;
      total.value = result.total;
    } catch (error, stackTrace) {
      debugPrint('Unable to load more account transactions: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (generation == _requestGeneration) {
        loadMoreError.value = _userMessage(error);
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<_AccountTransactionsPage> _fetchPage(int page) async {
    final uuid = account.uuid?.trim();
    if (uuid == null || uuid.isEmpty) {
      throw const FormatException('This account has no valid identifier.');
    }

    final uri = Uri.parse(
      '${ApiService.accountsUrl}/${Uri.encodeComponent(uuid)}/transactions',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$pageSize'});
    final response = await apiService.get(uri.toString());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? serverMessage;
      try {
        final errorResponse = jsonDecode(response.body);
        if (errorResponse is Map) {
          serverMessage = errorResponse['message']?.toString();
        }
      } on FormatException {
        serverMessage = null;
      }
      throw FormatException(
        serverMessage == null || serverMessage.isEmpty
            ? 'Account transactions request failed (${response.statusCode}).'
            : serverMessage,
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException(
        'The server returned invalid account transaction data.',
      );
    }

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map ||
        decoded['data']['items'] is! List) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw FormatException(
        message == null || message.isEmpty
            ? 'The account transaction response was invalid.'
            : message,
      );
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final items = <AccountTransaction>[];
    for (final item in data['items'] as List) {
      if (item is! Map) {
        throw const FormatException(
          'The account transaction list contained invalid data.',
        );
      }
      items.add(AccountTransaction.fromJson(Map<String, dynamic>.from(item)));
    }
    final paginationValue = data['pagination'];
    if (paginationValue is! Map) {
      throw const FormatException(
        'The account transaction pagination data was invalid.',
      );
    }

    final pagination = Map<String, dynamic>.from(paginationValue);
    return _AccountTransactionsPage(
      items: items,
      currentPage: _readPositiveInt(pagination['current_page'], page),
      lastPage: _readPositiveInt(pagination['last_page'], page),
      total: _readNonNegativeInt(pagination['total'], items.length),
    );
  }

  String _userMessage(Object error) {
    if (error is FormatException) return error.message;
    return 'Unable to load account transactions. Please try again.';
  }

  static int _readPositiveInt(dynamic value, int fallback) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : fallback;
  }

  static int _readNonNegativeInt(dynamic value, int fallback) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed >= 0 ? parsed : fallback;
  }
}

class AccountTransaction {
  const AccountTransaction({
    required this.uuid,
    required this.type,
    required this.amount,
    required this.currency,
    required this.transactionDate,
    required this.description,
    required this.counterparty,
    required this.reference,
    required this.status,
    required this.categoryName,
    required this.sourceAccountUuid,
    required this.sourceAccountName,
    required this.destinationAccountUuid,
    required this.destinationAccountName,
    required this.reversedTransactionUuid,
    required this.reversalUuid,
  });

  final String? uuid;
  final String type;
  final String amount;
  final String currency;
  final String? transactionDate;
  final String? description;
  final String? counterparty;
  final String? reference;
  final String status;
  final String? categoryName;
  final String? sourceAccountUuid;
  final String? sourceAccountName;
  final String? destinationAccountUuid;
  final String? destinationAccountName;
  final String? reversedTransactionUuid;
  final String? reversalUuid;

  bool get isReversed =>
      reversedTransactionUuid != null || reversalUuid != null;

  bool isCreditFor(String accountUuid) {
    if (destinationAccountUuid == accountUuid) {
      return true;
    }
    if (sourceAccountUuid == accountUuid) {
      return false;
    }

    final normalizedType = type.toLowerCase();
    return normalizedType == 'income' ||
        normalizedType == 'opening_balance' ||
        normalizedType == 'transfer_in' ||
        normalizedType == 'deposit';
  }

  factory AccountTransaction.fromJson(Map<String, dynamic> json) {
    String? readOptional(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return AccountTransaction(
      uuid: readOptional('uuid'),
      type: readOptional('type') ?? 'transaction',
      amount: readOptional('amount') ?? '0.00',
      currency: readOptional('currency') ?? 'INR',
      transactionDate: readOptional('transaction_date'),
      description: readOptional('description'),
      counterparty: readOptional('counterparty'),
      reference: readOptional('reference'),
      status: readOptional('status') ?? 'unknown',
      categoryName: readOptional('category_name'),
      sourceAccountUuid: readOptional('source_account_uuid'),
      sourceAccountName: readOptional('source_account_name'),
      destinationAccountUuid: readOptional('destination_account_uuid'),
      destinationAccountName: readOptional('destination_account_name'),
      reversedTransactionUuid: readOptional('reversed_transaction_uuid'),
      reversalUuid: readOptional('reversal_uuid'),
    );
  }
}

class _AccountTransactionsPage {
  const _AccountTransactionsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AccountTransaction> items;
  final int currentPage;
  final int lastPage;
  final int total;
}
