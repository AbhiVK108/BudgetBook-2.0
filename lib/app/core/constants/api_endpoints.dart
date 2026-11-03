/// Centralized API hosts and endpoint URLs.
///
/// Keep URL definitions here so changing an API host or reviewing the
/// available API surface does not require searching through controllers.
abstract final class ApiEndpoints {
  // API hosts
  static const String apiBaseUrl = 'https://api.budgetbook.in/api/v1';
  static const String legacyApiBaseUrl = 'https://budgetbook.in/api/api';

  // Auth and account endpoints
  static const String firebaseVerifyUrl = '$apiBaseUrl/auth/firebase/verify';
  static const String refreshTokenUrl = '$apiBaseUrl/auth/refresh-token';
  static const String profileUrl = '$apiBaseUrl/auth/profile';
  static const String legacyVerifyUrl = '$legacyApiBaseUrl/verify';
  static const String customersUrl = '$legacyApiBaseUrl/customers';

  // Dashboard and financial endpoints
  static const String dashboardSummaryUrl = '$apiBaseUrl/dashboard/summary';
  static const String incomeReportUrl = '$apiBaseUrl/reports/income';
  static const String lendingUrl = '$apiBaseUrl/lending';
  static const String lendingSummaryUrl = '$lendingUrl/summary';
  static const String borrowingUrl = '$apiBaseUrl/borrowing';
  static const String loansUrl = '$apiBaseUrl/loans';
  static const String chitsUrl = '$apiBaseUrl/chits';
  static const String chitsSummaryUrl = '$chitsUrl/summary';
  static const String loanSummaryUrl = '$loansUrl/summary';
  static const String upcomingLoanInstallmentsUrl =
      '$apiBaseUrl/loan-installments/upcoming';
  static const String overdueLoanInstallmentsUrl =
      '$apiBaseUrl/loan-installments/overdue';
  static const String upcomingChitInstallmentsUrl =
      '$apiBaseUrl/chit-installments/upcoming';
  static const String overdueChitInstallmentsUrl =
      '$apiBaseUrl/chit-installments/overdue';
  static const String accountsUrl = '$apiBaseUrl/accounts';
  static const String creditCardsUrl = '$apiBaseUrl/credit-cards';
  static const String creditCardsReportUrl = '$apiBaseUrl/reports/credit-cards';
  static const String upcomingCreditCardStatementsUrl =
      '$apiBaseUrl/credit-card-statements/upcoming';
  static const String overdueCreditCardStatementsUrl =
      '$apiBaseUrl/credit-card-statements/overdue';
  static const String transfersUrl = '$apiBaseUrl/transfers';
  static const String categoriesUrl = '$apiBaseUrl/categories';
  static const String incomeTransactionsUrl = '$apiBaseUrl/income';
  static const String expenseTransactionsUrl = '$apiBaseUrl/expenses';
  static const String expenseReportUrl = '$apiBaseUrl/reports/expenses';
  static const String budgetsUrl = '$apiBaseUrl/budgets';
  static const String savingsGoalsUrl = '$apiBaseUrl/savings-goals';
  static const String savingsGoalsSummaryUrl = '$savingsGoalsUrl/summary';

  // Legacy API endpoints still used by older screens.
  static const String legacyReminderUrl = '$legacyApiBaseUrl/reminder';
  static const String legacyCategoriesUrl = '$legacyApiBaseUrl/categories';
  static const String legacyLoansUrl = '$legacyApiBaseUrl/loans';
  static const String legacyCreditUrl = '$legacyApiBaseUrl/credit';
  static const String legacyDebitUrl = '$legacyApiBaseUrl/debit';
  static const String legacyIncomeUrl = '$legacyApiBaseUrl/income';
  static const String legacyExpenseUrl = '$legacyApiBaseUrl/expense';
}
