import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class GetChitfundsController extends GetxController {
  GetChitfundsController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  static const int pageSize = 20;

  final ApiService apiService;
  final RxList<Map<String, dynamic>> chits = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString loadError = ''.obs;
  final RxString loadMoreError = ''.obs;
  final RxInt currentPage = 0.obs;
  final RxInt lastPage = 1.obs;
  final RxInt totalRecords = 0.obs;

  int _requestGeneration = 0;

  bool get hasMore => currentPage.value < lastPage.value;

  @override
  void onInit() {
    super.onInit();
    fetchChits();
  }

  Future<void> fetchChits() async {
    if (isLoading.value) return;
    final generation = ++_requestGeneration;
    isLoading.value = true;
    loadError.value = '';
    loadMoreError.value = '';
    try {
      final page = await _fetchPage(1);
      if (generation != _requestGeneration) return;
      chits.assignAll(page.items);
      currentPage.value = page.currentPage;
      lastPage.value = page.lastPage;
      totalRecords.value = page.total;
    } on FormatException catch (error) {
      if (generation == _requestGeneration) loadError.value = error.message;
      debugPrint('Unable to fetch chits: ${error.message}');
    } catch (error, stackTrace) {
      if (generation == _requestGeneration) {
        loadError.value = 'Unable to load chit funds. Please retry.';
      }
      debugPrint('Unable to fetch chits: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshChits() => fetchChits();

  Future<void> loadNextPage() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    loadMoreError.value = '';
    final generation = _requestGeneration;
    try {
      final page = await _fetchPage(currentPage.value + 1);
      if (generation != _requestGeneration) return;
      final knownIds = chits.map(_recordId).whereType<String>().toSet();
      chits.addAll(
        page.items.where((chit) {
          final id = _recordId(chit);
          return id == null || knownIds.add(id);
        }),
      );
      currentPage.value = page.currentPage;
      lastPage.value = page.lastPage;
      totalRecords.value = page.total;
    } on FormatException catch (error) {
      if (generation == _requestGeneration) {
        loadMoreError.value = error.message;
      }
      debugPrint('Unable to load more chits: ${error.message}');
    } catch (error, stackTrace) {
      if (generation == _requestGeneration) {
        loadMoreError.value = 'Unable to load more chit funds. Please retry.';
      }
      debugPrint('Unable to load more chits: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<_ChitPage> _fetchPage(int page) async {
    final response = await apiService.getChits(page: page, perPage: pageSize);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) message = decoded['message']?.toString();
      } on FormatException {
        message = null;
      }
      throw FormatException(
        message == null || message.isEmpty
            ? 'Chit funds request failed (${response.statusCode}).'
            : message,
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned invalid chit data.');
    }
    if (decoded is! Map) {
      throw const FormatException('Unexpected chit funds response format.');
    }
    final result = Map<String, dynamic>.from(decoded);
    final apiSuccess =
        result['success'] == true ||
        result['status']?.toString().toLowerCase() == 'success';
    if (!apiSuccess) {
      throw FormatException(
        result['message']?.toString() ?? 'Failed to fetch chit funds.',
      );
    }

    final data = result['data'];
    final dynamic itemValue = data is List
        ? data
        : data is Map && data['items'] is List
        ? data['items']
        : data is Map && data['chits'] is List
        ? data['chits']
        : data is Map && data['data'] is List
        ? data['data']
        : data is Map &&
              (data.containsKey('uuid') ||
                  data.containsKey('id') ||
                  data.containsKey('chit_uuid'))
        ? [data]
        : null;
    if (itemValue is! List) {
      throw const FormatException('Unexpected chit funds list response.');
    }

    final items = <Map<String, dynamic>>[];
    for (final item in itemValue) {
      if (item is! Map) {
        throw const FormatException(
          'The chit funds list contained invalid data.',
        );
      }
      items.add(Map<String, dynamic>.from(item));
    }
    final paginationValue = data is Map
        ? data['pagination'] ?? data['meta']
        : result['pagination'];
    final pagination = paginationValue is Map
        ? Map<String, dynamic>.from(paginationValue)
        : <String, dynamic>{};
    return _ChitPage(
      items: items,
      currentPage: _positiveInt(pagination['current_page'], page),
      lastPage: _positiveInt(pagination['last_page'], page),
      total: _nonNegativeInt(pagination['total'], items.length),
    );
  }

  String? _recordId(Map<String, dynamic> chit) {
    final value =
        chit['uuid'] ?? chit['id'] ?? chit['chit_uuid'] ?? chit['chit_id'];
    final id = value?.toString().trim();
    return id == null || id.isEmpty ? null : id;
  }

  int _positiveInt(dynamic value, int fallback) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : fallback;
  }

  int _nonNegativeInt(dynamic value, int fallback) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed >= 0 ? parsed : fallback;
  }

  String valueFor(Map<String, dynamic> chit, List<String> keys) {
    for (final key in keys) {
      final value = chit[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  double? amountFor(Map<String, dynamic> chit, List<String> keys) {
    for (final key in keys) {
      final amount = double.tryParse(chit[key]?.toString() ?? '');
      if (amount != null && amount.isFinite) return amount;
    }
    return null;
  }
}

class _ChitPage {
  const _ChitPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Map<String, dynamic>> items;
  final int currentPage;
  final int lastPage;
  final int total;
}
