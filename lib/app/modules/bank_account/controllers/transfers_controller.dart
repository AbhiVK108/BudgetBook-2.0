import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'account_transactions_controller.dart';

class TransfersController extends GetxController {
  TransfersController({required this.apiService});

  static const int pageSize = 20;

  final ApiService apiService;
  final transfers = <AccountTransaction>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isCreating = false.obs;
  final errorMessage = ''.obs;
  final createError = ''.obs;
  final loadMoreError = ''.obs;
  final currentPage = 0.obs;
  final lastPage = 1.obs;
  final total = 0.obs;

  int _requestGeneration = 0;
  String? _pendingIdempotencyKey;
  String? _pendingRequestBody;

  bool get hasMore => currentPage.value < lastPage.value;

  Future<bool> createTransfer({
    required String amount,
    required DateTime transactionDate,
    required String sourceAccountUuid,
    required String destinationAccountUuid,
    required String description,
  }) async {
    if (isCreating.value) return false;

    final parsedAmount = double.tryParse(amount.trim());
    if (parsedAmount == null || !parsedAmount.isFinite || parsedAmount <= 0) {
      createError.value = 'Enter an amount greater than zero.';
      return false;
    }
    if (sourceAccountUuid.trim().isEmpty ||
        destinationAccountUuid.trim().isEmpty) {
      createError.value = 'Select both source and destination accounts.';
      return false;
    }
    if (sourceAccountUuid == destinationAccountUuid) {
      createError.value = 'Source and destination accounts must be different.';
      return false;
    }
    if (description.trim().isEmpty) {
      createError.value = 'Enter a transfer description.';
      return false;
    }

    final requestBody = <String, dynamic>{
      'amount': parsedAmount.toStringAsFixed(2),
      'transaction_date': _formatDate(transactionDate),
      'source_account_uuid': sourceAccountUuid,
      'destination_account_uuid': destinationAccountUuid,
      'description': description.trim(),
    };
    final encodedRequestBody = jsonEncode(requestBody);
    if (_pendingIdempotencyKey == null ||
        _pendingRequestBody != encodedRequestBody) {
      _pendingIdempotencyKey = ApiService.createIdempotencyKey();
      _pendingRequestBody = encodedRequestBody;
    }

    isCreating.value = true;
    createError.value = '';
    try {
      final response = await apiService.postTransfer(
        requestBody,
        idempotencyKey: _pendingIdempotencyKey!,
      );
      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException(
          'The server returned an invalid transfer response.',
        );
      }

      final data = decoded is Map ? decoded['data'] : null;
      final transaction = data is Map ? data['transaction'] : null;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded is! Map ||
          decoded['success'] != true ||
          transaction is! Map) {
        final message = decoded is Map
            ? decoded['message']?.toString()
            : null;
        createError.value = message == null || message.isEmpty
            ? 'Unable to create transfer. Please try again.'
            : message;
        return false;
      }

      final createdTransfer = AccountTransaction.fromJson(
        Map<String, dynamic>.from(transaction),
      );
      if (createdTransfer.uuid == null ||
          createdTransfer.uuid!.trim().isEmpty) {
        throw const FormatException(
          'The server response did not include the transfer identifier.',
        );
      }
      transfers.removeWhere(
        (transfer) => transfer.uuid == createdTransfer.uuid,
      );
      transfers.insert(0, createdTransfer);
      total.value++;
      _pendingIdempotencyKey = null;
      _pendingRequestBody = null;
      return true;
    } on FormatException catch (error) {
      createError.value = error.message;
      return false;
    } catch (error, stackTrace) {
      debugPrint('Unable to create transfer: $error');
      debugPrintStack(stackTrace: stackTrace);
      createError.value =
          'Unable to connect to the server. Please try again.';
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  void onInit() {
    super.onInit();
    fetchTransfers();
  }

  Future<void> fetchTransfers() async {
    if (isLoading.value) return;
    final generation = ++_requestGeneration;
    isLoading.value = true;
    errorMessage.value = '';
    loadMoreError.value = '';

    try {
      final result = await _fetchPage(1);
      if (generation != _requestGeneration) return;
      transfers.assignAll(result.items);
      currentPage.value = result.currentPage;
      lastPage.value = result.lastPage;
      total.value = result.total;
    } catch (error, stackTrace) {
      debugPrint('Unable to fetch transfers: $error');
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
      final knownUuids = transfers
          .map((transfer) => transfer.uuid)
          .whereType<String>()
          .toSet();
      transfers.addAll(
        result.items.where(
          (transfer) =>
              transfer.uuid == null || knownUuids.add(transfer.uuid!),
        ),
      );
      currentPage.value = result.currentPage;
      lastPage.value = result.lastPage;
      total.value = result.total;
    } catch (error, stackTrace) {
      debugPrint('Unable to load more transfers: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (generation == _requestGeneration) {
        loadMoreError.value = _userMessage(error);
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<_TransfersPage> _fetchPage(int page) async {
    final response = await apiService.getTransfers(
      page: page,
      perPage: pageSize,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? serverMessage;
      try {
        final decodedError = jsonDecode(response.body);
        if (decodedError is Map) {
          serverMessage = decodedError['message']?.toString();
        }
      } on FormatException {
        serverMessage = null;
      }
      throw FormatException(
        serverMessage == null || serverMessage.isEmpty
            ? 'Transfers request failed (${response.statusCode}).'
            : serverMessage,
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException(
        'The server returned invalid transfer data.',
      );
    }
    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map ||
        decoded['data']['items'] is! List) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw FormatException(
        message == null || message.isEmpty
            ? 'The transfers response was invalid.'
            : message,
      );
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final items = <AccountTransaction>[];
    for (final item in data['items'] as List) {
      if (item is! Map) {
        throw const FormatException(
          'The transfer list contained invalid data.',
        );
      }
      items.add(AccountTransaction.fromJson(Map<String, dynamic>.from(item)));
    }

    final paginationValue = data['pagination'];
    if (paginationValue is! Map) {
      throw const FormatException('The transfers pagination data was invalid.');
    }
    final pagination = Map<String, dynamic>.from(paginationValue);
    return _TransfersPage(
      items: items,
      currentPage: _readPositiveInt(pagination['current_page'], page),
      lastPage: _readPositiveInt(pagination['last_page'], page),
      total: _readNonNegativeInt(pagination['total'], items.length),
    );
  }

  String _userMessage(Object error) {
    if (error is FormatException) return error.message;
    return 'Unable to load transfers. Please try again.';
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

class _TransfersPage {
  const _TransfersPage({
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
