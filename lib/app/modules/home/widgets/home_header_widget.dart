import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_widget.dart';
import 'package:budget_book_2026/app/modules/profile/controllers/profile_controller.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

// ======================================================
// HOME HEADER
// ======================================================

class HomeTopHeader extends GetView<HomeController> {
  const HomeTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(), permanent: true);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.bannerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(21.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 12.w, 13.h),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: () => Get.toNamed(Routes.PROFILE),
              borderRadius: BorderRadius.circular(50.r),
              child: Obx(() {
                final imageUrl = profileController.profile.value?.profileImage;

                return Container(
                  height: 47.w,
                  width: 47.w,
                  padding: EdgeInsets.all(2.5.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      child: imageUrl == null || imageUrl.isEmpty
                          ? Image.asset(
                              'assets/images/BudgetBook-Logo.png',
                              fit: BoxFit.contain,
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Image.asset(
                                'assets/images/BudgetBook-Logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(width: 11.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BUDGETBOOK',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10.sp,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Obx(
                    () => Text(
                      'Hello, ${controller.username.value}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _headerAction(
              icon: Icons.account_balance_outlined,
              tooltip: 'Bank accounts',
              onTap: () => Get.toNamed(Routes.bankAccounts),
            ),

            SizedBox(width: 3.w),

            _headerAction(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh',
              onTap: controller.fetchTotals,
            ),

            PopupMenuButton<String>(
              tooltip: 'More options',
              icon: Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 22.sp,
              ),
              color: Colors.white,
              onSelected: (value) {
                if (value == 'logout') controller.logout();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'logout', child: Text('Log out')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 21.sp),
    );
  }
}
// ======================================================
// BALANCE CARD
// ======================================================

class HomeBanner extends GetView<HomeController> {
  const HomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final available = controller.hasAvailableSummary.value;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(19.r),
        decoration: BoxDecoration(
          gradient: AppColors.bannerGradient,
          borderRadius: BorderRadius.circular(21.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryTeal.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -25.w,
              top: -30.h,
              child: Container(
                height: 125.w,
                width: 125.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 22.w,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'TOTAL BALANCE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5.sp,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.shield_outlined,
                      color: Colors.white70,
                      size: 19.sp,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Text(
                  'Available balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  loading
                      ? 'Loading...'
                      : available
                      ? '₹${controller.available.value.toStringAsFixed(2)}'
                      : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                SizedBox(height: 13.h),
                Row(
                  children: [
                    Container(
                      height: 7.w,
                      width: 7.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        'Across your accounts',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10.5.sp,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                    ),
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 19.sp,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ======================================================
// PERIOD SELECTOR
// Calendar button opens a themed, scrollable GetX bottom sheet.
// ======================================================

class HomePeriodSelector extends GetView<HomeController> {
  const HomePeriodSelector({super.key});

  static const List<String> _monthNames = [
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
  static const int _earliestSupportedYear = 2018;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final label = controller.summaryPeriodLabel;
      return InkWell(
        onTap: _showPeriodPicker,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 42.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: AppColors.cardBgWhite,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: HomeStyle.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HomeStyle.ink,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryTeal,
                size: 20.sp,
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showPeriodPicker() {
    final now = DateTime.now();

    final availableMonthCount =
        (now.year - _earliestSupportedYear) * 12 + now.month;
    final months = List.generate(availableMonthCount, (index) {
      final date = DateTime(now.year, now.month - index);
      return DateTime(date.year, date.month);
    });
    final years = List<int>.generate(
      now.year - _earliestSupportedYear + 1,
      (index) => now.year - index,
    );

    Get.bottomSheet<void>(
      SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.78),
          decoration: BoxDecoration(
            color: AppColors.cardBgWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom-sheet notch
              Padding(
                padding: EdgeInsets.only(top: 10.h, bottom: 15.h),
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: HomeStyle.border,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),

              // Sheet header
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 14.w, 14.h),
                child: Row(
                  children: [
                    Container(
                      height: 42.w,
                      width: 42.w,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primaryTeal,
                        size: 21.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial period',
                            style: TextStyle(
                              color: HomeStyle.ink,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Choose a quick period or a custom month',
                            style: TextStyle(
                              color: HomeStyle.muted,
                              fontSize: 11.sp,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      splashRadius: 20.r,
                      icon: Icon(
                        Icons.close_rounded,
                        color: HomeStyle.muted,
                        size: 21.sp,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, thickness: 1, color: HomeStyle.border),

              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: const [
                    _PresetPeriod(period: 'today', label: 'Today'),
                    _PresetPeriod(period: 'this_week', label: 'This week'),
                    _PresetPeriod(period: 'this_month', label: 'This month'),
                    _PresetPeriod(
                      period: 'previous_month',
                      label: 'Previous month',
                    ),
                    _PresetPeriod(period: 'this_year', label: 'This year'),
                    _PresetPeriod(
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
                        color: HomeStyle.muted,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: SizedBox(
                        height: 34.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: years.length,
                          separatorBuilder: (_, _) => SizedBox(width: 6.w),
                          itemBuilder: (context, index) {
                            return _YearPeriod(year: years[index]);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable month list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
                  itemCount: months.length,
                  separatorBuilder: (_, _) => SizedBox(height: 7.h),
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final isCurrentMonth =
                        month.year == now.year && month.month == now.month;

                    final label =
                        '${_monthNames[month.month - 1]} ${month.year}';

                    return Obx(() {
                      final isSelected =
                          controller.selectedPeriod.value ==
                          'month_${month.year}_${month.month}';

                      return Material(
                        color: isSelected
                            ? AppColors.primaryTeal.withValues(alpha: 0.09)
                            : AppColors.cardBgWhite,
                        borderRadius: BorderRadius.circular(13.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13.r),
                          onTap: () {
                            controller.selectMonth(month);
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
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : HomeStyle.border,
                                width: isSelected ? 1.2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 35.w,
                                  width: 35.w,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryTeal
                                        : AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16.sp,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primaryTeal,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: HomeStyle.ink,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'HankenGrotesk',
                                    ),
                                  ),
                                ),
                                if (isCurrentMonth)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTeal.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      'Current',
                                      style: TextStyle(
                                        color: AppColors.primaryTeal,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'HankenGrotesk',
                                      ),
                                    ),
                                  ),
                                if (isSelected) ...[
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primaryTeal,
                                    size: 19.sp,
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

// ======================================================
// QUICK ACTIONS
// ======================================================

class HomeQuickActions extends StatelessWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onTransfer;
  final VoidCallback? onMore;

  const HomeQuickActions({
    super.key,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onTransfer,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        title: 'Income',
        subtitle: 'Add money',
        icon: Icons.add_rounded,
        color: AppColors.primaryTeal,
        background: const Color(0xFFE5F5F1),
        onTap: onAddIncome,
      ),
      _QuickActionData(
        title: 'Expense',
        subtitle: 'Record spend',
        icon: Icons.remove_rounded,
        color: AppColors.expenseRed,
        background: const Color(0xFFFFF0E9),
        onTap: onAddExpense,
      ),
      _QuickActionData(
        title: 'Transfer',
        subtitle: 'Move money',
        icon: Icons.swap_horiz_rounded,
        color: AppColors.iconTeal,
        background: AppColors.cardBg,
        onTap: onTransfer,
      ),
      _QuickActionData(
        title: 'More',
        subtitle: 'See all',
        icon: Icons.more_horiz_rounded,
        color: AppColors.primaryTeal,
        background: AppColors.cardBg,
        onTap: onMore ?? () {},
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 7.w),
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: HomeStyle.border),
      ),
      child: Row(
        children: actions.map((item) {
          return Expanded(
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12.r),
              child: Column(
                children: [
                  Container(
                    height: 42.w,
                    width: 42.w,
                    decoration: BoxDecoration(
                      color: item.background,
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: Icon(item.icon, color: item.color, size: 23.sp),
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: HomeStyle.ink,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: HomeStyle.muted,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });
}

class _PresetPeriod extends StatelessWidget {
  const _PresetPeriod({required this.period, required this.label});

  final String period;
  final String label;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final selected = controller.selectedPeriod.value == period;
      return InkWell(
        onTap: () {
          controller.selectPeriod(period);
          Get.back();
        },
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryTeal
                : AppColors.primaryTeal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.primaryTeal,
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

class _YearPeriod extends StatelessWidget {
  const _YearPeriod({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final selected =
          controller.selectedPeriod.value == 'year' &&
          controller.selectedMonth.value.year == year;
      return InkWell(
        onTap: () {
          controller.selectYear(year);
          Get.back();
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryTeal.withValues(alpha: 0.15)
                : AppColors.cardBg,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: selected ? AppColors.primaryTeal : HomeStyle.border,
            ),
          ),
          child: Text(
            year.toString(),
            style: TextStyle(
              color: selected ? AppColors.primaryTeal : HomeStyle.ink,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
      );
    });
  }
}

// ======================================================
// INCOME & EXPENSE
// ======================================================

class IncomeExpenseRow extends GetView<HomeController> {
  const IncomeExpenseRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _cashFlowCard(
              title: 'Money in',
              subtitle: 'Total income',
              amount: controller.isLoading.value
                  ? 'Loading...'
                  : controller.hasIncomeSummary.value
                  ? '₹${controller.totalIncome.value.toStringAsFixed(2)}'
                  : '—',
              color: AppColors.primaryTeal,
              background: const Color(0xFFE5F5F1),
              icon: Icons.south_west_rounded,
              onTap: () => Get.toNamed(Routes.INCOME_EXPENSE),
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: _cashFlowCard(
              title: 'Money out',
              subtitle: 'Total expenses',
              amount: controller.isLoading.value
                  ? 'Loading...'
                  : controller.hasExpenseSummary.value
                  ? '₹${controller.totalExpense.value.toStringAsFixed(2)}'
                  : '—',
              color: AppColors.expenseRed,
              background: const Color(0xFFFFF0E9),
              icon: Icons.north_east_rounded,
              onTap: () => Get.toNamed(Routes.ExpenseView),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cashFlowCard({
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
    required Color background,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBgWhite,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(13.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: HomeStyle.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 31.w,
                    width: 31.w,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(icon, color: color, size: 16.sp),
                  ),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: HomeStyle.ink,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: HomeStyle.muted,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// OUTSTANDING OBLIGATIONS
// ======================================================

class SummaryRow extends GetView<HomeController> {
  const SummaryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: AppColors.cardBgWhite,
          borderRadius: BorderRadius.circular(17.r),
          border: Border.all(color: HomeStyle.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _obligationItem(
                title: 'To receive',
                subtitle: 'Money lent',
                amount: controller.isLoading.value
                    ? '...'
                    : controller.hasLoanDueSummary.value
                    ? '₹${controller.loanDue.value.toStringAsFixed(2)}'
                    : '—',
                icon: Icons.call_received_rounded,
                color: AppColors.primaryTeal,
                background: const Color(0xFFE5F5F1),
              ),
            ),
            Container(height: 66.h, width: 1, color: HomeStyle.border),
            Expanded(
              child: _obligationItem(
                title: 'To pay',
                subtitle: 'Money borrowed',
                amount: controller.isLoading.value
                    ? '...'
                    : controller.hasDebitDueSummary.value
                    ? '₹${controller.debitDue.value.toStringAsFixed(2)}'
                    : '—',
                icon: Icons.call_made_rounded,
                color: AppColors.expenseRed,
                background: const Color(0xFFFFF0E9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _obligationItem({
    required String title,
    required String subtitle,
    required String amount,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Column(
      children: [
        Container(
          height: 35.w,
          width: 35.w,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyle(
            color: HomeStyle.ink,
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        SizedBox(height: 5.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          subtitle,
          style: TextStyle(
            color: HomeStyle.muted,
            fontSize: 9.5.sp,
            fontFamily: 'HankenGrotesk',
          ),
        ),
      ],
    );
  }
}
