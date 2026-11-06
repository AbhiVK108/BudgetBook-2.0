import 'dart:convert';

import 'package:budget_book_2026/app/core/constants/api_endpoints.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/core/services/income_category_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PostLendController extends GetxController {
  PostLendController({ApiService? apiService})
    : apiService = apiService ?? ApiService();

  final ApiService apiService;
  late final IncomeCategoryService _incomeCategoryService =
      IncomeCategoryService(apiService: apiService);

  final String url = ApiEndpoints.legacyDebitUrl;
  final categories = <Map<String, dynamic>>[].obs;
  final accounts = <Map<String, dynamic>>[].obs;
  final isLoadingCategories = false.obs;
  final isLoadingAccounts = false.obs;
  final isCreatingCategory = false.obs;
  final categoryLoadError = ''.obs;
  final accountLoadError = ''.obs;
  final selectedInterestCategoryUuid = RxnString();
  final selectedSourceAccountUuid = RxnString();
  final interestMethod = 'fixed'.obs;
  String? _pendingLendingIdempotencyKey;
  String? _pendingLendingRequestBody;

  // Form controllers
  final TextEditingController personController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController amountController = TextEditingController();

  final TextEditingController interestController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  // Selected dates
  final Rx<DateTime?> giveDate = Rx<DateTime?>(null);
  final Rx<DateTime?> returnDate = Rx<DateTime?>(null);

  // Loading state
  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  dynamic editingLendId;

  // Format date as YYYY-MM-DD
  String formatDate(DateTime date) {
    final String year = date.year.toString();
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is Map) {
      final lend = Map<String, dynamic>.from(argument);
      editingLendId = lend['id'] ?? lend['debitId'] ?? lend['debit_id'];
      isEditMode.value = true;
      personController.text =
          (lend['receiveFrom'] ?? lend['givenTo'] ?? lend['person'] ?? '')
              .toString();
      phoneController.text = (lend['phone'] ?? '').toString();
      amountController.text = (lend['amount'] ?? '').toString();
      interestController.text =
          (lend['rateOfInterest'] ?? lend['interest'] ?? '').toString();
      descriptionController.text = (lend['description'] ?? '').toString();
      giveDate.value = _parseDate(lend['receiveDate'] ?? lend['giveDate']);
      returnDate.value = _parseDate(
        lend['returnDate'] ?? lend['repaymentDate'],
      );
    }
    loadIncomeCategories();
    loadSourceAccounts();
  }

  Future<void> loadIncomeCategories() async {
    isLoadingCategories.value = true;
    categoryLoadError.value = '';
    try {
      final uri = Uri.parse(
        ApiService.categoriesUrl,
      ).replace(queryParameters: {'type': 'income'});
      final response = await apiService.get(uri.toString());
      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          _responseMessage(decoded, 'Unable to load income categories.'),
        );
      }

      final dataValue = decoded['data'];
      final List<dynamic>? items = dataValue is List
          ? dataValue
          : dataValue is Map && dataValue['items'] is List
          ? dataValue['items'] as List<dynamic>
          : null;
      if (items == null) {
        throw const FormatException('Unexpected income categories response.');
      }
      categories.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((item) {
          final uuid = (item['uuid'] ?? item['category_uuid'])
              ?.toString()
              .trim();
          final type =
              (item['category_type'] ?? item['categoryType'] ?? item['type'])
                  ?.toString()
                  .trim()
                  .toLowerCase();
          final status = item['status']?.toString().trim().toLowerCase();
          return uuid != null &&
              uuid.isNotEmpty &&
              (type == null || type == 'income') &&
              (status == null || status == '1' || status == 'active');
        }),
      );
      if (categories.length == 1) {
        selectedInterestCategoryUuid.value =
            (categories.first['uuid'] ?? categories.first['category_uuid'])
                ?.toString();
      }
    } catch (error) {
      categoryLoadError.value = error is FormatException
          ? error.message
          : 'Failed to load income categories. Please try again.';
      debugPrint('LENDING CATEGORY LOAD ERROR: $error');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<Map<String, dynamic>?> createIncomeCategory({
    required String name,
    required String icon,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || isCreatingCategory.value) return null;

    try {
      isCreatingCategory.value = true;
      final category = await _incomeCategoryService.create(
        name: trimmedName,
        icon: icon,
      );
      final uuid = categoryUuid(category);
      if (uuid.isEmpty) return null;

      categories.add(category);
      selectedInterestCategoryUuid.value = uuid;
      return category;
    } catch (error) {
      debugPrint('LENDING CATEGORY CREATE ERROR: $error');
      return null;
    } finally {
      isCreatingCategory.value = false;
    }
  }

  Future<void> loadSourceAccounts() async {
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
      final dataValue = decoded['data'];
      final List<dynamic>? items = dataValue is List
          ? dataValue
          : dataValue is Map && dataValue['items'] is List
          ? dataValue['items'] as List<dynamic>
          : null;
      if (items == null) {
        throw const FormatException('Unexpected accounts response.');
      }
      accounts.assignAll(
        items.whereType<Map>().map(Map<String, dynamic>.from).where((item) {
          final uuid = (item['uuid'] ?? item['account_uuid'])
              ?.toString()
              .trim();
          final status = item['status']?.toString().trim().toLowerCase();
          return uuid != null &&
              uuid.isNotEmpty &&
              (status == null || status == 'active' || status == '1');
        }),
      );
      if (accounts.length == 1) {
        selectedSourceAccountUuid.value =
            (accounts.first['uuid'] ?? accounts.first['account_uuid'])
                ?.toString();
      }
    } catch (error) {
      accountLoadError.value = error is FormatException
          ? error.message
          : 'Failed to load accounts. Please try again.';
      debugPrint('LENDING ACCOUNT LOAD ERROR: $error');
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  String categoryUuid(Map<String, dynamic> category) =>
      (category['uuid'] ?? category['category_uuid'])?.toString() ?? '';

  String categoryName(Map<String, dynamic> category) =>
      (category['name'] ??
              category['category_name'] ??
              category['categoryName'])
          ?.toString() ??
      'Income category';

  String accountUuid(Map<String, dynamic> account) =>
      (account['uuid'] ?? account['account_uuid'])?.toString() ?? '';

  String accountName(Map<String, dynamic> account) =>
      (account['name'] ?? account['account_name'])?.toString() ?? 'Account';

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

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    final parts = text.split('-');
    if (parts.length != 3) return null;
    try {
      if (parts[0].length == 4) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } on FormatException {
      return null;
    }
  }

  // Select give date
  Future<void> selectGiveDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: giveDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    giveDate.value = picked;

    // Reset return date if it is before the give date.
    if (returnDate.value != null && returnDate.value!.isBefore(picked)) {
      returnDate.value = null;

      _showMessage(
        'Return Date Reset',
        'Please select a return date on or after the give date.',
      );
    }
  }

  // Select return date
  Future<void> selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: returnDate.value ?? giveDate.value ?? DateTime.now(),
      firstDate: giveDate.value ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      returnDate.value = picked;
    }
  }

  // Submit lending details
  Future<void> postLend() async {
    if (isLoading.value) return;

    final String person = personController.text.trim();
    final String phone = phoneController.text.trim();
    final String amountText = amountController.text.trim();
    final String interestText = interestController.text.trim();

    // Validate person name
    if (person.isEmpty) {
      _showMessage('Required', 'Please enter the person name.');
      return;
    }

    // Validate phone number
    if (phone.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showMessage(
        'Invalid Phone',
        'Enter a valid 10-digit mobile number, or leave it blank.',
      );
      return;
    }

    // Validate amount
    final double? amount = double.tryParse(amountText);

    if (amount == null || !amount.isFinite || amount <= 0) {
      _showMessage(
        'Invalid Amount',
        'Please enter an amount greater than zero.',
      );
      return;
    }

    // Validate interest rate
    final double? interest = double.tryParse(interestText);

    if (interestText.isEmpty ||
        interest == null ||
        !interest.isFinite ||
        interest < 0) {
      _showMessage(
        'Invalid Interest',
        'Please enter a valid fixed interest amount (zero or more).',
      );
      return;
    }

    // Validate dates
    final DateTime? give = giveDate.value;
    final DateTime? repayment = returnDate.value;

    if (give == null) {
      _showMessage('Required', 'Please select the give date.');
      return;
    }

    if (repayment == null) {
      _showMessage('Required', 'Please select the return date.');
      return;
    }

    if (repayment.isBefore(give)) {
      _showMessage('Invalid Date', 'Return date cannot be before give date.');
      return;
    }

    if (!isEditMode.value &&
        (selectedInterestCategoryUuid.value == null ||
            selectedInterestCategoryUuid.value!.isEmpty)) {
      _showMessage(
        'Required',
        'Please select an income category for interest.',
      );
      return;
    }

    if (!isEditMode.value &&
        (selectedSourceAccountUuid.value == null ||
            selectedSourceAccountUuid.value!.isEmpty)) {
      _showMessage('Required', 'Please select the source account.');
      return;
    }

    if (isEditMode.value && editingLendId == null) {
      _showMessage(
        'Unable to update',
        'The selected lend record does not contain an ID.',
      );
      return;
    }

    try {
      isLoading.value = true;

      // All values are strings for multipart form-data.
      final http.Response response;
      if (isEditMode.value) {
        final body = <String, dynamic>{
          'phone': phone,
          'receiveFrom': person,
          'amount': amount.toString(),
          'receiveDate': formatDate(give),
          'rateOfInterest': interest.toString(),
          'returnDate': formatDate(repayment),
          'description': descriptionController.text.trim(),
        };
        final requestUrl = '$url/$editingLendId';
        debugPrint('Legacy lending update URL: $requestUrl');
        response = await apiService.put(requestUrl, body);
      } else {
        final body = <String, dynamic>{
          'borrower_name': person,
          'principal_amount': amount.toStringAsFixed(2),
          'lending_date': formatDate(give),
          'interest_method': interestMethod.value,
          'fixed_interest_amount': interest.toStringAsFixed(2),
          'interest_category_uuid': selectedInterestCategoryUuid.value!,
          'expected_repayment_date': formatDate(repayment),
          'source_account_uuid': selectedSourceAccountUuid.value!,
          'notes': descriptionController.text.trim(),
          if (phone.isNotEmpty) 'borrower_phone': phone,
        };
        final encodedBody = jsonEncode(body);
        if (_pendingLendingIdempotencyKey == null ||
            _pendingLendingRequestBody != encodedBody) {
          _pendingLendingIdempotencyKey = ApiService.createIdempotencyKey();
          _pendingLendingRequestBody = encodedBody;
        }
        debugPrint('Lending API URL: ${ApiService.lendingUrl}');
        debugPrint('Lending request body: $encodedBody');
        response = await apiService.postLending(
          body,
          idempotencyKey: _pendingLendingIdempotencyKey!,
        );
      }

      // Send form-data with the saved Bearer token.
      debugPrint('Lend API status: ${response.statusCode}');
      debugPrint('Lend API response: ${response.body}');

      final Map<String, dynamic> decoded;
      try {
        decoded = _decodeResponse(response);
      } on FormatException catch (error) {
        _showMessage('Server Error', error.message);
        return;
      }

      final String message =
          decoded['message']?.toString() ??
          'Unable to ${isEditMode.value ? 'update' : 'save'} lending details.';

      final bool success =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (isEditMode.value
              ? decoded['status']?.toString().toLowerCase() == 'success'
              : decoded['success'] == true);

      if (success) {
        clearForm();
        _pendingLendingIdempotencyKey = null;
        _pendingLendingRequestBody = null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.back(result: true);
          _showMessage(
            'Success',
            decoded['message']?.toString() ??
                (isEditMode.value
                    ? 'Lending details updated.'
                    : 'Lending details saved.'),
          );
        });
      } else {
        final dynamic errors = decoded['errors'];
        final List<String> details = [];

        if (errors is Map) {
          errors.forEach((key, value) {
            if (value is List) {
              details.addAll(value.map((item) => item.toString()));
            } else {
              details.add(value.toString());
            }
          });
        } else if (errors is List) {
          details.addAll(errors.map((item) => item.toString()));
        }

        debugPrint('Lend API errors: $errors');

        _showMessage(
          'Failed (${response.statusCode})',
          details.isNotEmpty ? details.join('\n') : message,
        );
      }
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('Post lend connection error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(
        'Connection error',
        'The server could not confirm this lending. Check your connection '
            'and try again; your form is unchanged.',
      );
    } catch (e, stackTrace) {
      debugPrint('Post lend error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(
        'Error',
        'Unable to submit lending details. Your form is unchanged; please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Display messages
  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
    );
  }

  // Clear all fields
  void clearForm() {
    personController.clear();
    phoneController.clear();
    amountController.clear();
    interestController.clear();
    descriptionController.clear();

    giveDate.value = null;
    returnDate.value = null;
    editingLendId = null;
    isEditMode.value = false;
  }

  @override
  void onClose() {
    personController.dispose();
    phoneController.dispose();
    amountController.dispose();
    interestController.dispose();
    descriptionController.dispose();

    super.onClose();
  }
}
