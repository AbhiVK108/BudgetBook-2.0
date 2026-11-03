import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/loan_chitfund/controllers/loans_controller.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class LoansView extends GetView<LoansController> {
  const LoansView({super.key, this.hideChrome = false});

  final bool hideChrome;

  static const Color _primary = Color(0xFF079B8D);
  static const Color _background = Color(0xFFF6F8F8);
  static const Color _border = Color(0xFFDDECE9);
  static const Color _ink = Color(0xFF263445);
  static const Color _muted = Color(0xFF75828F);

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString().trim() ?? '');
    if (amount == null || !amount.isFinite) return '—';
    return '₹${amount.toStringAsFixed(2)}';
  }

  Widget _statusLabel(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _ink,
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'HankenGrotesk',
        ),
      ),
    );
  }

  Widget _sectionPicker() {
    return Obx(() {
      final selected = controller.selectedSection.value;
      final overdueCount = controller.overdueInstallments.length;
      final upcomingCount = controller.upcomingInstallments.length;
      final options = [
        (label: 'Loans', count: controller.totalRecords.value),
        (label: 'Overdue', count: overdueCount),
        (label: 'Upcoming', count: upcomingCount),
      ];

      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2F1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              for (var index = 0; index < options.length; index++)
                Expanded(
                  child: Material(
                    color: selected == index
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11.r),
                      onTap: () => controller.selectedSection.value = index,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                options[index].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected == index ? _ink : _muted,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'HankenGrotesk',
                                ),
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              options[index].count.toString(),
                              style: TextStyle(
                                color: selected == index ? _primary : _muted,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _loansContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshLoans,
      color: _primary,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 200 && controller.hasMore) {
            controller.loadNextPage();
          }
          return false;
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 90.h),
          children: [
            _loanSummaryPanel(context),
            Container(
              margin: EdgeInsets.only(bottom: 14.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5F3),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: _primary, size: 17.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Creating a loan sets up its contract only. Record a '
                      'separate disbursement when funds are received.',
                      style: TextStyle(color: _ink, fontSize: 11.sp),
                    ),
                  ),
                ],
              ),
            ),
            _loansSectionHeader(),
            if (controller.loans.isEmpty)
              _messageState(
                controller.loadError.value.isEmpty
                    ? 'No loans found.'
                    : controller.loadError.value,
                onRetry: controller.loadError.value.isEmpty
                    ? null
                    : controller.refreshLoans,
              )
            else
              for (final loan in controller.loans) _loanCard(loan),
            if (controller.loadError.value.isNotEmpty &&
                controller.loans.isNotEmpty)
              _inlineError(controller.loadError.value, controller.refreshLoans),
            if (controller.loadMoreError.value.isNotEmpty)
              _inlineError(
                controller.loadMoreError.value,
                controller.loadNextPage,
              )
            else if (controller.hasMore)
              Center(
                child: TextButton(
                  onPressed: controller.loadNextPage,
                  child: Text(
                    controller.isLoadingMore.value ? 'Loading…' : 'Load more',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _loanCard(Map<String, dynamic> loan) {
    final loanName = controller.valueFor(loan, ['name']).trim();
    final lender = controller.valueFor(loan, ['lender_name']).trim();
    final title = loanName.isNotEmpty
        ? loanName
        : lender.isNotEmpty
        ? lender
        : 'Loan';
    final loanType = controller.valueFor(loan, ['loan_type']);
    final principal = controller.valueFor(loan, ['principal_amount']);
    final sanctioned = controller.valueFor(loan, ['sanctioned_amount']);
    final interestRate = controller.valueFor(loan, ['annual_interest_rate']);
    final tenure = controller.valueFor(loan, ['tenure_months']);
    final firstDueDate = controller.valueFor(loan, ['first_due_date']);
    final outstanding = controller.valueFor(loan, [
      'principal_outstanding',
      'outstanding_principal',
      'total_outstanding',
    ]);
    final status = controller.valueFor(loan, ['loan_status', 'status']);
    final nextDueDate = controller.valueFor(loan, [
      'next_due_date',
      'next_installment_due_date',
      'next_emi_date',
    ]);

    final loanUuid = controller.valueFor(loan, [
      'uuid',
      'loan_uuid',
      'loanUuid',
      'id',
    ]);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141BBCAC),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: () async {
              await Get.toNamed(Routes.GET_LOANS, arguments: loan);
              await controller.refreshLoans();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundColor: const Color(0xFFE9F7F4),
                      child: Icon(
                        Icons.account_balance_outlined,
                        color: _primary,
                        size: 21.sp,
                      ),
                    ),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                          if (lender.isNotEmpty && lender != title) ...[
                            SizedBox(height: 2.h),
                            Text(
                              lender,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 11.sp,
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (loanType.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      _typeBadge(loanType),
                    ],
                    if (status.isNotEmpty) ...[
                      SizedBox(width: 6.w),
                      _statusLabel(status),
                    ],
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(11.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFA),
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _loanMetric(
                          'Principal',
                          _money(principal.isEmpty ? sanctioned : principal),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _loanMetric('Sanctioned', _money(sanctioned)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 14.w,
                  runSpacing: 6.h,
                  children: [
                    if (interestRate.isNotEmpty)
                      _detailValue(
                        Icons.percent_rounded,
                        '$interestRate% p.a.',
                      ),
                    if (tenure.isNotEmpty)
                      _detailValue(
                        Icons.calendar_month_outlined,
                        '$tenure months',
                      ),
                    if (firstDueDate.isNotEmpty)
                      _detailValue(
                        Icons.event_outlined,
                        'First due $firstDueDate',
                      ),
                    if (outstanding.isNotEmpty)
                      _detailValue(
                        Icons.account_balance_wallet_outlined,
                        'Outstanding ${_money(outstanding)}',
                      ),
                    if (nextDueDate.isNotEmpty)
                      _detailValue(
                        Icons.event_available_outlined,
                        'Next due $nextDueDate',
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loanUuid.isEmpty ? null : () => _openPayment(loan),
                  icon: const Icon(Icons.payments_outlined, size: 17),
                  label: const Text('Partial EMI payment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    textStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loanUuid.isEmpty
                      ? null
                      : () => _openPrincipalPayment(loan),
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 17,
                  ),
                  label: const Text('Principal payment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _border),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    textStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openPayment(Map<String, dynamic> loan) async {
    final result = await Get.toNamed(
      Routes.LOAN_PAYMENT,
      arguments: {'loan': loan},
    );
    if (result == true) await controller.refreshLoans();
  }

  Future<void> _openPrincipalPayment(Map<String, dynamic> loan) async {
    final result = await Get.toNamed(
      Routes.LOAN_PREPAYMENT,
      arguments: {'loan': loan},
    );
    if (result == true) await controller.refreshLoans();
  }

  Widget _inlineError(String message, VoidCallback onRetry) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.fromLTRB(12.w, 6.h, 6.w, 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F4),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFF4D8D2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFF9B4C3B),
                fontSize: 11.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _installmentsContent({required bool isOverdue}) {
    final title = isOverdue ? 'Overdue instalments' : 'Upcoming instalments';
    final description = isOverdue
        ? 'Payments past their due date. Open a loan to view its repayment schedule.'
        : 'Payments coming up next. Open a loan to view its repayment schedule.';
    final refresh = isOverdue
        ? controller.fetchOverdueInstallments
        : controller.fetchUpcomingInstallments;

    return RefreshIndicator(
      onRefresh: refresh,
      color: _primary,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 90.h),
        children: [
          _installmentSectionHeader(title, description),
          if (isOverdue) _overdueInstallmentsPanel(),
          if (!isOverdue) _upcomingInstallmentsPanel(),
        ],
      ),
    );
  }

  Widget _installmentSectionHeader(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _ink,
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            description,
            style: TextStyle(
              color: _muted,
              fontSize: 11.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectSummaryPeriod(BuildContext context) async {
    if (controller.isLoadingLoanSummary.value) return;
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: controller.summaryFromDate,
        end: controller.summaryToDate,
      ),
      helpText: 'Choose summary period',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (selectedRange != null) {
      await controller.setSummaryPeriod(selectedRange.start, selectedRange.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _sectionPicker(),
        Expanded(
          child: Obx(() {
            final hasInstallmentData =
                controller.overdueInstallments.isNotEmpty ||
                controller.upcomingInstallments.isNotEmpty;
            if (controller.selectedSection.value == 0 &&
                controller.isLoading.value &&
                controller.loans.isEmpty &&
                !hasInstallmentData) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }
            return switch (controller.selectedSection.value) {
              1 => _installmentsContent(isOverdue: true),
              2 => _installmentsContent(isOverdue: false),
              _ => _loansContent(context),
            };
          }),
        ),
      ],
    );

    if (hideChrome) return content;

    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Get.toNamed(Routes.POSTLOAN);
          await controller.refreshLoans();
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Create loan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 16.h),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(22.r),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    tooltip: 'Back',
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      'Loans',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                  Obx(
                    () => IconButton(
                      tooltip: 'Refresh loans',
                      onPressed:
                          controller.isLoading.value ||
                              controller.isLoadingUpcomingInstallments.value ||
                              controller.isLoadingOverdueInstallments.value
                          ? null
                          : controller.refreshLoans,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _loanSummaryPanel(BuildContext context) {
    const metrics = <({String label, List<String> keys, bool money})>[
      (
        label: 'Outstanding',
        keys: [
          'total_outstanding',
          'principal_outstanding',
          'outstanding_amount',
          'outstanding',
        ],
        money: true,
      ),
      (
        label: 'Total principal',
        keys: [
          'total_principal',
          'principal_total',
          'principal_amount',
          'principal',
        ],
        money: true,
      ),
      (
        label: 'Total disbursed',
        keys: [
          'total_disbursed',
          'total_disbursed_amount',
          'disbursed_amount',
          'disbursed',
        ],
        money: true,
      ),
      (
        label: 'Total repaid',
        keys: [
          'total_repaid',
          'total_paid',
          'principal_recovered',
          'paid_amount',
          'repaid_amount',
        ],
        money: true,
      ),
      (
        label: 'Active loans',
        keys: ['active_loans', 'active_loan_count', 'active_count'],
        money: false,
      ),
      (
        label: 'Total loans',
        keys: ['total_loans', 'loan_count', 'total_count'],
        money: false,
      ),
    ];

    return Obx(() {
      final availableMetrics = metrics
          .map((metric) {
            final value = controller.summaryValueFor(metric.keys);
            return (metric: metric, value: value);
          })
          .where((entry) => entry.value != null)
          .toList();

      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF079B8D), Color(0xFF08776F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Portfolio activity for selected dates',
                        style: TextStyle(
                          color: const Color(0xFFD8F4F0),
                          fontSize: 10.sp,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh loan summary',
                  onPressed: controller.isLoadingLoanSummary.value
                      ? null
                      : controller.fetchLoanSummary,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            OutlinedButton.icon(
              onPressed: controller.isLoadingLoanSummary.value
                  ? null
                  : () => _selectSummaryPeriod(context),
              icon: const Icon(Icons.date_range_rounded, size: 17),
              label: Text(controller.summaryPeriodDisplayLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x80FFFFFF)),
                padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
                textStyle: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ),
            if (controller.isLoadingLoanSummary.value &&
                controller.loanSummary.isEmpty) ...[
              SizedBox(height: 14.h),
              const LinearProgressIndicator(
                minHeight: 2,
                color: Colors.white,
                backgroundColor: Color(0x26FFFFFF),
              ),
            ] else if (controller.loanSummaryError.value.isNotEmpty &&
                controller.loanSummary.isEmpty) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.loanSummaryError.value,
                      style: TextStyle(
                        color: const Color(0xFFFFE6E0),
                        fontSize: 12.sp,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.fetchLoanSummary,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ] else if (availableMetrics.isEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                'No loan summary available for this period.',
                style: TextStyle(
                  color: const Color(0xFFD8F4F0),
                  fontSize: 12.sp,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ] else ...[
              Builder(
                builder: (context) {
                  final primaryMetric = availableMetrics.first;
                  final secondaryMetrics = availableMetrics.skip(1).take(4);
                  final primaryValue = primaryMetric.metric.money
                      ? _money(primaryMetric.value)
                      : primaryMetric.value.toString();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 17.h),
                      Text(
                        primaryMetric.metric.label,
                        style: TextStyle(
                          color: const Color(0xFFD8F4F0),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                      SizedBox(height: 3.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          primaryValue,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'HankenGrotesk',
                          ),
                        ),
                      ),
                      if (secondaryMetrics.isNotEmpty) ...[
                        SizedBox(height: 13.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            for (final entry in secondaryMetrics)
                              Container(
                                width: 136.w,
                                padding: EdgeInsets.all(9.w),
                                decoration: BoxDecoration(
                                  color: const Color(0x26FFFFFF),
                                  borderRadius: BorderRadius.circular(11.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.metric.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFFD8F4F0),
                                        fontSize: 10.sp,
                                        fontFamily: 'HankenGrotesk',
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      entry.metric.money
                                          ? _money(entry.value)
                                          : entry.value.toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'HankenGrotesk',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _loansSectionHeader() {
    final total = controller.totalRecords.value;
    return Padding(
      padding: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Your loans',
              style: TextStyle(
                color: _ink,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          Text(
            '$total ${total == 1 ? 'loan' : 'loans'}',
            style: TextStyle(
              color: _muted,
              fontSize: 11.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _overdueInstallmentsPanel() {
    return Obx(() {
      final installments = controller.overdueInstallments;

      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.cardBgWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: installments.isNotEmpty ? const Color(0xFFF2D0CB) : _border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101BBCAC),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EF),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: const Color(0xFFB54735),
                    size: 19.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Overdue installments',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ),
                if (installments.isNotEmpty)
                  Text(
                    '${installments.length} overdue',
                    style: TextStyle(
                      color: const Color(0xFFB54735),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                IconButton(
                  tooltip: 'Refresh overdue installments',
                  onPressed: controller.isLoadingOverdueInstallments.value
                      ? null
                      : controller.fetchOverdueInstallments,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFFB54735),
                  ),
                ),
              ],
            ),
            if (controller.isLoadingOverdueInstallments.value &&
                installments.isEmpty) ...[
              SizedBox(height: 10.h),
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFB54735),
                backgroundColor: Color(0xFFFFF1EF),
              ),
            ] else if (controller.overdueInstallmentsError.value.isNotEmpty &&
                installments.isEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.overdueInstallmentsError.value,
                      style: TextStyle(
                        color: const Color(0xFF9B4C3B),
                        fontSize: 11.sp,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.fetchOverdueInstallments,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ] else if (installments.isEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                'No overdue installments.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12.sp,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ] else ...[
              SizedBox(height: 4.h),
              for (var index = 0; index < installments.length; index++)
                _overdueInstallmentRow(
                  installments[index],
                  isLast: index == installments.length - 1,
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _overdueInstallmentRow(
    Map<String, dynamic> installment, {
    required bool isLast,
  }) {
    final loan = installment['loan'];
    final loanDetails = loan is Map ? Map<String, dynamic>.from(loan) : null;
    final title =
        _firstValue(installment, [
          'loan_name',
          'loan_title',
          'name',
          'lender_name',
        ]) ??
        (loanDetails == null
            ? null
            : _firstValue(loanDetails, ['name', 'loan_name', 'lender_name'])) ??
        'Loan installment';
    final amount = _firstValue(installment, [
      'amount_due',
      'remaining_amount',
      'installment_amount',
      'emi_amount',
      'due_amount',
      'amount',
    ]);
    final dueDate = _firstValue(installment, [
      'due_date',
      'installment_due_date',
      'payment_date',
    ]);
    final daysOverdue = _firstValue(installment, [
      'days_overdue',
      'overdue_days',
    ]);
    final dueLabel = daysOverdue == null
        ? _dueDetails(dueDate).$1
        : 'Overdue by $daysOverdue ${daysOverdue == '1' ? 'day' : 'days'}'
              '${dueDate == null ? '' : ' · ${_dueDetails(dueDate).$1.split(' · ').last}'}';
    final uuid =
        _firstValue(installment, [
          'loan_uuid',
          'loanUuid',
          'loan_id',
          'loanId',
        ]) ??
        (loanDetails == null
            ? null
            : _firstValue(loanDetails, ['uuid', 'loan_uuid', 'id']));

    return InkWell(
      onTap: uuid == null
          ? null
          : () => _openInstallment(
              installment,
              isOverdue: true,
              title: title,
              loanDetails: loanDetails,
              loanUuid: uuid,
            ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEAF0EF))),
              ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    dueLabel,
                    style: TextStyle(
                      color: const Color(0xFFB54735),
                      fontSize: 10.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              _money(amount),
              style: TextStyle(
                color: const Color(0xFFB54735),
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
            if (uuid != null)
              Icon(Icons.chevron_right_rounded, color: _muted, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _upcomingInstallmentsPanel() {
    return Obx(() {
      final installments = controller.upcomingInstallments;

      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.cardBgWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101BBCAC),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F7F4),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: _primary,
                    size: 19.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Upcoming installments',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ),
                if (installments.isNotEmpty)
                  Text(
                    '${installments.length} due',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
              ],
            ),
            if (controller.isLoadingUpcomingInstallments.value &&
                installments.isEmpty) ...[
              SizedBox(height: 14.h),
              const LinearProgressIndicator(
                minHeight: 2,
                color: _primary,
                backgroundColor: Color(0xFFE9F7F4),
              ),
            ] else if (controller.upcomingInstallmentsError.value.isNotEmpty &&
                installments.isEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.upcomingInstallmentsError.value,
                      style: TextStyle(
                        color: const Color(0xFF9B4C3B),
                        fontSize: 11.sp,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.fetchUpcomingInstallments,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ] else if (installments.isEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                'No upcoming installments.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12.sp,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ] else ...[
              SizedBox(height: 8.h),
              for (var index = 0; index < installments.length; index++)
                _upcomingInstallmentRow(
                  installments[index],
                  isLast: index == installments.length - 1,
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _upcomingInstallmentRow(
    Map<String, dynamic> installment, {
    required bool isLast,
  }) {
    final loan = installment['loan'];
    final loanDetails = loan is Map ? Map<String, dynamic>.from(loan) : null;
    final title =
        _firstValue(installment, ['loan_name', 'name', 'loan_title']) ??
        (loanDetails == null
            ? null
            : _firstValue(loanDetails, ['name', 'loan_name', 'lender_name'])) ??
        'Loan installment';
    final amount = _firstValue(installment, [
      'installment_amount',
      'emi_amount',
      'amount',
      'due_amount',
    ]);
    final dueDate = _firstValue(installment, [
      'due_date',
      'installment_due_date',
      'payment_date',
    ]);
    final due = _dueDetails(dueDate);
    final uuid =
        _firstValue(installment, [
          'loan_uuid',
          'loanUuid',
          'loan_id',
          'loanId',
        ]) ??
        (loanDetails == null
            ? null
            : _firstValue(loanDetails, ['uuid', 'loan_uuid', 'id']));

    return InkWell(
      onTap: uuid == null
          ? null
          : () => _openInstallment(
              installment,
              isOverdue: false,
              title: title,
              loanDetails: loanDetails,
              loanUuid: uuid,
            ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEAF0EF))),
              ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    due.$1,
                    style: TextStyle(
                      color: due.$2,
                      fontSize: 10.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              _money(amount),
              style: TextStyle(
                color: _ink,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
            if (uuid != null)
              Icon(Icons.chevron_right_rounded, color: _muted, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _openInstallment(
    Map<String, dynamic> installment, {
    required bool isOverdue,
    required String title,
    required Map<String, dynamic>? loanDetails,
    required String loanUuid,
  }) async {
    Map<String, dynamic>? matchingLoan;
    for (final record in controller.loans) {
      if (controller.valueFor(record, ['uuid', 'loan_uuid', 'id']) ==
          loanUuid) {
        matchingLoan = record;
        break;
      }
    }

    await Get.toNamed(
      Routes.GET_LOANS,
      arguments: {
        ...?matchingLoan,
        ...?loanDetails,
        'uuid': loanUuid,
        'name': title,
        'focus_installment': installment,
        'focus_installment_type': isOverdue ? 'overdue' : 'upcoming',
      },
    );
    await controller.refreshLoans();
  }

  String? _firstValue(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  (String, Color) _dueDetails(String? value) {
    if (value == null) return ('Due date unavailable', _muted);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return (value, _muted);

    final dueDate = DateTime(parsed.year, parsed.month, parsed.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysUntilDue = dueDate.difference(today).inDays;
    final dateLabel =
        '${parsed.day.toString().padLeft(2, '0')} '
        '${_monthName(parsed.month)} ${parsed.year}';
    final relativeLabel = switch (daysUntilDue) {
      < 0 =>
        'Overdue by ${daysUntilDue.abs()} ${daysUntilDue.abs() == 1 ? 'day' : 'days'}',
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $daysUntilDue days',
    };
    final color = daysUntilDue < 0
        ? const Color(0xFFB54735)
        : daysUntilDue <= 3
        ? const Color(0xFFB7791F)
        : _muted;
    return ('$relativeLabel · $dateLabel', color);
  }

  String _monthName(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  Widget _loanMetric(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _muted,
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        SizedBox(height: 3.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: TextStyle(
              color: _ink,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailValue(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _primary, size: 14.sp),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            color: _muted,
            fontSize: 10.sp,
            fontFamily: 'HankenGrotesk',
          ),
        ),
      ],
    );
  }

  Widget _typeBadge(String loanType) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7F4),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        loanType.replaceAll('_', ' '),
        style: TextStyle(
          color: _primary,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'HankenGrotesk',
        ),
      ),
    );
  }

  Widget _messageState(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined, color: _primary, size: 34.sp),
            SizedBox(height: 10.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 13.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 12.h),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
