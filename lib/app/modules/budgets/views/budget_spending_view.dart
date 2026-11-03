import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_pages.dart';
import '../controllers/budget_spending_controller.dart';
import '../../home/widgets/home_widget.dart';

class BudgetSpendingView extends GetView<BudgetSpendingController> {
  const BudgetSpendingView({super.key});

  static const ink = HomeStyle.ink;
  static const muted = HomeStyle.muted;
  static const page = HomeStyle.background;
  static const border = HomeStyle.border;
  static const savingsPurple = Color(0xFF7657C7);
  static const success = Color(0xFF169B8A);
  static const warning = Color(0xFFE1A83B);
  static const danger = Color(0xFFE4775A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Budget & Savings',
          style: TextStyle(
            color: ink,
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'HankenGrotesk',
            letterSpacing: -.2,
          ),
        ),
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back_rounded, size: 23.sp),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Refresh',
              onPressed: controller.isLoading.value
                  ? null
                  : controller.isSavingsMode.value
                  ? controller.fetchSavingsGoals
                  : controller.fetchSpending,
              icon: Icon(
                Icons.refresh_rounded,
                color: AppColors.primaryTeal,
                size: 23.sp,
              ),
            ),
          ),
          SizedBox(width: 6.w),
        ],
      ),
      body: Obx(() {
        final isSavings = controller.isSavingsMode.value;
        final isInitialLoading = isSavings
            ? controller.isLoadingSavingsGoals.value &&
                  controller.savingsGoals.isEmpty
            : controller.isLoading.value && controller.budget.isEmpty;

        if (isInitialLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          );
        }

        if (!isSavings &&
            controller.errorMessage.value.isNotEmpty &&
            controller.budget.isEmpty) {
          return _errorState();
        }

        return RefreshIndicator(
          color: AppColors.primaryTeal,
          onRefresh: () => controller.isSavingsMode.value
              ? controller.fetchSavingsGoals()
              : controller.fetchSpending(),
          child: _content(),
        );
      }),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          backgroundColor: const Color(0xFF079B8D),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          onPressed: controller.isSavingsMode.value
              ? _openCreateSavingsGoal
              : _openCreateBudget,
          icon: Icon(Icons.add_rounded, size: 22.sp),
          label: Text(
            controller.isSavingsMode.value ? 'New goal' : 'New budget',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
      children: [
        _pageIntro(),
        SizedBox(height: 22.h),
        _modeSwitch(),
        SizedBox(height: 24.h),
        Obx(
          () => controller.isSavingsMode.value
              ? _savingsContent()
              : _budgetContent(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE INTRO
  // ---------------------------------------------------------------------------

  Widget _pageIntro() {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF079B8D), Color(0xFF19B7A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: .14),
            blurRadius: 22.r,
            offset: Offset(0, 9.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .17),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 25.sp,
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FINANCIAL PLANNING',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .78),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'HankenGrotesk',
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Plan your spending.\nBuild your savings.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'HankenGrotesk',
                    letterSpacing: -.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUDGET / SAVINGS SWITCH
  // ---------------------------------------------------------------------------

  Widget _modeSwitch() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _modeButton(
                label: 'Budget',
                icon: Icons.pie_chart_outline_rounded,
                selected: !controller.isSavingsMode.value,
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => _modeButton(
                label: 'Savings',
                icon: Icons.savings_outlined,
                selected: controller.isSavingsMode.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool selected,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selected
          ? null
          : () {
              controller.isSavingsMode.value = label == 'Savings';

              if (controller.isSavingsMode.value) {
                controller.fetchSavingsGoals();
              } else {
                controller.fetchSpending();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17.sp, color: selected ? Colors.white : muted),
            SizedBox(width: 7.w),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : ink,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUDGET CONTENT
  // ---------------------------------------------------------------------------

  Widget _budgetContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _periodHeader(),
        SizedBox(height: 14.h),
        _overviewCard(),
        SizedBox(height: 14.h),
        _categoryCard(),
        SizedBox(height: 14.h),
        _financialParameterCard(),
      ],
    );
  }

  Widget _periodHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F5F2),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFD8EBE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 37.w,
            height: 37.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primaryTeal,
              size: 19.sp,
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUDGET PERIOD',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                    letterSpacing: .6,
                  ),
                ),
                SizedBox(height: 3.h),
                Obx(
                  () => Text(
                    _periodLabel(),
                    style: TextStyle(
                      color: ink,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Text(
              controller.text('currency', 'INR'),
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard() {
    return _sectionCard(
      title: 'Spending overview',
      subtitle: 'Track your monthly budget',
      leadingIcon: Icons.analytics_outlined,
      child: Obx(() {
        final spent = controller.spent;
        final remaining = controller.remaining;
        final limit = controller.limit;
        final percent = controller.percent.clamp(0.0, 1.0);
        final progressColor = _progressColor(percent);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _budgetOverviewMetric(
                    label: 'Spent so far',
                    value: _money(spent),
                    color: AppColors.primaryTeal,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _budgetOverviewMetric(
                    label: 'Remaining',
                    value: _money(remaining),
                    color: remaining < 0 ? danger : success,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${(percent * 100).round()}% of budget used',
                    style: TextStyle(
                      color: ink,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Limit ${_money(limit)}',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 9.h,
                color: progressColor,
                backgroundColor: const Color(0xFFE8EFEE),
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  percent >= .9
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: progressColor,
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    _statusLabel(percent),
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _budgetOverviewMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: muted,
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        SizedBox(height: 7.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'HankenGrotesk',
            letterSpacing: -.2,
          ),
        ),
      ],
    );
  }

  Widget _categoryCard() {
    return _sectionCard(
      title: 'Category budgets',
      subtitle: 'See where your money is going',
      leadingIcon: Icons.category_outlined,
      action: TextButton.icon(
        onPressed: _openAddCategoryLimit,
        icon: Icon(Icons.add_rounded, size: 17.sp),
        label: Text(
          'Add limit',
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryTeal,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.symmetric(horizontal: 7.w),
        ),
      ),
      child: Obx(() {
        if (controller.categories.isEmpty) {
          return _emptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No spending recorded',
            message:
                'Your category spending will appear here when expenses are recorded.',
          );
        }

        return Column(
          children: controller.categories.take(8).map((item) {
            final name =
                item['category_name'] ??
                item['category'] ??
                item['name'] ??
                'Expense';

            final value = _asDouble(
              item['spent'] ??
                  item['actual_spending'] ??
                  item['amount'] ??
                  item['total'],
            );

            final ratio = controller.spent <= 0
                ? 0.0
                : (value / controller.spent).clamp(0.0, 1.0);

            return Padding(
              padding: EdgeInsets.only(bottom: 15.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$name',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _money(value),
                        style: TextStyle(
                          color: ink,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 7.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 7.h,
                      color: AppColors.secondaryTeal,
                      backgroundColor: const Color(0xFFE8EFEE),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // SAVINGS CONTENT
  // ---------------------------------------------------------------------------

  Widget _savingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _savingsOverviewCard(),
        SizedBox(height: 14.h),
        _savingsGoalsSection(),
      ],
    );
  }

  Widget _savingsOverviewCard() {
    return Obx(() {
      final summary = controller.savingsSummary;
      final target = _summaryAmount(summary, const [
        'target_amount',
        'total_target_amount',
        'total_target',
      ]);
      final saved = _summaryAmount(summary, const [
        'saved_amount',
        'total_saved_amount',
        'current_amount',
        'total_saved',
      ]);
      final remaining = target > saved ? target - saved : 0.0;
      final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;

      return Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6550A9), Color(0xFF806CC4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: savingsPurple.withValues(alpha: .16),
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Icons.savings_rounded, color: Colors.white),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '${_summaryCount(summary)} active goals',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7.h,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: .22),
              ),
            ),
            SizedBox(height: 15.h),
            Row(
              children: [
                Expanded(
                  child: _savingsOverviewMetric(
                    'Saved',
                    _formatCurrency(saved),
                  ),
                ),
                Container(
                  width: 1,
                  height: 28.h,
                  color: Colors.white.withValues(alpha: .20),
                ),
                Expanded(
                  child: _savingsOverviewMetric(
                    'Target',
                    _formatCurrency(target),
                    alignCenter: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 28.h,
                  color: Colors.white.withValues(alpha: .20),
                ),
                Expanded(
                  child: _savingsOverviewMetric(
                    'Remaining',
                    _formatCurrency(remaining),
                    alignRight: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _savingsOverviewMetric(
    String label,
    String value, {
    bool alignCenter = false,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : alignCenter
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: .68),
            fontSize: 8.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _savingsGoalsSection() {
    return _sectionCard(
      title: 'Your savings goals',
      subtitle: 'Progress toward what matters',
      leadingIcon: Icons.flag_outlined,
      child: Obx(() {
        if (controller.isLoadingSavingsGoals.value &&
            controller.savingsGoals.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            ),
          );
        }

        if (controller.savingsGoals.isEmpty) {
          return _emptyState(
            icon: Icons.savings_outlined,
            title: 'No savings goals yet',
            message:
                'Create your first goal to start tracking your savings progress.',
            action: OutlinedButton.icon(
              onPressed: _openCreateSavingsGoal,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create goal'),
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < controller.savingsGoals.length; i++) ...[
              _savingsGoalCard(controller.savingsGoals[i]),
              if (i != controller.savingsGoals.length - 1)
                SizedBox(height: 12.h),
            ],
          ],
        );
      }),
    );
  }

  Widget _savingsGoalCard(Map<String, dynamic> goal) {
    final uuid = (goal['uuid'] ?? goal['savings_goal_uuid'] ?? goal['id'])
        ?.toString()
        .trim();

    final name = (goal['name'] ?? goal['title'] ?? 'Savings goal').toString();

    final target = _asDouble(
      controller.savingsGoalSummaryValue(uuid, const [
            'target_amount',
            'targetAmount',
          ]) ??
          goal['target_amount'] ??
          goal['targetAmount'],
    );

    final saved = _asDouble(
      controller.savingsGoalSummaryValue(uuid, const [
            'current_amount',
            'saved_amount',
            'currentAmount',
            'contributed_amount',
            'total_contributions',
          ]) ??
          goal['current_amount'] ??
          goal['saved_amount'] ??
          goal['currentAmount'] ??
          goal['contributed_amount'] ??
          0,
    );

    final progress = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);

    final completed = target > 0 && saved >= target;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAFE),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: savingsPurple.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: savingsPurple.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  completed
                      ? Icons.check_circle_outline_rounded
                      : Icons.savings_outlined,
                  color: savingsPurple,
                  size: 19.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
              if (completed)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: success.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      color: success,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAVED',
                      style: TextStyle(
                        color: muted,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _money(saved),
                      style: TextStyle(
                        color: savingsPurple,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (target > 0)
                Text(
                  'of ${_money(target)}',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              color: savingsPurple,
              backgroundColor: savingsPurple.withValues(alpha: .10),
            ),
          ),
          SizedBox(height: 7.h),
          Row(
            children: [
              Text(
                '${(progress * 100).round()}% saved',
                style: TextStyle(
                  color: savingsPurple,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (uuid != null && uuid.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openAddContribution(uuid, name),
                  icon: Icon(Icons.add_rounded, size: 16.sp),
                  label: Text(
                    'Add money',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: savingsPurple,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADD SAVINGS CONTRIBUTION
  // ---------------------------------------------------------------------------

  Future<void> _openAddContribution(String uuid, String goalName) async {
    final added = await Get.dialog<bool>(
      _SavingsContributionDialog(
        controller: controller,
        goalName: goalName,
        goalUuid: uuid,
      ),
      barrierDismissible: false,
    );

    if (added == true) {
      await controller.fetchSavingsGoals();
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE SAVINGS GOAL
  // ---------------------------------------------------------------------------

  Future<void> _openCreateSavingsGoal() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        title: Text(
          'Create savings goal',
          style: TextStyle(
            color: ink,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Goal name',
                      hintText: 'e.g. Emergency fund',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a goal name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Target amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid target amount';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isCreatingSavingsGoal.value
                  ? null
                  : Get.back,
              child: const Text('Cancel'),
            ),
          ),
          Obx(
            () => FilledButton(
              onPressed: controller.isCreatingSavingsGoal.value
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      final created = await controller.createSavingsGoal(
                        name: nameController.text.trim(),
                        targetAmount: amountController.text.trim(),
                        description: descriptionController.text.trim(),
                      );
                      if (created) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Get.back(result: true);
                      }
                    },
              child: controller.isCreatingSavingsGoal.value
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create goal'),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    nameController.dispose();
    amountController.dispose();
    descriptionController.dispose();
  }

  // ---------------------------------------------------------------------------
  // ADD CATEGORY BUDGET LIMIT
  // ---------------------------------------------------------------------------

  Future<void> _openAddCategoryLimit() async {
    if (controller.expenseCategories.isEmpty) {
      await controller.loadExpenseCategories();
    }

    if (controller.expenseCategories.isEmpty) {
      Get.snackbar(
        'No categories available',
        'Expense categories could not be loaded. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    String? categoryUuid;
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final added = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            title: Text(
              'Add category limit',
              style: TextStyle(
                color: ink,
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: categoryUuid,
                      decoration: const InputDecoration(
                        labelText: 'Expense category',
                        border: OutlineInputBorder(),
                      ),
                      items: controller.expenseCategories.map((category) {
                        final uuid =
                            (category['uuid'] ?? category['category_uuid'])
                                .toString();

                        final name =
                            category['name'] ??
                            category['category_name'] ??
                            'Expense category';

                        return DropdownMenuItem<String>(
                          value: uuid,
                          child: Text('$name', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          categoryUuid = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Select an expense category';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monthly limit',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');

                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: controller.isAddingCategory.value
                    ? null
                    : () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              Obx(
                () => FilledButton(
                  onPressed: controller.isAddingCategory.value
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final success = await controller.addBudgetCategory(
                            categoryUuid: categoryUuid!,
                            amountLimit: amountController.text.trim(),
                          );

                          if (success) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Get.back(result: true);
                          }
                        },
                  child: controller.isAddingCategory.value
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save limit'),
                ),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    amountController.dispose();

    if (added == true) {
      await controller.fetchSpending();
    }
  }

  // ---------------------------------------------------------------------------
  // FINANCIAL PARAMETER
  // ---------------------------------------------------------------------------

  Widget _financialParameterCard() {
    return Obx(() {
      final parameter = controller
          .text(
            'financial_parameter',
            controller.text(
              'financial',
              controller.text('financialParameter', ''),
            ),
          )
          .trim();

      if (parameter.isEmpty) {
        return const SizedBox.shrink();
      }

      return _sectionCard(
        title: 'Financial note',
        subtitle: 'Additional budget information',
        leadingIcon: Icons.info_outline_rounded,
        child: Text(
          parameter,
          style: TextStyle(color: muted, fontSize: 12.sp, height: 1.5),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // SHARED UI
  // ---------------------------------------------------------------------------

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData leadingIcon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21.r),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37.w,
                height: 37.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F6),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  leadingIcon,
                  color: AppColors.primaryTeal,
                  size: 19.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'HankenGrotesk',
                        letterSpacing: -.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: muted,
                        fontSize: 10.5.sp,
                        height: 1.35,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          SizedBox(height: 22.h),
          child,
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      child: Column(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5F4),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: muted, size: 22.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 11.sp, height: 1.4),
          ),
          if (action != null) ...[SizedBox(height: 12.h), action],
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: muted, size: 42.sp),
            SizedBox(height: 12.h),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12.sp, height: 1.4),
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: controller.fetchSpending,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _openCreateBudget() async {
    final created = await Get.toNamed(Routes.CREATE_BUDGET);

    if (created == true) {
      await controller.reloadBudget();
    }
  }

  String _periodLabel() {
    return controller.text(
      'period',
      controller.text('month_name', controller.text('month', 'Monthly budget')),
    );
  }

  String _money(double value) => '₹${value.toStringAsFixed(2)}';
  String _formatCurrency(double value) =>
      '₹${value.toStringAsFixed(value >= 100000 ? 0 : 2)}';

  double _summaryAmount(Map<String, dynamic> summary, List<String> keys) {
    for (final key in keys) {
      final value = summary[key];
      if (value != null) return _asDouble(value);
    }
    for (final nestedKey in const ['summary', 'data', 'totals']) {
      final nested = summary[nestedKey];
      if (nested is Map) {
        final value = _summaryAmount(Map<String, dynamic>.from(nested), keys);
        if (value != 0) return value;
      }
    }
    return 0;
  }

  int _summaryCount(Map<String, dynamic> summary) {
    for (final key in const [
      'active_goals_count',
      'goals_count',
      'total_goals',
      'goal_count',
    ]) {
      final count = summary[key];
      if (count != null) return int.tryParse('$count') ?? 0;
    }
    for (final nestedKey in const ['summary', 'data', 'totals']) {
      final nested = summary[nestedKey];
      if (nested is Map) {
        final count = _summaryCount(Map<String, dynamic>.from(nested));
        if (count != 0) return count;
      }
    }
    return controller.savingsGoals.length;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _statusLabel(double value) {
    if (value >= 1) return 'You have reached your budget limit';
    if (value >= .9) return 'Almost at your budget limit';
    if (value >= .75) return 'Keep an eye on your spending';
    return 'You are within your budget';
  }

  Color _progressColor(double value) {
    if (value >= .9) return danger;
    if (value >= .75) return warning;
    return AppColors.primaryTeal;
  }
}

class _SavingsContributionDialog extends StatefulWidget {
  const _SavingsContributionDialog({
    required this.controller,
    required this.goalName,
    required this.goalUuid,
  });

  final BudgetSpendingController controller;
  final String goalName;
  final String goalUuid;

  @override
  State<_SavingsContributionDialog> createState() =>
      _SavingsContributionDialogState();
}

class _SavingsContributionDialogState
    extends State<_SavingsContributionDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text(
        'Add money',
        style: TextStyle(
          color: BudgetSpendingView.ink,
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.goalName,
                style: TextStyle(
                  color: BudgetSpendingView.muted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Contribution amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        Obx(
          () => FilledButton(
            onPressed: widget.controller.isAddingSavingsContribution.value
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;

                    final success = await widget.controller
                        .addSavingsGoalContribution(
                          savingsGoalUuid: widget.goalUuid,
                          amount: _amountController.text.trim(),
                          notes: _notesController.text.trim(),
                        );

                    if (success && Get.isDialogOpen == true) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Get.back(result: true);
                    }
                  },
            child: widget.controller.isAddingSavingsContribution.value
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Add contribution'),
          ),
        ),
      ],
    );
  }
}
