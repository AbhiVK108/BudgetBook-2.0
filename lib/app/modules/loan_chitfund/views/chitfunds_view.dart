import 'dart:convert';

import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/modules/get_chitfunds/controllers/get_chitfunds_controller.dart';
import 'package:budget_book_2026/app/modules/get_chitfunds/controllers/chit_summary_controller.dart';
import 'package:budget_book_2026/app/modules/get_chitfunds/views/chit_summary_view.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/chitfunds_controller.dart';

class ChitfundView extends GetView<ChitfundController> {
  const ChitfundView({super.key, this.hideChrome = false});
  final bool hideChrome;
  static const _primary = Color(0xFF079B8D);

  @override
  Widget build(BuildContext context) {
    final chitController = Get.find<GetChitfundsController>();
    final selectedSection = 0.obs;

    Future<void> refreshAll() async {
      await chitController.refreshChits();
      await controller.refreshSummary();
      await controller.fetchOverdueInstallments();
      await controller.fetchUpcomingInstallments();
    }

    final content = RefreshIndicator(
      onRefresh: refreshAll,
      color: _primary,
      child: Obx(() {
        if (chitController.isLoading.value && chitController.chits.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        return ListView(
          padding: EdgeInsets.only(bottom: 96.h),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
              child: Text(
                'Chit fund overview',
                style: TextStyle(
                  color: const Color(0xFF263445),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ),
            _sectionPicker(selectedSection, chitController),
            if (selectedSection.value == 0 && chitController.chits.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 30.h),
                child: _emptyState(),
              )
            else if (selectedSection.value == 0) ...[
              // _summaryPanel(),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                child: Text(
                  'Your chit funds',
                  style: TextStyle(
                    color: const Color(0xFF263445),
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
              for (final chit in chitController.chits)
                _chitCard(chit, chitController),
            ] else if (selectedSection.value == 1) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Text(
                  'Overdue instalments',
                  style: TextStyle(
                    color: const Color(0xFF263445),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _overduePanel(),
              ),
            ] else ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Text(
                  'Upcoming instalments',
                  style: TextStyle(
                    color: const Color(0xFF263445),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _upcomingPanel(),
              ),
            ],
          ],
        );
      }),
    );

    if (hideChrome) {
      return SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F8),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Get.toNamed(Routes.POSTCHITFUND);
          await chitController.refreshChits();
          await controller.refreshSummary();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create chit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _sectionPicker(
    RxInt selectedSection,
    GetChitfundsController chitController,
  ) {
    return Obx(() {
      final options = [
        ('Chits', chitController.chits.length),
        ('Overdue', controller.overdueInstallments.length),
        ('Upcoming', controller.upcomingInstallments.length),
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
                    color: selectedSection.value == index
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11.r),
                      onTap: () => selectedSection.value = index,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                options[index].$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selectedSection.value == index
                                      ? const Color(0xFF263445)
                                      : const Color(0xFF75828F),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'HankenGrotesk',
                                ),
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              options[index].$2.toString(),
                              style: TextStyle(
                                color: selectedSection.value == index
                                    ? _primary
                                    : const Color(0xFF75828F),
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

  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 48.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68.w,
            height: 68.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F7F4),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Icon(Icons.savings_outlined, color: _primary, size: 32.sp),
          ),
          SizedBox(height: 14.h),
          Text(
            'No chit funds yet',
            style: TextStyle(
              color: const Color(0xFF263445),
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'Create a chit fund to track contributions, auctions and payouts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF75828F),
              fontSize: 12.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(Routes.POSTCHITFUND),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create your first chit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 16.h),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22.r)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              'Chit Funds',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh chit funds',
            onPressed: () async {
              await Get.find<GetChitfundsController>().refreshChits();
              await controller.refreshSummary();
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _summaryPanel() {
    return Obx(() {
      if (controller.summaryError.value.isNotEmpty &&
          controller.summary.isEmpty) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: _inlineMessage(
            controller.summaryError.value,
            onRetry: controller.refreshSummary,
          ),
        );
      }

      final total = _number(controller.summary['total_chit_value']);
      final paid = _number(
        controller.summary['paid_amount'] ??
            controller.summary['total_contributed'],
      );
      final due = _number(controller.summary['due_amount']);
      final completed = _number(controller.summary['completed_amount']);
      final payouts = _asMaps(controller.summary['payouts']);

      return Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFDDECE9)),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _totalTile('Total', total, const Color(0xFF00A878)),
                  SizedBox(width: 6.w),
                  _totalTile('Pay', paid, const Color(0xFFFF1515)),
                  SizedBox(width: 6.w),
                  _totalTile('Due', due, const Color(0xFFFF995B)),
                  SizedBox(width: 6.w),
                  _totalTile('Completed', completed, const Color(0xFF00C987)),
                ],
              ),
            ),
            const Text('Total chits', style: TextStyle(fontSize: 0, height: 0)),
            const Text(
              'Overdue instalments',
              style: TextStyle(fontSize: 0, height: 0),
            ),
            const Text(
              'Upcoming instalments',
              style: TextStyle(fontSize: 0, height: 0),
            ),
            const Text('Payouts', style: TextStyle(fontSize: 0, height: 0)),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Financial summary',
                    style: TextStyle(
                      color: const Color(0xFF263445),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _primary,
                  size: 19.sp,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _summaryMetric('Total value', _moneyGrouped(total)),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _summaryMetric(
                    'Paid / contributed',
                    _moneyAmount(paid),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _summaryMetric(
                    'Amount due',
                    _moneyAmount(due),
                    valueColor: const Color(0xFFB54735),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _summaryMetric(
                    'Completed',
                    _moneyAmount(completed),
                    valueColor: _primary,
                  ),
                ),
              ],
            ),
            if (payouts.isNotEmpty) ...[
              SizedBox(height: 14.h),
              const Divider(height: 1, color: Color(0xFFEAF0EF)),
              SizedBox(height: 10.h),
              Text(
                'Recent payouts',
                style: TextStyle(
                  color: const Color(0xFF263445),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
              for (final payout in payouts.take(3))
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          payout['payout_name']?.toString() ?? 'Payout',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF75828F),
                            fontSize: 11.sp,
                            fontFamily: 'HankenGrotesk',
                          ),
                        ),
                      ),
                      Text(
                        '₹${payout['payout_amount']?.toString() ?? '0.00'}',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _summaryMetric(
    String label,
    String amount, {
    Color valueColor = const Color(0xFF263445),
  }) {
    return Container(
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFDDECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF75828F),
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 5.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹$amount',
              style: TextStyle(
                color: valueColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineMessage(String message, {VoidCallback? onRetry}) {
    return Container(
      padding: EdgeInsets.all(12.w),
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
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _totalTile(String label, double amount, Color color) {
    return Container(
      width: 78.w,
      height: 72.h,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 11.sp),
          ),
          if (label == 'Total')
            const Text(
              'TOTAL CHIT VALUE',
              style: TextStyle(fontSize: 0, height: 0),
            ),
          SizedBox(height: 3.h),
          Text(
            '₹${_moneyAmount(amount)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overduePanel() => _installmentPanel(
    title: 'Overdue installments',
    items: controller.overdueInstallments,
    loading: controller.isLoadingOverdueInstallments,
    error: controller.overdueInstallmentsError,
    onRefresh: controller.fetchOverdueInstallments,
    overdue: true,
  );

  Widget _upcomingPanel() => _installmentPanel(
    title: 'Upcoming installments',
    items: controller.upcomingInstallments,
    loading: controller.isLoadingUpcomingInstallments,
    error: controller.upcomingInstallmentsError,
    onRefresh: controller.fetchUpcomingInstallments,
    overdue: false,
  );

  Widget _installmentPanel({
    required String title,
    required List<Map<String, dynamic>> items,
    required RxBool loading,
    required RxString error,
    required Future<void> Function() onRefresh,
    required bool overdue,
  }) {
    return Obx(
      () => Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: overdue && items.isNotEmpty
                ? const Color(0xFFF2D0CB)
                : const Color(0xFFE4ECEB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 8.h),
              child: Row(
                children: [
                  Icon(
                    overdue
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_month_rounded,
                    color: overdue ? const Color(0xFFB54735) : _primary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'HankenGrotesk',
                        color: const Color(0xFF263445),
                      ),
                    ),
                  ),
                  if (items.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: Text(
                        '${items.length} ${overdue ? 'overdue' : 'due'}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: overdue ? const Color(0xFFB54735) : _primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: loading.value ? null : onRefresh,
                    tooltip: 'Refresh $title',
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 20.sp,
                      color: overdue ? const Color(0xFFB54735) : _primary,
                    ),
                  ),
                ],
              ),
            ),
            if (loading.value && items.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 16.h),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: overdue ? const Color(0xFFB54735) : _primary,
                ),
              )
            else if (error.value.isNotEmpty && items.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 4.h, 8.w, 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        error.value,
                        style: const TextStyle(
                          color: Color(0xFF9B4C3B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onRefresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 16.h),
                child: Text(
                  overdue
                      ? 'No overdue chit installments.'
                      : 'No upcoming chit installments.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.sp,
                  ),
                ),
              )
            else
              for (var index = 0; index < items.length; index++)
                _installmentRow(
                  items[index],
                  isLast: index == items.length - 1,
                  overdue: overdue,
                ),
          ],
        ),
      ),
    );
  }

  Widget _installmentRow(
    Map<String, dynamic> installment, {
    required bool isLast,
    required bool overdue,
  }) {
    final chitData = installment['chit'];
    final chit = chitData is Map
        ? Map<String, dynamic>.from(chitData)
        : <String, dynamic>{};
    String? first(List<String> keys, Map<String, dynamic> map) {
      for (final key in keys) {
        final value = map[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    final title =
        first(const ['chit_name', 'name', 'title'], installment) ??
        first(const ['name', 'chit_name'], chit) ??
        'Chit installment';
    final amount = first(const [
      'amount_due',
      'remaining_amount',
      'installment_amount',
      'due_amount',
      'contribution_amount',
      'amount',
    ], installment);
    final dueDate = first(const [
      'due_date',
      'installment_due_date',
      'payment_date',
    ], installment);
    final number = first(const [
      'installment_number',
      'number',
      'sequence',
    ], installment);
    final days = first(const [
      'days_overdue',
      'overdue_days',
      'days_past_due',
    ], installment);
    final date = dueDate == null
        ? ''
        : DateTime.tryParse(dueDate)?.toString().substring(0, 10) ?? dueDate;
    final label = overdue && days != null
        ? 'Overdue by $days ${days == '1' ? 'day' : 'days'}${date.isEmpty ? '' : ' · $date'}'
        : [
            if (date.isNotEmpty) date,
            if (number != null) 'Installment $number',
          ].join(' · ');
    final parsedAmount = double.tryParse(amount ?? '');
    final amountText = parsedAmount == null
        ? (amount ?? 'Amount pending')
        : '₹${parsedAmount.toStringAsFixed(2)}';
    final color = overdue ? const Color(0xFFB54735) : const Color(0xFF173B38);
    return Container(
      margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, isLast ? 14.h : 0),
      padding: EdgeInsets.symmetric(vertical: 11.h),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F3F3))),
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
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  label.isEmpty ? 'Payment schedule' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: overdue ? color : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chitCard(
    Map<String, dynamic> chit,
    GetChitfundsController chitController,
  ) {
    final uuid = _value(chit, const ['uuid', 'chit_uuid', 'id']);
    final name = _value(chit, const ['name', 'chit_name']);
    final organizer = _value(chit, const ['organizer_name', 'organizer']);
    final status = _value(chit, const ['status', 'state']);
    final totalValue = _number(
      chit['total_value'] ?? chit['chit_value'] ?? chit['amount'],
    );
    final start = _value(chit, const ['start_date', 'start']);
    final end = _value(chit, const ['end_date', 'end']);
    final liftAmount = _number(
      chit['lift_amount'] ?? chit['payout_amount'] ?? chit['monthly_amount'],
    );
    final beforeLift = _number(chit['before_lift'] ?? chit['paid_amount']);
    final afterLift = _number(chit['after_lift'] ?? chit['remaining_amount']);
    final members = _value(chit, const ['members_count', 'members']);
    final duration = _value(chit, const ['duration', 'duration_months']);
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDDECE9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101BBCAC),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: uuid.isEmpty
            ? null
            : () {
                Get.put(
                  ChitSummaryController(
                    chitUuid: uuid,
                    chit: chit,
                    apiService: chitController.apiService,
                  ),
                );
                Get.to(() => const ChitSummaryView());
              },
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB9F5DD),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00B77A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      name.isEmpty ? 'Chit fund' : name,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _statusPill(status.isEmpty ? 'Completed' : status),
                  SizedBox(width: 4.w),
                  PopupMenuButton<String>(
                    tooltip: 'Chit options',
                    onSelected: (action) {
                      if (uuid.isEmpty) return;
                      if (action == 'auction')
                        _auctionSheet(
                          uuid,
                          name,
                          chit,
                          chitController.apiService,
                        );
                      if (action == 'payout')
                        _payoutSheet(uuid, name, chitController.apiService);
                      if (action == 'receive')
                        _receiveSheet(
                          uuid,
                          name,
                          chit,
                          chitController.apiService,
                        );
                      if (action == 'edit')
                        Get.toNamed(Routes.POSTCHITFUND, arguments: chit);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'auction',
                        child: Text('Record auction'),
                      ),
                      PopupMenuItem(
                        value: 'payout',
                        child: Text('Create payout'),
                      ),
                      PopupMenuItem(
                        value: 'receive',
                        child: Text('Receive payout'),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'edit', child: Text('Edit chit')),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  if (duration.isNotEmpty)
                    _metaChip(Icons.access_time, '$duration Months'),
                  if (duration.isNotEmpty && members.isNotEmpty)
                    SizedBox(width: 8.w),
                  if (members.isNotEmpty)
                    _metaChip(Icons.people_outline, '$members Members'),
                  if (organizer.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Organizer: $organizer',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 18.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TOTAL VALUE',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF7B8B99),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '₹${_moneyAmount(totalValue)}',
                    style: TextStyle(
                      color: const Color(0xFF009B6C),
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  const Spacer(),
                  _roundAction(Icons.edit_outlined, const Color(0xFFF6F8FB)),
                  SizedBox(width: 8.w),
                  _roundAction(
                    Icons.delete_outline,
                    const Color(0xFFFFF0F1),
                    iconColor: const Color(0xFFFF5261),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: const Divider(height: 1),
              ),
              Row(
                children: [
                  _detail('Start', start),
                  _detail('End', end),
                  _detail('Lift Amt', '₹${_moneyAmount(liftAmount)}'),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  _detail('Before Lift', '₹${_moneyAmount(beforeLift)}'),
                  _detail('After Lift', '₹${_moneyAmount(afterLift)}'),
                  Expanded(child: _liftedBadge(chit)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: const Color(0xFFE9FFF6),
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(color: const Color(0xFFB4F0D7)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 14, color: Color(0xFF00A878)),
        SizedBox(width: 4.w),
        Text(
          status,
          style: TextStyle(color: const Color(0xFF008D69), fontSize: 11.sp),
        ),
      ],
    ),
  );

  Widget _metaChip(IconData icon, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FB),
      borderRadius: BorderRadius.circular(7.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _primary),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF5D6C7B)),
        ),
      ],
    ),
  );

  Widget _roundAction(IconData icon, Color background, {Color? iconColor}) =>
      Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE1E8EE)),
        ),
        child: Icon(
          icon,
          size: 17,
          color: iconColor ?? const Color(0xFF627485),
        ),
      );

  Widget _detail(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: const Color(0xFF006E67),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          value.isEmpty ? '--' : value,
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF263445),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _liftedBadge(Map<String, dynamic> chit) {
    final value = _value(chit, const ['lifted_date', 'lift_date']);
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FFF6),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFFB4F0D7)),
      ),
      child: Text(
        'Lifted: $value',
        style: TextStyle(fontSize: 10.sp, color: const Color(0xFF008D69)),
      ),
    );
  }

  double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  String _moneyAmount(double value) => value.toStringAsFixed(2);

  String _moneyGrouped(double value) {
    final fixed = _moneyAmount(value);
    final parts = fixed.split('.');
    final whole = parts.first;
    final grouped = whole.replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$grouped.${parts.last}';
  }

  List<Map<String, dynamic>> _asMaps(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  String _value(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  String _today() =>
      ('${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}');
  String _money(String v) => double.parse(v.trim()).toStringAsFixed(2);

  Future<void> _auctionSheet(
    String uuid,
    String name,
    Map<String, dynamic> chit,
    ApiService api,
  ) async {
    final keys = [
      'installment_number',
      'draw_date',
      'winner_reference',
      'gross_amount',
      'discount_amount',
      'commission_amount',
      'other_deductions',
      'reference',
    ];
    final defaults = ['1', _today(), '', '', '0.00', '0.00', '0.00', ''];
    final values = List.generate(
      keys.length,
      (i) => TextEditingController(text: defaults[i]),
    );
    final labels = [
      'Installment number',
      'Draw date (YYYY-MM-DD)',
      'Winner reference',
      'Gross amount',
      'Discount amount',
      'Commission amount',
      'Other deductions',
      'Reference',
    ];
    await _sheet(
      uuid,
      name,
      'Record auction',
      values,
      labels,
      (ctx) async {
        final installmentNumber = int.tryParse(values[0].text.trim());
        final grossAmount = double.tryParse(values[3].text.trim());
        if (installmentNumber == null || installmentNumber < 1) {
          throw const FormatException('Enter a valid installment number.');
        }
        if (grossAmount == null || grossAmount <= 0) {
          throw const FormatException('Enter a valid gross amount.');
        }
        return api.postChitAuction(uuid, {
          'installment_number': installmentNumber,
          'draw_date': values[1].text,
          'winner_reference': values[2].text,
          'gross_amount': _money(values[3].text),
          'discount_amount': _money(values[4].text),
          'commission_amount': _money(values[5].text),
          'other_deductions': _money(values[6].text),
          'reference': values[7].text,
        }, idempotencyKey: ApiService.createIdempotencyKey());
      },
      dynamicOptions: {'Winner reference': _memberOptions(chit)},
    );
  }

  Future<void> _payoutSheet(String uuid, String name, ApiService api) async {
    final values = [
      TextEditingController(),
      TextEditingController(text: '0.00'),
      TextEditingController(text: _today()),
      TextEditingController(),
    ];
    await _sheet(
      uuid,
      name,
      'Create payout',
      values,
      ['Gross amount', 'Deductions', 'Expected date (YYYY-MM-DD)', 'Reference'],
      (_) => api.postChitPayout(uuid, {
        'gross_amount': _money(values[0].text),
        'deductions': _money(values[1].text),
        'expected_date': values[2].text,
        'reference': values[3].text,
      }, idempotencyKey: ApiService.createIdempotencyKey()),
    );
  }

  Future<void> _receiveSheet(
    String uuid,
    String name,
    Map<String, dynamic> chit,
    ApiService api,
  ) async {
    List<Map<String, dynamic>> accounts = [];
    String? loadError;
    try {
      final response = await api.getAccounts();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const FormatException('Unable to load receiving accounts.');
      }
      final decoded = jsonDecode(response.body);
      accounts = _extractMaps(decoded, const ['items', 'accounts', 'data']);
    } catch (error) {
      loadError = error is FormatException
          ? error.message
          : 'Unable to load receiving accounts.';
    }
    final payouts = _payoutOptions(chit);
    if (accounts.isEmpty && loadError != null) {
      _showError(loadError);
      return;
    }
    if (payouts.isEmpty) {
      _showError('No pending payout is available for this chit.');
      return;
    }
    final payout = RxnString();
    final date = TextEditingController(text: _today());
    final reference = TextEditingController();
    final account = RxnString();
    final form = GlobalKey<FormState>();
    final loading = false.obs;

    await Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: 650.h),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: form,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receive payout',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(name.isEmpty ? 'Chit fund' : name),
                        SizedBox(height: 18.h),
                        DropdownButtonFormField<String>(
                          decoration: _decoration('Payout'),
                          items: [
                            for (final option in payouts)
                              DropdownMenuItem(
                                value: option['uuid'],
                                child: Text(option['label']!),
                              ),
                          ],
                          onChanged: (value) => payout.value = value,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Select a payout'
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        _field(date, 'Received date (YYYY-MM-DD)'),
                        SizedBox(height: 12.h),
                        Obx(
                          () => DropdownButtonFormField<String>(
                            initialValue: account.value,
                            decoration: _decoration('Receiving account'),
                            items: [
                              for (final a in accounts)
                                DropdownMenuItem(
                                  value: _accountValue(a),
                                  child: Text(_accountName(a)),
                                ),
                            ],
                            onChanged: (value) => account.value = value,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Select receiving account'
                                : null,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _field(reference, 'Reference'),
                      ],
                    ),
                  ),
                ),
                Obx(
                  () => ElevatedButton(
                    onPressed: loading.value
                        ? null
                        : () async {
                            if (form.currentState?.validate() != true) return;
                            loading.value = true;
                            try {
                              final result = await api.postChitPayoutReceive(
                                uuid,
                                payout.value!,
                                {
                                  'received_date': date.text,
                                  'receiving_account_uuid': account.value,
                                  'reference': reference.text.trim(),
                                },
                                idempotencyKey:
                                    ApiService.createIdempotencyKey(),
                              );
                              if (result.statusCode < 200 ||
                                  result.statusCode >= 300) {
                                throw FormatException(
                                  _responseMessage(result.body) ??
                                      'Unable to record the payout receipt.',
                                );
                              }
                              Get.back();
                              _showSuccess(
                                'Payout received',
                                _responseMessage(result.body) ??
                                    'The payout receipt was recorded.',
                              );
                            } catch (error) {
                              _showError(
                                error is FormatException
                                    ? error.message
                                    : 'Unable to record the payout receipt.',
                              );
                            } finally {
                              loading.value = false;
                            }
                          },
                    child: loading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Receive payout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _accountValue(Map<String, dynamic> a) {
    for (final k in ['uuid', 'account_uuid', 'id']) {
      final v = a[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  String _accountName(Map<String, dynamic> a) {
    for (final k in ['name', 'account_name']) {
      final v = a[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return _accountValue(a);
  }

  Future<void> _sheet(
    String uuid,
    String name,
    String title,
    List<TextEditingController> values,
    List<String> labels,
    Future<dynamic> Function(BuildContext) submit, {
    Map<String, List<String>> dynamicOptions = const {},
  }) async {
    final form = GlobalKey<FormState>();
    final loading = false.obs;
    await Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: 650.h),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: form,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(name.isEmpty ? 'Chit fund' : name),
                        SizedBox(height: 18.h),
                        for (var i = 0; i < values.length; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: dynamicOptions[labels[i]]?.isNotEmpty == true
                                ? DropdownButtonFormField<String>(
                                    initialValue: values[i].text.isEmpty
                                        ? null
                                        : values[i].text,
                                    decoration: _decoration(labels[i]),
                                    items: [
                                      for (final option
                                          in dynamicOptions[labels[i]]!)
                                        DropdownMenuItem(
                                          value: option,
                                          child: Text(option),
                                        ),
                                    ],
                                    onChanged: (value) {
                                      values[i].text = value ?? '';
                                    },
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Required'
                                        : null,
                                  )
                                : _field(values[i], labels[i]),
                          ),
                      ],
                    ),
                  ),
                ),
                Obx(
                  () => ElevatedButton(
                    onPressed: loading.value
                        ? null
                        : () async {
                            if (form.currentState?.validate() != true) return;
                            loading.value = true;
                            try {
                              final r = await submit(Get.context!);
                              if (r.statusCode < 200 || r.statusCode >= 300) {
                                throw FormatException(
                                  _responseMessage(r.body) ??
                                      'The server rejected this request.',
                                );
                              }
                              await controller.refreshSummary();
                              if (Get.isRegistered<GetChitfundsController>()) {
                                await Get.find<GetChitfundsController>()
                                    .refreshChits();
                              }
                              Get.back();
                              _showSuccess(
                                title,
                                _responseMessage(r.body) ??
                                    'Saved successfully.',
                              );
                            } catch (error) {
                              _showError(
                                error is FormatException
                                    ? error.message
                                    : 'Unable to save. Please try again.',
                              );
                            } finally {
                              loading.value = false;
                            }
                          },
                    child: loading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(title),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  List<String> _memberOptions(Map<String, dynamic> chit) {
    final raw = chit['members'] ?? chit['member_list'] ?? chit['members_list'];
    if (raw is! List) return const [];
    return [
      for (final member in raw)
        if (member is Map)
          _value(Map<String, dynamic>.from(member), const [
            'uuid',
            'member_uuid',
            'name',
            'phone',
          ])
        else if (member.toString().trim().isNotEmpty)
          member.toString().trim(),
    ];
  }

  List<Map<String, String>> _payoutOptions(Map<String, dynamic> chit) {
    final raw = chit['payouts'] ?? controller.summary['payouts'];
    if (raw is! List) return const [];
    return [
      for (final payout in raw)
        if (payout is Map)
          if (_value(Map<String, dynamic>.from(payout), const [
            'uuid',
            'payout_uuid',
            'id',
          ]).isNotEmpty)
            {
              'uuid': _value(Map<String, dynamic>.from(payout), const [
                'uuid',
                'payout_uuid',
                'id',
              ]),
              'label':
                  _value(Map<String, dynamic>.from(payout), const [
                    'payout_name',
                    'name',
                  ]).isEmpty
                  ? 'Payout ${_value(Map<String, dynamic>.from(payout), const ['uuid', 'payout_uuid', 'id'])}'
                  : _value(Map<String, dynamic>.from(payout), const [
                      'payout_name',
                      'name',
                    ]),
            },
    ];
  }

  List<Map<String, dynamic>> _extractMaps(dynamic value, List<String> keys) {
    if (value is List) {
      return [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    }
    if (value is Map) {
      for (final key in keys) {
        if (value[key] is List || value[key] is Map) {
          final result = _extractMaps(value[key], keys);
          if (result.isNotEmpty) return result;
        }
      }
    }
    return const [];
  }

  String? _responseMessage(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE9FFF6),
      colorText: const Color(0xFF006E67),
      margin: const EdgeInsets.all(14),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Unable to save',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFFF0F1),
      colorText: const Color(0xFF9B2635),
      margin: const EdgeInsets.all(14),
    );
  }

  Widget _field(TextEditingController c, String label) => TextFormField(
    controller: c,
    readOnly: label.toLowerCase().contains('date'),
    onTap: label.toLowerCase().contains('date') ? () => _pickDate(c) : null,
    keyboardType:
        RegExp(r'amount|deduction|number').hasMatch(label.toLowerCase())
        ? TextInputType.number
        : TextInputType.text,
    decoration: _decoration(label).copyWith(
      suffixIcon: label.toLowerCase().contains('date')
          ? const Icon(Icons.calendar_today_outlined, size: 18)
          : null,
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Required';
      if (label.toLowerCase().contains('date') &&
          DateTime.tryParse(v.trim()) == null) {
        return 'Use YYYY-MM-DD';
      }
      if (label.toLowerCase().contains('amount') &&
          (double.tryParse(v.trim()) ?? -1) < 0) {
        return 'Enter a valid amount';
      }
      return null;
    },
  );
  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
  );
}
