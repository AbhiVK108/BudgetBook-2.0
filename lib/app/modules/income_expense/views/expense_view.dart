import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_widget.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/expense_controller.dart';

const Color _teal = Color(0xFF0F8F7F);
const Color _tealDark = Color(0xFF087A70);
const Color _background = Color(0xFFF4FAFD);
const Color _text = Color(0xFF202A35);
const Color _muted = Color(0xFF7A8794);
const Color _border = Color(0xFFE7EEF1);
const Color _expenseRed = AppColors.expenseRed;

class ExpenseView extends GetView<ExpenseController> {
  const ExpenseView({super.key});

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
              'Expense',
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
                  onTap: controller.exportExpenseReportPdf,
                  borderRadius: BorderRadius.circular(13.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 13.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13.r),
                      border: Border.all(
                        color: AppColors.expenseRed.withValues(alpha: 0.13),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 19.sp,
                          color: AppColors.expenseRed,
                        ),
                        SizedBox(width: 7.w),
                        Text(
                          'Export',
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: AppColors.expenseRed,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.download_rounded,
                          size: 15.sp,
                          color: AppColors.expenseRed,
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
        onPressed: _addExpense,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),

      body: Obx(() {
        final isInitialLoading =
            controller.isLoading.value && controller.expenses.isEmpty;

        if (isInitialLoading) {
          return const Center(child: CircularProgressIndicator(color: _teal));
        }

        return RefreshIndicator(
          color: _teal,
          onRefresh: () async {
            await controller.getExpenses();
            await controller.getExpenseReport();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14.w, 15.h, 14.w, 100.h),
            children: [
              const _ExpensePeriodSelector(),

              SizedBox(height: 16.h),

              _expenseSummary(),

              SizedBox(height: 23.h),

              _expenseSources(),

              SizedBox(height: 23.h),

              _transactionsSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _expenseSources() {
    return Obx(() {
      final categories = controller.expenseCategoryAnalysis;
      if (categories.isEmpty) return const SizedBox.shrink();
      return _ExpenseSourcesSection(categories: categories);
    });
  }

  // ============================================================
  // ADD EXPENSE
  // ============================================================

  Future<void> _addExpense() async {
    final result = await Get.toNamed(Routes.PostExpenseView);

    if (result == true) {
      await controller.getExpenses();
    }
  }

  // ============================================================
  // EXPENSE SUMMARY
  // ============================================================

  Widget _expenseSummary() {
    return Obx(() {
      final total = controller.filteredTotalExpense;
      final count = controller.filteredExpenses.length;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_expenseRed, _expenseRed.withValues(alpha: 0.85)],
          ),
          borderRadius: BorderRadius.circular(17.r),
          boxShadow: [
            BoxShadow(
              color: _expenseRed.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
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
                  'TOTAL EXPENSE',
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
                    'Expense',
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
                  'Total spending',
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
  // MONTH SELECTOR
  // ============================================================

  // ============================================================
  // TRANSACTIONS SECTION
  // ============================================================

  Widget _transactionsSection() {
    return Obx(() {
      final items = controller.filteredExpenses;

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
                      'Expense transactions',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Your spending and transaction history',
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
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${items.length} records',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: _expenseRed,
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
              final expense = items[index];

              return ExpenseTransactionTile(
                key: ValueKey(
                  expense['uuid'] ??
                      expense['id'] ??
                      expense['expenseId'] ??
                      index,
                ),
                expense: expense,
                controller: controller,
              );
            }),
        ],
      );
    });
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

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
              color: Color(0xFFFFEEEE),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 25.sp,
              color: _expenseRed,
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            'No expense transactions',
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),

          SizedBox(height: 5.h),

          Text(
            'Your expense records for this period will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 11.sp,
              color: _muted,
            ),
          ),

          SizedBox(height: 14.h),

          OutlinedButton.icon(
            onPressed: _addExpense,
            style: OutlinedButton.styleFrom(
              foregroundColor: _teal,
              side: const BorderSide(color: _teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add expense',
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

class _ExpensePeriodSelector extends GetView<ExpenseController> {
  const _ExpensePeriodSelector();

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
                  controller.expenseSummaryPeriodLabel,
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
                color: _expenseRed,
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
                        color: _expenseRed,
                        size: 21,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense period',
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
                    _ExpensePresetPeriod(period: 'today', label: 'Today'),
                    _ExpensePresetPeriod(
                      period: 'this_week',
                      label: 'This week',
                    ),
                    _ExpensePresetPeriod(
                      period: 'this_month',
                      label: 'This month',
                    ),
                    _ExpensePresetPeriod(
                      period: 'previous_month',
                      label: 'Previous month',
                    ),
                    _ExpensePresetPeriod(
                      period: 'this_year',
                      label: 'This year',
                    ),
                    _ExpensePresetPeriod(
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
                            return Padding(
                              padding: EdgeInsets.only(right: 6.w),
                              child: _ExpenseYearPeriod(year: years[index]),
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
                          controller.selectedExpensePeriod.value ==
                          'month_${month.year}_${month.month}';
                      return Material(
                        color: selected
                            ? const Color(0xFFEAF7F5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(13.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13.r),
                          onTap: () {
                            controller.selectExpenseMonth(month);
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
                                color: selected ? _expenseRed : _border,
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
                                      color: _expenseRed,
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

class _ExpensePresetPeriod extends GetView<ExpenseController> {
  final String period;
  final String label;

  const _ExpensePresetPeriod({required this.period, required this.label});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedExpensePeriod.value == period;
      return InkWell(
        onTap: () {
          controller.selectExpensePeriod(period);
          Get.back();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: selected ? _expenseRed : Colors.white,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: selected ? _expenseRed : _border),
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

class _ExpenseYearPeriod extends GetView<ExpenseController> {
  final int year;

  const _ExpenseYearPeriod({required this.year});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected =
          controller.selectedExpensePeriod.value == 'year' &&
          controller.selectedMonth.value.year == year;
      return InkWell(
        onTap: () {
          controller.selectExpenseYear(year);
          Get.back();
        },
        child: Container(
          height: 34.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _expenseRed : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: selected ? _expenseRed : _border),
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

class _ExpenseSourcesSection extends StatefulWidget {
  final List<Map<String, dynamic>> categories;

  const _ExpenseSourcesSection({required this.categories});

  @override
  State<_ExpenseSourcesSection> createState() => _ExpenseSourcesSectionState();
}

class _ExpenseSourcesSectionState extends State<_ExpenseSourcesSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _showAll
        ? widget.categories
        : widget.categories.take(4).toList();

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
                    'Expense categories',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Where your money is going',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 10.sp,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.categories.length > 4)
              InkWell(
                onTap: () => setState(() => _showAll = !_showAll),
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
              return _ExpenseSourceCard(category: visibleCategories[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _ExpenseSourceCard extends StatelessWidget {
  final Map<String, dynamic> category;

  const _ExpenseSourceCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final name = category['category_name']?.toString() ?? 'Expense';
    final amount =
        category['amount']?.toString() ??
        category['total_amount']?.toString() ??
        '0.00';
    final currency = category['currency']?.toString() ?? '₹';
    final count = category['transaction_count']?.toString() ?? '0';
    final percentage =
        double.tryParse(category['percentage_of_total']?.toString() ?? '') ?? 0;

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
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Icon(
                  _expenseCategoryIcon(name),
                  size: 16.sp,
                  color: _expenseRed,
                ),
              ),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: _expenseRed,
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
                        color: _expenseRed,
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
}

IconData _expenseCategoryIcon(String name) {
  final value = name.toLowerCase();
  if (value.contains('rent') || value.contains('home')) {
    return Icons.home_work_outlined;
  }
  if (value.contains('food') || value.contains('dining')) {
    return Icons.restaurant_outlined;
  }
  if (value.contains('travel') || value.contains('transport')) {
    return Icons.directions_car_outlined;
  }
  if (value.contains('shopping')) return Icons.shopping_bag_outlined;
  if (value.contains('health') || value.contains('medical')) {
    return Icons.medical_services_outlined;
  }
  if (value.contains('bill') || value.contains('utility')) {
    return Icons.receipt_long_outlined;
  }
  if (value.contains('education')) return Icons.school_outlined;
  if (value.contains('entertainment')) return Icons.movie_outlined;
  return Icons.payments_outlined;
}

// ============================================================
// EXPENSE TRANSACTION TILE
// ============================================================

class ExpenseTransactionTile extends StatelessWidget {
  final Map<String, dynamic> expense;
  final ExpenseController controller;

  const ExpenseTransactionTile({
    super.key,
    required this.expense,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final transactionUuid = expense['uuid']?.toString().trim() ?? '';

    final canOfferReversal = ExpenseController.canOfferExpenseReversal(expense);

    final id =
        expense['uuid'] ??
        expense['id'] ??
        expense['expenseId'] ??
        expense['expense_id'];

    final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;

    final category =
        expense['categoryName']?.toString() ??
        expense['category_name']?.toString() ??
        expense['category']?.toString() ??
        'Expense';

    final description = expense['description']?.toString() ?? '';

    final date =
        expense['transaction_date']?.toString() ??
        expense['expenseDate']?.toString() ??
        expense['expense_date']?.toString() ??
        expense['date']?.toString() ??
        expense['created_at']?.toString() ??
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
              color: Color(0xFFFFEEEE),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.south_east_rounded,
              size: 20.sp,
              color: _expenseRed,
            ),
          ),

          SizedBox(width: 11.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
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
                  description.isEmpty ? 'Expense' : description,
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
                '-₹${amount.toStringAsFixed(2)}',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: _expenseRed,
                ),
              ),

              PopupMenuButton<String>(
                tooltip: 'Expense actions',
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
                  if (action == 'reverse') {
                    if (canOfferReversal) {
                      await controller.confirmExpenseReversal(transactionUuid);
                    }
                    return;
                  }

                  if (id == null || id.toString().isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Expense ID not found.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  switch (action) {
                    case 'edit':
                      final result = await Get.toNamed(
                        Routes.PostExpenseView,
                        arguments: {...expense, 'isEdit': true},
                      );

                      if (result == true) {
                        await controller.getExpenses();
                      }
                      break;

                    case 'delete':
                      controller.confirmDelete(id);
                      break;
                  }
                },

                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    height: 48.h,
                    child: _expenseMenuItem(
                      icon: Icons.edit_rounded,
                      title: 'Edit expense',
                      subtitle: 'Update transaction details',
                      iconColor: const Color(0xFF4263EB),
                      iconBackground: const Color(0xFFEEF2FF),
                    ),
                  ),

                  PopupMenuItem<String>(
                    value: 'delete',
                    height: 48.h,
                    child: _expenseMenuItem(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete expense',
                      subtitle: 'Remove this transaction',
                      iconColor: _expenseRed,
                      iconBackground: const Color(0xFFFFEEEE),
                    ),
                  ),

                  if (canOfferReversal)
                    PopupMenuItem<String>(
                      value: 'reverse',
                      height: 48.h,
                      child: _expenseMenuItem(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Reverse expense',
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

  Widget _expenseMenuItem({
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
