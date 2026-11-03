import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PostchitfundController extends GetxController {
  PostchitfundController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController organizerNameController = TextEditingController();
  final TextEditingController groupReferenceController =
      TextEditingController();
  final TextEditingController memberReferenceController =
      TextEditingController();
  final TextEditingController chitValueController = TextEditingController();
  final TextEditingController installmentAmountController =
      TextEditingController();
  final TextEditingController installmentCountController =
      TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final accounts = <Map<String, dynamic>>[].obs;
  final isLoadingAccounts = false.obs;
  final accountLoadError = ''.obs;
  final selectedContributionAccountUuid = RxnString();
  final startDate = Rx<DateTime?>(null);
  final firstDueDate = Rx<DateTime?>(null);
  final chitType = 'auction'.obs;
  final isLoading = false.obs;
  final RxBool isEditing = false.obs;
  String editingUuid = '';

  String? _pendingIdempotencyKey;
  String? _pendingRequestBody;

  @override
  void onInit() {
    super.onInit();
    _loadEditArguments();
    loadContributionAccounts();
  }

  void _loadEditArguments() {
    final arguments = Get.arguments;
    if (arguments is! Map) return;
    final map = Map<String, dynamic>.from(arguments);
    editingUuid = (map['uuid'] ?? map['chit_uuid'] ?? map['id'] ?? '')
        .toString();
    if (editingUuid.isEmpty) return;
    isEditing.value = true;
    nameController.text = _argumentValue(map, ['name', 'chit_name']);
    organizerNameController.text = _argumentValue(map, [
      'organizer_name',
      'organizer',
    ]);
    groupReferenceController.text = _argumentValue(map, ['group_reference']);
    memberReferenceController.text = _argumentValue(map, ['member_reference']);
    chitValueController.text = _argumentValue(map, [
      'chit_value',
      'total_value',
      'total_amount',
    ]);
    installmentAmountController.text = _argumentValue(map, [
      'installment_amount',
    ]);
    installmentCountController.text = _argumentValue(map, [
      'installment_count',
    ]);
    notesController.text = _argumentValue(map, ['notes']);
    startDate.value = DateTime.tryParse(_argumentValue(map, ['start_date']));
    firstDueDate.value = DateTime.tryParse(
      _argumentValue(map, ['first_due_date']),
    );
    selectedContributionAccountUuid.value = _argumentValue(map, [
      'contribution_account_uuid',
    ]);
    final type = _argumentValue(map, ['chit_type']);
    if (type.isNotEmpty) chitType.value = type;
  }

  String _argumentValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Future<void> loadContributionAccounts() async {
    isLoadingAccounts.value = true;
    accountLoadError.value = '';
    try {
      final response = await apiService.getAccounts();
      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(decoded, 'Unable to load accounts.'),
        );
      }

      final data = decoded['data'];
      final List<dynamic>? items = data is List
          ? data
          : data is Map && data['items'] is List
          ? data['items'] as List<dynamic>
          : null;
      if (items == null) {
        throw const FormatException('Unexpected accounts response.');
      }

      accounts.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((account) {
          final uuid = accountUuid(account).trim();
          final status = account['status']?.toString().trim().toLowerCase();
          return uuid.isNotEmpty &&
              (status == null || status == 'active' || status == '1');
        }),
      );
      if (accounts.length == 1) {
        selectedContributionAccountUuid.value = accountUuid(accounts.first);
      }
    } catch (error) {
      accountLoadError.value = error is FormatException
          ? error.message
          : 'Failed to load accounts. Please try again.';
      debugPrint('CHIT CONTRIBUTION ACCOUNT LOAD ERROR: $error');
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  String accountUuid(Map<String, dynamic> account) =>
      (account['uuid'] ?? account['account_uuid'])?.toString() ?? '';

  String accountName(Map<String, dynamic> account) =>
      (account['name'] ?? account['account_name'])?.toString() ?? 'Account';

  String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    startDate.value = picked;
    if (firstDueDate.value != null && firstDueDate.value!.isBefore(picked)) {
      firstDueDate.value = null;
      _showMessage(
        'Due date reset',
        'The first due date must be on or after the start date.',
      );
    }
  }

  Future<void> selectFirstDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: firstDueDate.value ?? startDate.value ?? DateTime.now(),
      firstDate: startDate.value ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) firstDueDate.value = picked;
  }

  Future<void> postChit() async {
    if (isLoading.value) return;
    if (formKey.currentState?.validate() != true) return;

    final start = startDate.value;
    final due = firstDueDate.value;
    if (start == null) {
      _showMessage('Required', 'Please select the start date.');
      return;
    }
    if (due == null) {
      _showMessage('Required', 'Please select the first due date.');
      return;
    }
    if (due.isBefore(start)) {
      _showMessage(
        'Invalid date',
        'The first due date cannot be before the start date.',
      );
      return;
    }
    final accountUuid = selectedContributionAccountUuid.value;
    if (accountUuid == null || accountUuid.isEmpty) {
      _showMessage('Required', 'Please select the contribution account.');
      return;
    }

    final chitValue = double.tryParse(chitValueController.text.trim());
    final installmentAmount = double.tryParse(
      installmentAmountController.text.trim(),
    );
    final installmentCount = int.tryParse(
      installmentCountController.text.trim(),
    );
    if (chitValue == null ||
        !chitValue.isFinite ||
        installmentAmount == null ||
        !installmentAmount.isFinite ||
        installmentCount == null) {
      _showMessage('Invalid amount', 'Please enter valid chit amounts.');
      return;
    }

    final body = <String, dynamic>{
      'name': nameController.text.trim(),
      'organizer_name': organizerNameController.text.trim(),
      'group_reference': groupReferenceController.text.trim(),
      'member_reference': memberReferenceController.text.trim(),
      'chit_value': chitValue.toStringAsFixed(2),
      'installment_amount': installmentAmount.toStringAsFixed(2),
      'installment_count': installmentCount,
      'currency': 'INR',
      'start_date': formatDate(start),
      'first_due_date': formatDate(due),
      'contribution_account_uuid': accountUuid,
      'status': 'active',
      'notes': notesController.text.trim(),
      'chit_type': chitType.value,
    };

    try {
      isLoading.value = true;
      final encodedBody = jsonEncode(body);
      if (_pendingIdempotencyKey == null ||
          _pendingRequestBody != encodedBody) {
        _pendingIdempotencyKey = ApiService.createIdempotencyKey();
        _pendingRequestBody = encodedBody;
      }

      final response = isEditing.value
          ? await apiService.put(
              '${ApiService.chitsUrl}/${Uri.encodeComponent(editingUuid)}',
              body,
            )
          : await apiService.postChit(
              body,
              idempotencyKey: _pendingIdempotencyKey!,
            );
      final decoded = _decodeResponse(response);
      final message = _responseMessage(decoded, 'Unable to save chit.');
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['success'] == true) {
        _showMessage('Success', message);
        clearForm();
        isEditing.value = false;
        editingUuid = '';
        _pendingIdempotencyKey = null;
        _pendingRequestBody = null;
        if (Get.key.currentState?.canPop() ?? false) Get.back(result: true);
        return;
      }

      final details = _errorDetails(decoded['errors']);
      _showMessage(
        'Failed (${response.statusCode})',
        details.isEmpty ? message : details,
      );
    } on FormatException catch (error) {
      _showMessage('Server Error', error.message);
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('Post chit connection error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Connection error',
        'The server could not confirm this chit. Check your connection and '
            'try again; your form is unchanged.',
      );
    } catch (error, stackTrace) {
      debugPrint('Post chit error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'Error',
        'Unable to submit chit details. Your form is unchanged; please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw const FormatException('Empty response from server.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Unexpected server response.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _responseMessage(Map<String, dynamic> decoded, String fallback) {
    final message = decoded['message']?.toString().trim();
    return message == null || message.isEmpty ? fallback : message;
  }

  String _errorDetails(dynamic errors) {
    if (errors is Map) {
      return errors.entries
          .map((entry) {
            final value = entry.value;
            return value is List
                ? value.map((item) => item.toString()).join(', ')
                : value.toString();
          })
          .join('\n');
    }
    if (errors is List) {
      return errors.map((item) => item.toString()).join('\n');
    }
    return '';
  }

  void clearForm() {
    nameController.clear();
    organizerNameController.clear();
    groupReferenceController.clear();
    memberReferenceController.clear();
    chitValueController.clear();
    installmentAmountController.clear();
    installmentCountController.clear();
    notesController.clear();
    startDate.value = null;
    firstDueDate.value = null;
    selectedContributionAccountUuid.value = accounts.length == 1
        ? accountUuid(accounts.first)
        : null;
    chitType.value = 'auction';
    formKey.currentState?.reset();
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    organizerNameController.dispose();
    groupReferenceController.dispose();
    memberReferenceController.dispose();
    chitValueController.dispose();
    installmentAmountController.dispose();
    installmentCountController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
