
import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/expense_controller.dart';

class ExpenseView extends GetView<ExpenseController> {
  const ExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
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
          'Total expense',
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
            onPressed: controller.getExpenses,
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

      // ================= ADD EXPENSE =================

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F8F7F),
        onPressed: () async {
          final result = await Get.toNamed(
            Routes.PostExpenseView,
          );

          if (result == true) {
            await controller.getExpenses();
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

            // ================= TRANSACTION COUNT =================

            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expense Transactions',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${controller.filteredExpenses.length} transactions',
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

            // ================= EXPENSE LIST =================

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.expenses.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final items = controller.filteredExpenses;

                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.getExpenses,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 200.h,
                          child: Center(
                            child: Text(
                              'No expense records found',
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
                  onRefresh: controller.getExpenses,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ExpenseTransactionTile(
                        key: ValueKey(
                          items[index]['id'] ??
                              items[index]['expenseId'] ??
                              index,
                        ),
                        expense: items[index],
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

  // ================= TOTAL EXPENSE CARD =================

  Widget _balanceCard() {
    return Obx(() {
      final total = controller.filteredTotalExpense;
      final count = controller.filteredExpenses.length;

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
                  'Total Expense',
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
                  '$count expense records',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 11.sp,
                    color: Colors.redAccent,
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
                Icons.trending_down,
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
                  Icons.calendar_today,
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

// ======================================================
// EXPENSE TRANSACTION TILE
// ======================================================

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
    final id = expense['id'] ??
        expense['expenseId'] ??
        expense['expense_id'];

    final amount = double.tryParse(
          expense['amount']?.toString() ?? '0',
        ) ??
        0.0;

    final category = expense['categoryName']?.toString() ??
        expense['category_name']?.toString() ??
        expense['category']?.toString() ??
        'Expense';

    final description =
        expense['description']?.toString() ?? '';

    final date = expense['expenseDate']?.toString() ??
        expense['expense_date']?.toString() ??
        expense['date']?.toString() ??
        expense['created_at']?.toString() ??
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
                  category,
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
                  description.isEmpty ? 'Expense' : description,
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
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(width: 8.w),

          // ================= EDIT =================

          InkWell(
            onTap: () async {
              if (id == null || id.toString().isEmpty) {
                Get.snackbar(
                  'Error',
                  'Expense ID not found',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              final result = await Get.toNamed(
                Routes.PostExpenseView,
                arguments: {
                  ...expense,
                  'isEdit': true,
                },
              );

              if (result == true) {
                await controller.getExpenses();
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
              if (id != null && id.toString().isNotEmpty) {
                controller.confirmDelete(id);
              } else {
                Get.snackbar(
                  'Error',
                  'Expense ID not found',
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

