
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';

class HomeController extends GetxController {
  final ApiService apiService = ApiService();

  final isLoading = false.obs;
  final username = 'User'.obs;

  // Income and Expense Row
  final totalIncome = 0.0.obs;
  final totalExpense = 0.0.obs;

  // Summary Row
  final available = 0.0.obs;
  final debitDue = 0.0.obs;
  final loanDue = 0.0.obs;

  final String apiUrl =
      'https://budgetbook.in/api/api/personal';

  @override
  void onInit() {
    super.onInit();
    loadUsername();
    fetchTotals();
  }

  // Load username saved during login
  Future<void> loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      username.value = prefs.getString('username') ?? 'User';
    } catch (e) {
      print('Error loading username: $e');
    }
  }

  // Convert API values to double
  double toAmount(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  // Fetch Home screen summary API
  Future<void> fetchTotals() async {
    isLoading.value = true;

    try {
      final response = await apiService.get(apiUrl);

      print('Personal API Status: ${response.statusCode}');
      print('Personal API Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result is Map && result['data'] is Map) {
          final data = result['data'];

          totalIncome.value = toAmount(data['income']);
          totalExpense.value = toAmount(data['expense']);

          // Summary Row values
          available.value = toAmount(data['available']);
          debitDue.value = toAmount(data['debitDue']);
          loanDue.value = toAmount(data['loanDue']);

          print('Income: ${totalIncome.value}');
          print('Expense: ${totalExpense.value}');
          print('Available: ${available.value}');
          print('To Pay: ${debitDue.value}');
          print('Lend Back: ${loanDue.value}');
        } else {
          print('Unexpected API response structure');
        }
      } else {
        print('API Error: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('Error fetching personal summary: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
