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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F8F7F),
        onPressed: () {
          Get.toNamed(Routes.REMINDERS);
        },
        child: const Icon(Icons.notification_add, color: AppColors.cardBgWhite),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.scaffoldGradient),
        child: Column(
          children: [
            const HomeTopHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeBanner(),
                    SizedBox(height: 16.h),
                    const IncomeExpenseRow(),
                    SizedBox(height: 16.h),
                    const SummaryRow(),
                    SizedBox(height: 16.h),

                    /// RECENTLY USED
                    const SectionTitle(title: "Recently Used"),
                    SizedBox(height: 10.h),
                    const RecentlyUsed(),
                    SizedBox(height: 20.h),

                    /// CATEGORIES
                    const SectionHeader(
                      title: "Categories",
                      action: "View All",
                    ),
                    SizedBox(height: 10.h),
                    // const CategoryRow(),
                    // SizedBox(height: 20.h),

                    /// INCOME
                    const SectionTitle(title: "Income"),
                    SizedBox(height: 10.h),
                    const IncomeRow(),
                    SizedBox(height: 20.h),

                    /// EXPENSE
                    const SectionTitle(title: "Expense"),
                    SizedBox(height: 10.h),
                    const ExpenseRow(),
                    SizedBox(height: 20.h),

                    /// GRID ACTIONS
                    const ActionGrid(),
                    SizedBox(height: 20.h),

                    /// REMINDER
                    const SectionTitle(title: "Reminder"),
                    SizedBox(height: 10.h),
                    Column(
                      children: const [
                        ReminderCard(
                          title: "S2S",
                          subtitle: "Beauty",
                          amount: "₹54,635",
                          date: "Tomorrow",
                        ),
                        ReminderCard(
                          title: "work",
                          subtitle: "Barrow",
                          amount: "₹54,635",
                          date: "July 25th",
                        ),
                      ],
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
}
