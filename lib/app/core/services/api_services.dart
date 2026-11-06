import 'dart:convert';
import 'dart:math';

import 'package:budget_book_2026/app/core/constants/api_endpoints.dart';
import 'package:budget_book_2026/app/core/services/auth_credential_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const Duration requestTimeout = Duration(seconds: 30);

  ApiService({http.Client? client, AuthCredentialStorage? credentialStorage})
    : _client = client ?? http.Client(),
      _credentialStorage = credentialStorage ?? SecureAuthCredentialStorage();

  // Kept as compatibility aliases for existing callers. URL definitions live
  // in ApiEndpoints so this service remains focused on HTTP behavior.
  static const firebaseVerifyUrl = ApiEndpoints.firebaseVerifyUrl;
  static const refreshTokenUrl = ApiEndpoints.refreshTokenUrl;
  static const profileUrl = ApiEndpoints.profileUrl;
  static const dashboardSummaryUrl = ApiEndpoints.dashboardSummaryUrl;
  static const incomeReportUrl = ApiEndpoints.incomeReportUrl;
  static const lendingUrl = ApiEndpoints.lendingUrl;
  static const lendingSummaryUrl = ApiEndpoints.lendingSummaryUrl;
  static const borrowingUrl = ApiEndpoints.borrowingUrl;
  static const loansUrl = ApiEndpoints.loansUrl;
  static const chitsUrl = ApiEndpoints.chitsUrl;
  static const chitsSummaryUrl = ApiEndpoints.chitsSummaryUrl;
  static const loanSummaryUrl = ApiEndpoints.loanSummaryUrl;
  static const upcomingLoanInstallmentsUrl =
      ApiEndpoints.upcomingLoanInstallmentsUrl;
  static const overdueLoanInstallmentsUrl =
      ApiEndpoints.overdueLoanInstallmentsUrl;
  static const upcomingChitInstallmentsUrl =
      ApiEndpoints.upcomingChitInstallmentsUrl;
  static const overdueChitInstallmentsUrl =
      ApiEndpoints.overdueChitInstallmentsUrl;
  static const accountsUrl = ApiEndpoints.accountsUrl;
  static const creditCardsUrl = ApiEndpoints.creditCardsUrl;
  static const creditCardsReportUrl = ApiEndpoints.creditCardsReportUrl;
  static const upcomingCreditCardStatementsUrl =
      ApiEndpoints.upcomingCreditCardStatementsUrl;
  static const overdueCreditCardStatementsUrl =
      ApiEndpoints.overdueCreditCardStatementsUrl;
  static const transfersUrl = ApiEndpoints.transfersUrl;
  static const categoriesUrl = ApiEndpoints.categoriesUrl;
  static const incomeTransactionsUrl = ApiEndpoints.incomeTransactionsUrl;
  static const expenseTransactionsUrl = ApiEndpoints.expenseTransactionsUrl;
  static const expenseReportUrl = ApiEndpoints.expenseReportUrl;
  static const budgetsUrl = ApiEndpoints.budgetsUrl;
  static const savingsGoalsUrl = ApiEndpoints.savingsGoalsUrl;
  static const savingsGoalsSummaryUrl = ApiEndpoints.savingsGoalsSummaryUrl;

  final http.Client _client;
  final AuthCredentialStorage _credentialStorage;
  Future<String?>? _refreshInProgress;

  Future<T> _withTimeout<T>(Future<T> request) =>
      request.timeout(requestTimeout);

  // ================= SAVE TOKEN =================

  Future<void> saveToken(String token) async {
    await _credentialStorage.write('accessToken', token);
  }

  Future<void> saveAuthCredentials({
    String? accessToken,
    String? userId,
    String? roleId,
    String? refreshToken,
  }) async {
    final credentials = <String, String?>{
      'accessToken': accessToken,
      'userId': userId,
      'roleId': roleId,
      'refreshToken': refreshToken,
    };
    for (final entry in credentials.entries) {
      final value = entry.value;
      if (value != null && value.isNotEmpty) {
        await _credentialStorage.write(entry.key, value);
      } else {
        await _credentialStorage.delete(entry.key);
      }
    }
  }

  Future<void> logout() => saveAuthCredentials(
    accessToken: null,
    userId: null,
    roleId: null,
    refreshToken: null,
  );

  // ================= GET TOKEN =================

  Future<String?> getToken() async {
    final token = await _credentialStorage.read('accessToken');
    if (token != null && token.isNotEmpty) return token;

    // Migrate an access token saved by older app versions.
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString('accessToken');
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _credentialStorage.write('accessToken', legacyToken);
      await prefs.remove('accessToken');
      return legacyToken;
    }
    return null;
  }

  Future<String?> getUserId() => _credentialStorage.read('userId');

  Future<String?> getRoleId() => _credentialStorage.read('roleId');

  Future<String?> getRefreshToken() => _credentialStorage.read('refreshToken');

  Future<bool> restoreSession() async {
    final accessToken = await getToken();
    if (accessToken != null && accessToken.isNotEmpty) return true;

    final refreshedToken = await refreshAccessToken();
    return refreshedToken != null && refreshedToken.isNotEmpty;
  }

  // ================= HEADERS =================

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();

    return _headersFor(token);
  }

  Map<String, String> _headersFor(String? token) {
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",

      if (token != null && token.isNotEmpty) "Authorization": "Bearer " + token,
    };
  }

  static String createIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function(String? token) send,
  ) async {
    final token = await getToken();
    final response = await send(token);
    if (response.statusCode != 401) return response;

    final latestToken = await getToken();
    if (latestToken != null && latestToken.isNotEmpty && latestToken != token) {
      return send(latestToken);
    }

    final String? refreshedToken;
    try {
      refreshedToken = await refreshAccessToken();
    } catch (_) {
      return response;
    }
    if (refreshedToken == null) return response;
    return send(refreshedToken);
  }

  Future<String?> refreshAccessToken() {
    final pendingRefresh = _refreshInProgress;
    if (pendingRefresh != null) return pendingRefresh;

    late final Future<String?> refresh;
    refresh = _performTokenRefresh().whenComplete(() {
      if (identical(_refreshInProgress, refresh)) {
        _refreshInProgress = null;
      }
    });
    _refreshInProgress = refresh;
    return refresh;
  }

  Future<String?> _performTokenRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final http.Response response;
    try {
      response = await _withTimeout(
        _client.post(
          Uri.parse(refreshTokenUrl),
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
          body: jsonEncode({'refresh_token': refreshToken}),
        ),
      );
    } catch (_) {
      return null;
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      if (Get.key.currentState != null &&
          Get.currentRoute != '/login' &&
          Get.currentRoute != '/session-gate') {
        await Get.offAllNamed('/login');
      }
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      return null;
    }
    if (decoded is! Map || decoded['success'] == false) return null;

    final payload = Map<String, dynamic>.from(decoded);
    final dataValue = payload['data'];
    final data = dataValue is Map
        ? Map<String, dynamic>.from(dataValue)
        : payload;
    final tokensValue = data['tokens'] ?? payload['tokens'];
    final tokens = tokensValue is Map
        ? Map<String, dynamic>.from(tokensValue)
        : data;
    final accessToken =
        (tokens['access_token'] ??
                tokens['accessToken'] ??
                tokens['token'] ??
                data['access_token'] ??
                data['accessToken'] ??
                data['token'] ??
                payload['access_token'] ??
                payload['accessToken'] ??
                payload['token'])
            ?.toString();
    if (accessToken == null || accessToken.isEmpty) return null;

    await saveToken(accessToken);
    final newRefreshToken =
        (tokens['refresh_token'] ??
                tokens['refreshToken'] ??
                data['refresh_token'] ??
                data['refreshToken'] ??
                payload['refresh_token'] ??
                payload['refreshToken'])
            ?.toString();
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
      await _credentialStorage.write('refreshToken', newRefreshToken);
    }
    return accessToken;
  }

  Future<http.Response> postWithIdempotency(
    String url,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => _sendWithRefresh((token) {
    final headers = _headersFor(token);
    headers['Idempotency-Key'] = idempotencyKey;
    return _withTimeout(
      _client.post(Uri.parse(url), headers: headers, body: jsonEncode(body)),
    );
  });

  // ================= GET =================

  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return _withTimeout(
      _client.post(Uri.parse(url), headers: headers, body: jsonEncode(body)),
    );
  }

  Future<http.Response> postWithoutToken(
    String url,
    Map<String, dynamic> body,
  ) async {
    return _withTimeout(
      _client.post(
        Uri.parse(url),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> postFormDataWithoutToken(
    String url,
    Map<String, String> fields,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields.addAll(fields)
      ..headers['Accept'] = 'application/json';
    return http.Response.fromStream(await _withTimeout(request.send()));
  }

  Future<http.Response> postFormData(
    String url,
    Map<String, String> fields,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields.addAll(fields)
      ..headers['Accept'] = 'application/json';
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ' + token;
    }
    return http.Response.fromStream(await _withTimeout(request.send()));
  }

  Future<http.Response> postCategory(Map<String, dynamic> body) =>
      post(categoriesUrl, body);

  Future<http.Response> postCreditCard(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) =>
      postWithIdempotency(creditCardsUrl, body, idempotencyKey: idempotencyKey);

  Future<http.Response> postExpense(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(
    expenseTransactionsUrl,
    body,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> postBudget(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(budgetsUrl, body, idempotencyKey: idempotencyKey);

  Future<http.Response> postSavingsGoal(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(
    savingsGoalsUrl,
    body,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> postSavingsGoalContribution(
    String savingsGoalUuid,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(
    '$savingsGoalsUrl/${Uri.encodeComponent(savingsGoalUuid)}/contributions',
    body,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> getSavingsGoals() => get(savingsGoalsUrl);

  Future<http.Response> getSavingsGoalsSummary() =>
      get(ApiEndpoints.savingsGoalsSummaryUrl);

  Future<http.Response> getSavingsGoalSummary(String savingsGoalUuid) =>
      get('$savingsGoalsUrl/${Uri.encodeComponent(savingsGoalUuid)}/summary');

  Future<http.Response> getBudgets() => get(budgetsUrl);

  Future<http.Response> getBudgetSpending(String budgetUuid) =>
      get('$budgetsUrl/${Uri.encodeComponent(budgetUuid)}/spending');

  Future<http.Response> getBudgetSummary(String budgetUuid) =>
      get('$budgetsUrl/${Uri.encodeComponent(budgetUuid)}/summary');

  Future<http.Response> postBudgetCategory(
    String budgetUuid,
    Map<String, dynamic> body,
  ) => postWithIdempotency(
    '$budgetsUrl/${Uri.encodeComponent(budgetUuid)}/categories',
    body,
    idempotencyKey: createIdempotencyKey(),
  );

  Future<http.Response> get(String url) => _sendWithRefresh(
    (token) =>
        _withTimeout(_client.get(Uri.parse(url), headers: _headersFor(token))),
  );
  Future<http.Response> put(String url, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return _withTimeout(
      _client.put(Uri.parse(url), headers: headers, body: jsonEncode(body)),
    );
  }

  Future<http.Response> delete(String url) async {
    return _sendWithRefresh(
      (token) => _withTimeout(
        _client.delete(Uri.parse(url), headers: _headersFor(token)),
      ),
    );
  }

  Future<http.Response> getAccounts({bool includeArchived = false}) {
    final uri = Uri.parse(accountsUrl);
    final requestUri = includeArchived
        ? uri.replace(queryParameters: {'include_archived': '1'})
        : uri;
    return get(requestUri.toString());
  }

  Future<http.Response> getCreditCards() => get(creditCardsUrl);

  Future<http.Response> getCreditCardsReport() => get(creditCardsReportUrl);

  Future<http.Response> getUpcomingCreditCardStatements() =>
      get(upcomingCreditCardStatementsUrl);

  Future<http.Response> getOverdueCreditCardStatements() =>
      get(overdueCreditCardStatementsUrl);

  Future<http.Response> getTransfers({int page = 1, int perPage = 20}) {
    final uri = Uri.parse(
      transfersUrl,
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    return get(uri.toString());
  }

  Future<http.Response> getLending({int page = 1, int perPage = 20}) {
    final uri = Uri.parse(
      lendingUrl,
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    return get(uri.toString());
  }

  Future<http.Response> getLendingSummary() => get(lendingSummaryUrl);

  Future<http.Response> getBorrowing({int page = 1, int perPage = 20}) {
    final uri = Uri.parse(
      borrowingUrl,
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    return get(uri.toString());
  }

  Future<http.Response> getBorrowingSummary() => get('$borrowingUrl/summary');

  Future<http.Response> getLoans({int page = 1, int perPage = 20}) {
    final uri = Uri.parse(
      loansUrl,
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    return get(uri.toString());
  }

  Future<http.Response> getChits({int page = 1, int perPage = 20}) {
    final uri = Uri.parse(
      chitsUrl,
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    return get(uri.toString());
  }

  Future<http.Response> getChitsSummary() => get(chitsSummaryUrl);

  Future<http.Response> getLoanSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    String formatDate(DateTime date) {
      final year = date.year.toString().padLeft(4, '0');
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }

    final uri = Uri.parse(loanSummaryUrl).replace(
      queryParameters: {
        'from_date': formatDate(fromDate),
        'to_date': formatDate(toDate),
      },
    );
    return get(uri.toString());
  }

  Future<http.Response> getUpcomingLoanInstallments() =>
      get(upcomingLoanInstallmentsUrl);
  Future<http.Response> getUpcomingChitInstallments() =>
      get(upcomingChitInstallmentsUrl);
  Future<http.Response> getOverdueLoanInstallments() =>
      get(overdueLoanInstallmentsUrl);
  Future<http.Response> getOverdueChitInstallments() =>
      get(overdueChitInstallmentsUrl);

  Future<http.Response> getLoanByUuid(String loanUuid) {
    final baseUri = Uri.parse(loansUrl);
    final uri = baseUri.replace(
      pathSegments: [...baseUri.pathSegments, loanUuid],
    );
    return get(uri.toString());
  }

  Future<http.Response> getLoanPayments(
    String loanUuid, {
    int page = 1,
    int perPage = 20,
  }) {
    final baseUri = Uri.parse(loansUrl);
    final uri = baseUri.replace(
      pathSegments: [...baseUri.pathSegments, loanUuid, 'payments'],
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
    );
    return get(uri.toString());
  }

  Future<http.Response> getLoanSchedule(String loanUuid) {
    final baseUri = Uri.parse(loansUrl);
    final uri = baseUri.replace(
      pathSegments: [...baseUri.pathSegments, loanUuid, 'schedule'],
    );
    return get(uri.toString());
  }

  Future<http.Response> getLendingByUuid(String lendingUuid) {
    final uri = Uri.parse(lendingUrl).replace(
      pathSegments: [...Uri.parse(lendingUrl).pathSegments, lendingUuid],
    );
    return get(uri.toString());
  }

  Future<http.Response> getLendingRepayments(String lendingUuid) {
    final baseUri = Uri.parse(lendingUrl);
    final uri = baseUri.replace(
      pathSegments: [...baseUri.pathSegments, lendingUuid, 'repayments'],
    );
    return get(uri.toString());
  }

  Future<http.Response> getBorrowingRepayments(String borrowingUuid) {
    final baseUri = Uri.parse(borrowingUrl);
    final uri = baseUri.replace(
      pathSegments: [...baseUri.pathSegments, borrowingUuid, 'repayments'],
    );
    return get(uri.toString());
  }

  Future<http.Response> verifyFirebasePhone({
    required String idToken,
    String? phoneNumber,
    String? fullName,
  }) => postWithoutToken(firebaseVerifyUrl, {
    'id_token': idToken,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (fullName != null) 'full_name': fullName,
  });
  Future<http.Response> getDashboardSummary({
    String period = 'this_month',
    int? month,
    int? year,
  }) {
    final uri = Uri.parse(dashboardSummaryUrl).replace(
      queryParameters: {
        'period': period,
        if (month != null) 'month': month.toString(),
        if (year != null) 'year': year.toString(),
      },
    );
    return get(uri.toString());
  }

  Future<http.Response> getChitSummary(String uuid) =>
      get('$chitsUrl/$uuid/summary');
  Future<http.Response> getCreditCardSummary(String uuid) =>
      get('$creditCardsUrl/${Uri.encodeComponent(uuid)}/summary');
  Future<http.Response> getCreditCardTransactions(String uuid) =>
      get('$creditCardsUrl/${Uri.encodeComponent(uuid)}/transactions');
  Future<http.Response> postCreditCardTransaction(
    String uuid,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(
    '$creditCardsUrl/${Uri.encodeComponent(uuid)}/transactions',
    body,
    idempotencyKey: idempotencyKey,
  );
  Future<http.Response> getChitPayouts(
    String uuid, {
    int page = 1,
    int perPage = 20,
  }) => get(
    Uri.parse('$chitsUrl/$uuid/payouts')
        .replace(queryParameters: {'page': '$page', 'per_page': '$perPage'})
        .toString(),
  );

  Future<http.Response> postTransfer(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(transfersUrl, body, idempotencyKey: idempotencyKey);

  Future<http.Response> postIncome(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(
    incomeTransactionsUrl,
    body,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> updateIncome(
    String incomeUuid,
    Map<String, dynamic> body,
  ) => put('$incomeTransactionsUrl/${Uri.encodeComponent(incomeUuid)}', body);

  Future<http.Response> deleteIncome(String incomeUuid) =>
      delete('$incomeTransactionsUrl/${Uri.encodeComponent(incomeUuid)}');

  Future<http.Response> postLending(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) =>
      _postAgreementWithRetry(lendingUrl, body, idempotencyKey: idempotencyKey);

  Future<http.Response> postBorrowing(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(borrowingUrl, body, idempotencyKey: idempotencyKey);

  Future<http.Response> postLoan(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(loansUrl, body, idempotencyKey: idempotencyKey);

  Future<http.Response> postChit(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => postWithIdempotency(chitsUrl, body, idempotencyKey: idempotencyKey);

  Future<http.Response> postChitAuction(
    String chitUuid,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) => _postAction(
    '$chitsUrl/${Uri.encodeComponent(chitUuid)}/auctions',
    body,
    idempotencyKey,
  );
  Future<http.Response> postChitPayout(
    String chitUuid,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) => _postAction(
    '$chitsUrl/${Uri.encodeComponent(chitUuid)}/payouts',
    body,
    idempotencyKey,
  );
  Future<http.Response> postChitPayoutReceive(
    String chitUuid,
    String payoutUuid,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) => _postAction(
    '$chitsUrl/${Uri.encodeComponent(chitUuid)}/payouts/${Uri.encodeComponent(payoutUuid)}/receive',
    body,
    idempotencyKey,
  );
  Future<http.Response> _postAction(
    String url,
    Map<String, dynamic> body,
    String? key,
  ) => key == null || key.isEmpty
      ? post(url, body)
      : postWithIdempotency(url, body, idempotencyKey: key);

  Future<http.Response> postLoanDisbursement(
    String loanUuid,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => _postAgreementWithRetry(
    '$loansUrl/${Uri.encodeComponent(loanUuid)}/disbursements',
    body,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> postLoanPrepayment(
    String loanUuid,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => _postAgreementWithRetry(
    '$loansUrl/${Uri.encodeComponent(loanUuid)}/prepayments',
    body,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> postLoanPayment(
    String loanUuid,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => _postAgreementWithRetry(
    '$loansUrl/${Uri.encodeComponent(loanUuid)}/payments',
    body,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> postLendingRepayment(
    String lendingUuid,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => _postAgreementWithRetry(
    '$lendingUrl/${Uri.encodeComponent(lendingUuid)}/repayments',
    body,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> postBorrowingRepayment(
    String borrowingUuid,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => _postAgreementWithRetry(
    '$borrowingUrl/${Uri.encodeComponent(borrowingUuid)}/repayments',
    body,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> _postAgreementWithRetry(
    String url,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await postWithIdempotency(
        url,
        body,
        idempotencyKey: idempotencyKey,
      );
    } on http.ClientException {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return postWithIdempotency(url, body, idempotencyKey: idempotencyKey);
    }
  }
}
