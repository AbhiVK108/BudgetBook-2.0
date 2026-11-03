import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_widget.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../widgets/home_header_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBgWhite,

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryTeal,
        elevation: 3,
        onPressed: () => Get.toNamed(Routes.REMINDERS),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.cardBgWhite,
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.scaffoldGradient),
        child: Column(
          children: [
            const HomeTopHeader(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 9.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: const HomePeriodSelector(),
                    ),
                    SizedBox(height: 16.h),

                    // BALANCE OVERVIEW
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: const HomeBanner(),
                    ),

                    SizedBox(height: 25.h),

                    // CASH FLOW
                    _section(
                      title: 'Cash flow',
                      subtitle: 'Understand your income and spending',
                      icon: Icons.swap_vert_rounded,
                      child: Column(
                        children: [
                          const IncomeExpenseRow(),
                          SizedBox(height: 9.h),

                          // PERIOD LABEL
                          // Align(
                          //   alignment: Alignment.centerRight,
                          //   child: Text(
                          //     'Period: ${controller.summaryPeriodLabel}',
                          //     style: TextStyle(
                          //       color: Colors.black54,
                          //       fontSize: 10.sp,
                          //       fontFamily: 'HankenGrotesk',
                          //     ),
                          //   ),
                          // ),

                          // ERROR MESSAGE
                          // Obx(
                          //   () => controller.errorMessage.value.isEmpty
                          //       ? const SizedBox.shrink()
                          //       : Container(
                          //           margin: EdgeInsets.only(top: 10.h),
                          //           padding: EdgeInsets.all(11.r),
                          //           decoration: BoxDecoration(
                          //             color: AppColors.expenseRed.withValues(
                          //               alpha: 0.10,
                          //             ),
                          //             borderRadius:
                          //                 BorderRadius.circular(12.r),
                          //           ),
                          //           child: Row(
                          //             children: [
                          //               Icon(
                          //                 Icons.error_outline_rounded,
                          //                 color: AppColors.iconRed,
                          //                 size: 18.sp,
                          //               ),
                          //               SizedBox(width: 8.w),
                          //               Expanded(
                          //                 child: Text(
                          //                   controller.errorMessage.value,
                          //                   style: TextStyle(
                          //                     color: AppColors.iconRed,
                          //                     fontSize: 11.sp,
                          //                     fontFamily: 'HankenGrotesk',
                          //                   ),
                          //                 ),
                          //               ),
                          //               TextButton(
                          //                 onPressed: controller.fetchTotals,
                          //                 child: Text(
                          //                   'Retry',
                          //                   style: TextStyle(
                          //                     color: AppColors.primaryTeal,
                          //                     fontWeight: FontWeight.w700,
                          //                     fontSize: 11.sp,
                          //                   ),
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //         ),
                          // ),
                        ],
                      ),
                    ),

                    SizedBox(height: 26.h),

                    // LENDING & BORROWING
                    _section(
                      title: 'Lending & borrowing',
                      subtitle: 'Track money you owe and money owed to you',
                      icon: Icons.handshake_outlined,
                      child: const IncomeRow(),
                    ),

                    SizedBox(height: 26.h),

                    // FINANCIAL PLANNING
                    _section(
                      title: 'Financial planning',
                      subtitle: 'Organise budgets, cards and investments',
                      icon: Icons.pie_chart_outline_rounded,
                      child: const ExpenseRow(),
                    ),

                    SizedBox(height: 25.h),

                    // QUICK ACTIONS
                    _section(
                      title: 'Quick actions',
                      subtitle: 'Your everyday money actions',
                      icon: Icons.bolt_rounded,
                      child: HomeQuickActions(
                        onAddIncome: () {
                          Get.toNamed(Routes.INCOME_EXPENSE);
                        },
                        onAddExpense: () {
                          Get.toNamed(Routes.ExpenseView);
                        },
                        onTransfer: () {
                          Get.toNamed(Routes.bankAccounts);
                        },
                      ),
                    ),

                    SizedBox(height: 26.h),

                    // OUTSTANDING OBLIGATIONS
                    _section(
                      title: 'Outstanding obligations',
                      subtitle: 'Your pending receivables and payables',
                      icon: Icons.account_balance_outlined,
                      child: const SummaryRow(),
                    ),

                    SizedBox(height: 26.h),

                    // REMINDERS
                    _section(
                      title: 'Upcoming reminders',
                      subtitle: 'Stay on top of payments and due dates',
                      icon: Icons.notifications_active_outlined,
                      action: 'View all',
                      onAction: () => Get.toNamed(Routes.GET_REMINDER),
                      child: const Column(
                        children: [
                          ReminderCard(
                            title: 'S2S',
                            subtitle: 'Beauty',
                            amount: '₹54,635',
                            date: 'Tomorrow',
                          ),
                          ReminderCard(
                            title: 'Work',
                            subtitle: 'Borrow',
                            amount: '₹54,635',
                            date: 'July 25th',
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // BRAND FOOTER
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.primaryTeal.withValues(
                              alpha: 0.55,
                            ),
                            size: 20.sp,
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            'BUDGETBOOK  •  YOUR MONEY, YOUR CONTROL',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 8.5.sp,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    String? action,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: title,
            subtitle: subtitle,
            icon: icon,
            action: action,
            onAction: onAction,
          ),
          SizedBox(height: 13.h),
          child,
        ],
      ),
    );
  }
}
