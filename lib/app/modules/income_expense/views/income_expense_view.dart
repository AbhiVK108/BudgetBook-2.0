import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_widget.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/income_expense_controller.dart';

const Color _teal = Color(0xFF0F8F7F);
const Color _tealDark = Color(0xFF087A70);
const Color _background = Color(0xFFF4FAFD);
const Color _text = Color(0xFF202A35);
const Color _muted = Color(0xFF7A8794);
const Color _border = Color(0xFFE7EEF1);

class IncomeExpenseView extends GetView<IncomeExpenseController> {
  const IncomeExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBgWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          toolbarHeight: 66.h,

          leadingWidth: 48.w,
          leading: IconButton(
            onPressed: Get.back,
            splashRadius: 22.r,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: HomeStyle.ink,
            ),
          ),

          titleSpacing: 4.w,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'OVERVIEW',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.primaryTeal,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Income',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                  color: HomeStyle.ink,
                  height: 1,
                ),
              ),
            ],
          ),

          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: Material(
                  color: const Color(0xFFE8F5F2),
                  borderRadius: BorderRadius.circular(13.r),
                  child: InkWell(
                    onTap: controller.exportIncomeReportPdf,
                    borderRadius: BorderRadius.circular(13.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 13.w,
                        vertical: 9.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(
                          color: AppColors.primaryTeal.withValues(alpha: 0.13),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 19.sp,
                            color: AppColors.primaryTeal,
                          ),
                          SizedBox(width: 7.w),
                          Text(
                            'Export',
                            style: TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.download_rounded,
                            size: 15.sp,
                            color: AppColors.primaryTeal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _teal,
        elevation: 3,
        onPressed: _addIncome,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Obx(() {
        final isInitialLoading =
            controller.isLoading.value && controller.incomeList.isEmpty;

        if (isInitialLoading) {
          return const Center(child: CircularProgressIndicator(color: _teal));
        }

        return RefreshIndicator(
          color: _teal,
          onRefresh: controller.getIncome,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14.w, 15.h, 14.w, 100.h),
            children: [
              _IncomePeriodSelector(),

              SizedBox(height: 16.h),

              // SINGLE INCOME SUMMARY
              _incomeSummary(),

              SizedBox(height: 22.h),

              // INCOME SOURCES
              _incomeSources(),

              SizedBox(height: 23.h),

              // MAIN TRANSACTION SECTION
              _transactionsSection(),
            ],
          ),
        );
      }),
    );
  }

  // ============================================================
  // ADD INCOME
  // ============================================================

  Future<void> _addIncome() async {
    final result = await Get.toNamed(Routes.PostIncomeView);

    if (result == true) {
      await controller.getIncome();
    }
  }

  // ============================================================
  // PERIOD TABS
  // ============================================================

  // ============================================================
  // SINGLE INCOME SUMMARY
  // ============================================================

  Widget _incomeSummary() {
    return Obx(() {
      final reportTotals = controller.reportTotals;
      final total = reportTotals.isEmpty
          ? controller.filteredTotalIncome
          : double.tryParse(
                  reportTotals.first['total_amount']?.toString() ?? '',
                ) ??
                0;
      final count = reportTotals.isEmpty
          ? controller.filteredIncome.length
          : int.tryParse(
                  reportTotals.first['transaction_count']?.toString() ?? '',
                ) ??
                0;
      final changePercent = reportTotals.isEmpty
          ? 0.0
          : double.tryParse(
                  reportTotals.first['change_percent']?.toString() ?? '',
                ) ??
                0.0;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_teal, _tealDark],
          ),
          borderRadius: BorderRadius.circular(17.r),
          boxShadow: [
            BoxShadow(
              color: _teal.withValues(alpha: 0.13),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 17.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                SizedBox(width: 7.w),
                Text(
                  'TOTAL INCOME',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Text(
                    'Income',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              '₹${total.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 29.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 15.h),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 15.sp,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                SizedBox(width: 6.w),
                Text(
                  '$count ${count == 1 ? 'transaction' : 'transactions'}',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}% vs previous period',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 10.sp,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // INCOME SOURCES
  // ============================================================

  Widget _incomeSources() {
    return Obx(() {
      final categories = controller.categoryAnalysis;

      if (categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return _IncomeSourcesSection(categories: categories);
    });
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  Widget _transactionsSection() {
    return Obx(() {
      final items = controller.filteredIncome;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income transactions',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Your received income and transaction history',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontSize: 10.sp,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${items.length} records',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (items.isEmpty)
            _emptyTransactions()
          else
            ...List.generate(items.length, (index) {
              final income = items[index];

              return TransactionTile(
                key: ValueKey(income['uuid'] ?? income['id'] ?? index),
                income: income,
                controller: controller,
              );
            }),
        ],
      );
    });
  }

  Widget _emptyTransactions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Container(
            width: 55.w,
            height: 55.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6F7F5),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 25.sp, color: _teal),
          ),
          SizedBox(height: 12.h),
          Text(
            'No income transactions',
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'Your income records for this period will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 11.sp,
              color: _muted,
            ),
          ),
          SizedBox(height: 14.h),
          OutlinedButton.icon(
            onPressed: _addIncome,
            style: OutlinedButton.styleFrom(
              foregroundColor: _teal,
              side: const BorderSide(color: _teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add income',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13.r),
      border: Border.all(color: _border),
    );
  }
}

class _IncomePeriodSelector extends GetView<IncomeExpenseController> {
  const _IncomePeriodSelector();

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _earliestSupportedYear = 2018;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => InkWell(
        onTap: _showPeriodPicker,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 42.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.incomeSummaryPeriodLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _teal,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodPicker() {
    final now = DateTime.now();
    final availableMonthCount =
        (now.year - _earliestSupportedYear) * 12 + now.month;
    final months = List.generate(availableMonthCount, (index) {
      final date = DateTime(now.year, now.month - index);
      return DateTime(date.year, date.month);
    });
    final years = List.generate(
      now.year - _earliestSupportedYear + 1,
      (index) => now.year - index,
    );

    Get.bottomSheet<void>(
      SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.78),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10.h, bottom: 15.h),
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 14.w, 14.h),
                child: Row(
                  children: [
                    Container(
                      height: 42.w,
                      width: 42.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F5),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: _teal,
                        size: 21,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income period',
                            style: TextStyle(
                              color: _text,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Choose a quick period or a custom month',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 11.sp,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close_rounded, color: _muted),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: _border),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: const [
                    _IncomePresetPeriod(period: 'today', label: 'Today'),
                    _IncomePresetPeriod(
                      period: 'this_week',
                      label: 'This week',
                    ),
                    _IncomePresetPeriod(
                      period: 'this_month',
                      label: 'This month',
                    ),
                    _IncomePresetPeriod(
                      period: 'previous_month',
                      label: 'Previous month',
                    ),
                    _IncomePresetPeriod(
                      period: 'this_year',
                      label: 'This year',
                    ),
                    _IncomePresetPeriod(
                      period: 'previous_year',
                      label: 'Previous year',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Text(
                      'Custom year',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: SizedBox(
                        height: 34.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: years.length,
                          itemBuilder: (context, index) {
                            final year = years[index];
                            return Padding(
                              padding: EdgeInsets.only(right: 6.w),
                              child: _IncomeYearPeriod(year: year),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
                  itemCount: months.length,
                  separatorBuilder: (_, _) => SizedBox(height: 7.h),
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final isCurrent =
                        month.year == now.year && month.month == now.month;
                    return Obx(() {
                      final selected =
                          controller.selectedIncomePeriod.value ==
                          'month_${month.year}_${month.month}';
                      return Material(
                        color: selected
                            ? const Color(0xFFEAF7F5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(13.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13.r),
                          onTap: () {
                            controller.selectIncomeMonth(month);
                            Get.back();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 13.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13.r),
                              border: Border.all(
                                color: selected ? _teal : _border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_monthNames[month.month - 1]} '
                                    '${month.year}',
                                    style: TextStyle(
                                      color: _text,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'HankenGrotesk',
                                    ),
                                  ),
                                ),
                                if (isCurrent)
                                  Text(
                                    'Current',
                                    style: TextStyle(
                                      color: _teal,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                if (selected) ...[
                                  SizedBox(width: 8.w),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: _teal,
                                    size: 19,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      enableDrag: true,
    );
  }
}

class _IncomePresetPeriod extends GetView<IncomeExpenseController> {
  final String period;
  final String label;

  const _IncomePresetPeriod({required this.period, required this.label});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedIncomePeriod.value == period;
      return InkWell(
        onTap: () {
          controller.selectIncomePeriod(period);
          Get.back();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: selected ? _teal : Colors.white,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: selected ? _teal : _border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _text,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
      );
    });
  }
}

class _IncomeYearPeriod extends GetView<IncomeExpenseController> {
  final int year;

  const _IncomeYearPeriod({required this.year});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected =
          controller.selectedIncomePeriod.value == 'year' &&
          controller.selectedMonth.value.year == year;
      return InkWell(
        onTap: () {
          controller.selectIncomeYear(year);
          Get.back();
        },
        child: Container(
          height: 34.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _teal : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: selected ? _teal : _border),
          ),
          child: Text(
            year.toString(),
            style: TextStyle(
              color: selected ? Colors.white : _text,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
  }
}

// ============================================================
// INCOME SOURCES GRID WITH VIEW ALL
// ============================================================

class _IncomeSourcesSection extends StatefulWidget {
  final List<dynamic> categories;

  const _IncomeSourcesSection({required this.categories});

  @override
  State<_IncomeSourcesSection> createState() => _IncomeSourcesSectionState();
}

class _IncomeSourcesSectionState extends State<_IncomeSourcesSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories;
    final visibleCategories = _showAll
        ? categories
        : categories.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income sources',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Where your money comes from',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 10.sp,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            if (categories.length > 4)
              InkWell(
                onTap: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
                  child: Row(
                    children: [
                      Text(
                        _showAll ? 'Show less' : 'View all',
                        style: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: _teal,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        _showAll
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.arrow_forward_rounded,
                        size: 15.sp,
                        color: _teal,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 11.h),

        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleCategories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 9.w,
              mainAxisSpacing: 9.h,
              mainAxisExtent: 105.h,
            ),
            itemBuilder: (context, index) {
              final category = visibleCategories[index];

              return _IncomeSourceCard(category: category, index: index);
            },
          ),
        ),
      ],
    );
  }
}

class _IncomeSourceCard extends StatelessWidget {
  final dynamic category;
  final int index;

  const _IncomeSourceCard({required this.category, required this.index});

  @override
  Widget build(BuildContext context) {
    final name = category['category_name']?.toString() ?? 'Income';

    final amount = category['amount']?.toString() ?? '0.00';

    final currency = category['currency']?.toString() ?? '₹';

    final count = category['transaction_count']?.toString() ?? '0';

    final percentage =
        double.tryParse(category['percentage_of_total']?.toString() ?? '') ?? 0;

    final iconData = _categoryIcon(name);

    return Container(
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 29.w,
                height: 29.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(iconData, size: 16.sp, color: _teal),
              ),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: _text,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$currency $amount',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: _teal,
                      ),
                    ),
                  ),
                  Text(
                    '$count txns',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 9.sp,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String name) {
    final value = name.toLowerCase();

    if (value.contains('salary')) return Icons.work_outline_rounded;
    if (value.contains('business')) return Icons.business_center_outlined;
    if (value.contains('freelance')) return Icons.laptop_mac_rounded;
    if (value.contains('investment')) return Icons.trending_up_rounded;
    if (value.contains('interest')) return Icons.account_balance_outlined;
    if (value.contains('rent')) return Icons.home_work_outlined;
    if (value.contains('gift')) return Icons.card_giftcard_rounded;
    if (value.contains('refund')) return Icons.currency_exchange_rounded;
    if (value.contains('bonus')) return Icons.stars_rounded;

    return Icons.account_balance_wallet_outlined;
  }
}

// ============================================================
// TRANSACTION TILE
// ============================================================

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> income;
  final IncomeExpenseController controller;

  const TransactionTile({
    super.key,
    required this.income,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final transactionUuid = income['uuid']?.toString().trim() ?? '';

    final id = transactionUuid.isNotEmpty
        ? transactionUuid
        : income['id']?.toString() ?? '';

    final canOfferReversal = IncomeExpenseController.canOfferIncomeReversal(
      income,
    );

    final amount = double.tryParse(income['amount']?.toString() ?? '0') ?? 0.0;

    final categoryName =
        income['categoryName']?.toString() ??
        income['category_name']?.toString() ??
        income['category']?.toString() ??
        'Income';

    final description = income['description']?.toString() ?? '';

    final date =
        income['incomeDate']?.toString() ??
        income['incomedate']?.toString() ??
        income['income_date']?.toString() ??
        income['transaction_date']?.toString() ??
        '';

    return Container(
      margin: EdgeInsets.only(bottom: 9.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6F7F5),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.south_west_rounded, size: 20.sp, color: _teal),
          ),
          SizedBox(width: 11.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: _text,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  description.isEmpty ? 'Income' : description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 10.sp,
                    color: _muted,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 10.sp,
                      color: _muted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: 7.w),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+₹${amount.toStringAsFixed(2)}',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: _teal,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Transaction actions',
                padding: EdgeInsets.zero,
                splashRadius: 18.r,
                iconSize: 20.sp,
                elevation: 8,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shadowColor: const Color(0x18000000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  side: const BorderSide(color: Color(0xFFF0F1F3), width: 0.7),
                ),
                offset: Offset(0, 8.h),
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      if (id.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Income ID not found.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      final result = await Get.toNamed(
                        Routes.PostIncomeView,
                        arguments: {...income, 'isEdit': true},
                      );

                      if (result == true) {
                        await controller.getIncome();
                      }
                      break;

                    case 'delete':
                      if (id.isNotEmpty) {
                        controller.confirmDeleteIncome(id);
                      } else {
                        Get.snackbar(
                          'Error',
                          'Income ID not found.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                      break;

                    case 'reverse':
                      if (canOfferReversal) {
                        controller.confirmIncomeReversal(transactionUuid);
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    height: 48.h,
                    child: _incomeMenuItem(
                      icon: Icons.edit_rounded,
                      title: 'Edit income',
                      subtitle: 'Update transaction details',
                      iconColor: const Color(0xFF4263EB),
                      iconBackground: const Color(0xFFEEF2FF),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    height: 48.h,
                    child: _incomeMenuItem(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete income',
                      subtitle: 'Remove this transaction',
                      iconColor: const Color(0xFFE5484D),
                      iconBackground: const Color(0xFFFFEEEE),
                    ),
                  ),
                  if (canOfferReversal)
                    PopupMenuItem<String>(
                      value: 'reverse',
                      height: 48.h,
                      child: _incomeMenuItem(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Reverse income',
                        subtitle: 'Create a reversal transaction',
                        iconColor: const Color(0xFFB7791F),
                        iconBackground: const Color(0xFFFFF5DB),
                      ),
                    ),
                ],
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: const Color(0xFF737B87),
                  size: 21.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _incomeMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(10.r),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF252A34),
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 9.sp,
                  color: const Color(0xFF858B96),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
