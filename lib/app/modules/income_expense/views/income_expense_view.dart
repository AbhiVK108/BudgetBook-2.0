
import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/income_expense_controller.dart';

class IncomeExpenseView extends GetView<IncomeExpenseController> {
  const IncomeExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),

      // ================= APP BAR =================

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F7F),
        elevation: 0,
        leading: InkWell(
          onTap: Get.back,
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.cardBgWhite,
          ),
        ),
        title: Text(
          'Total income',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.cardBgWhite,
          ),
        ),
        actions: [
          const Icon(
            Icons.filter_list,
            color: AppColors.cardBgWhite,
          ),
          SizedBox(width: 8.w),
          IconButton(
            onPressed: controller.getIncome,
            icon: const Icon(
              Icons.refresh,
              color: AppColors.cardBgWhite,
            ),
          ),
          const Icon(
            Icons.more_vert,
            color: AppColors.cardBgWhite,
          ),
          SizedBox(width: 8.w),
        ],
      ),

      // ================= ADD INCOME =================

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F8F7F),
        onPressed: () async {
          final result = await Get.toNamed(
            Routes.PostIncomeView,
          );

          if (result == true) {
            await controller.getIncome();
          }
        },
        child: const Icon(
          Icons.add,
          color: AppColors.cardBgWhite,
        ),
      ),

      // ================= BODY =================

      body: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _balanceCard(),
            SizedBox(height: 16.h),
            _monthSelector(),
            SizedBox(height: 12.h),

            // ================= TRANSACTION HEADER =================

            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Income Transactions',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${controller.filteredIncome.length} transactions',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 11.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10.h),

            // ================= INCOME LIST =================

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.incomeList.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final items = controller.filteredIncome;

                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.getIncome,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 200.h,
                          child: Center(
                            child: Text(
                              'No income records found for this month',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'HankenGrotesk',
                                fontSize: 14.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.getIncome,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final income = items[index];

                      return TransactionTile(
                        key: ValueKey(
                          income['id'] ?? index,
                        ),
                        income: income,
                        controller: controller,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TOTAL INCOME CARD =================

  Widget _balanceCard() {
    return Obx(() {
      final total = controller.filteredTotalIncome;
      final count = controller.filteredIncome.length;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Income',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F8F7F),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '$count income records',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 11.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE6F7F5),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Color(0xFF0F8F7F),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ================= MONTH SELECTOR =================

  Widget _monthSelector() {
    return Obx(() {
      final month = controller.selectedMonth.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: controller.previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 16,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${_monthName(month.month)} ${month.year}',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: controller.nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      );
    });
  }

  String _monthName(int month) {
    const months = [
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

    return months[month - 1];
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
    final id = income['id']?.toString() ?? '';

    final amount = double.tryParse(
          income['amount']?.toString() ?? '0',
        ) ??
        0.0;

    final categoryName =
        income['categoryName']?.toString() ??
        income['category_name']?.toString() ??
        income['category']?.toString() ??
        'Income';

    final description =
        income['description']?.toString() ?? '';

    final date =
        income['incomeDate']?.toString() ??
        income['incomedate']?.toString() ??
        income['income_date']?.toString() ??
        '';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6F7F5),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF0F8F7F),
            ),
          ),

          SizedBox(width: 12.w),

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
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description.isEmpty ? 'Income' : description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 11.sp,
                    color: Colors.grey,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: 6.w),

          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 12.sp,
              color: const Color(0xFF0F8F7F),
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(width: 8.w),

          // ================= EDIT =================

          InkWell(
            onTap: () async {
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
                arguments: {
                  ...income,
                  'isEdit': true,
                },
              );

              if (result == true) {
                await controller.getIncome();
              }
            },
            child: const Icon(
              Icons.edit,
              size: 18,
            ),
          ),

          SizedBox(width: 8.w),

          // ================= DELETE =================

          InkWell(
            onTap: () {
              if (id.isNotEmpty) {
                controller.confirmDeleteIncome(id);
              } else {
                Get.snackbar(
                  'Error',
                  'Income ID not found.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Icon(
              Icons.delete,
              size: 18,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

