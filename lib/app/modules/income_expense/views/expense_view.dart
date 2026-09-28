import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/expense_controller.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ExpenseView extends GetView<ExpenseController> {
  const ExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),

      /// ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F7F),
        elevation: 0,
        leading: InkWell(
          onTap: (){
            Get.back();
          },
          child: const Icon(Icons.arrow_back, color: AppColors.cardBgWhite)),
        title: Text(
          "Total expansive",
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.cardBgWhite,
          ),
        ),
        actions: const [
          Icon(Icons.filter_list, color: AppColors.cardBgWhite),
          SizedBox(width: 12),
          Icon(Icons.refresh, color: AppColors.cardBgWhite),
          SizedBox(width: 12),
          Icon(Icons.more_vert, color: AppColors.cardBgWhite),
          SizedBox(width: 8),
        ],
      ),

      /// ================= FLOAT BUTTON =================
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F8F7F),
        onPressed: () {
          Get.toNamed(Routes.PostExpenseView);
        },
        child: const Icon(Icons.add, color: AppColors.cardBgWhite),
      ),

      /// ================= BODY =================
      body: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _balanceCard(),
            SizedBox(height: 16.h),
            _monthSelector(),
            SizedBox(height: 12.h),
            _todayHeader(),
            SizedBox(height: 10.h),

            /// List
            Expanded(
              child: ListView(
                children: const [
                  ExpenseTile(),
                  ExpenseTile(),
                  ExpenseTile(),
                  ExpenseTile(),
                  ExpenseTile(),
                  ExpenseTile(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= BALANCE CARD =================
  Widget _balanceCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Left
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Balance",
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "₹63,135",
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "↑ 12.5% increase from last month",
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 11.sp,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          /// Right Icon
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEDE3),
            ),
            child: const Icon(Icons.trending_up, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  /// ================= MONTH SELECTOR =================
  Widget _monthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.chevron_left),
        SizedBox(width: 10.w),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              SizedBox(width: 6.w),
              Text(
                "June 2026",
                style: TextStyle(fontFamily: 'HankenGrotesk', fontSize: 12.sp),
              ),
            ],
          ),
        ),

        SizedBox(width: 10.w),
        const Icon(Icons.chevron_right),
      ],
    );
  }

  /// ================= TODAY HEADER =================
  Widget _todayHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Today",
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          "4 transactions",
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 11.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// ================= EXPENSE TILE =================
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          /// Icon
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

          /// Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "S2S",
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Beauty",
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 11.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          /// Amount
          Text(
            "₹54,635",
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 12.sp,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(width: 10.w),

          /// Actions
          const Icon(Icons.edit, size: 18),
          SizedBox(width: 6),
          const Icon(Icons.delete, size: 18, color: Colors.red),
        ],
      ),
    );
  }
}
