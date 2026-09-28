import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeTopHeader extends GetView<HomeController> {
  const HomeTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// LEFT SIDE
            Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundImage: const AssetImage(
                    "assets/images/home-3d-kid.png",
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                    Obx(
                      () => Text(
                        controller.username.value.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            /// RIGHT ICON
            Icon(Icons.refresh, color: Colors.white, size: 22.sp),
          ],
        ),
      ),
    );
  }
}

class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.bannerGradient,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Stack(
        children: [
          /// TEXT
          Positioned(
            top: 30,
            left: 20,
            child: SizedBox(
              width: 180.w,
              child: Text(
                "Get 20% off on\nyour first\nplumbing task",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ),
          ),

          /// IMAGE
          Positioned(
            right: 0,
            bottom: -10,
            child: Image.asset("assets/images/home-3d-kid.png", height: 140.h),
          ),

          /// DOT INDICATOR
          Positioned(
            bottom: 15.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_dot(true), _dot(false), _dot(false)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      width: active ? 16.w : 6.w,
      height: 6.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
    );
  }
}

class IncomeExpenseRow extends StatelessWidget {
  const IncomeExpenseRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// INCOME
        Expanded(
          child: InkWell(
            onTap: () {
              Get.toNamed(Routes.INCOME_EXPENSE);
            },
            child: _card(
              title: "INCOME",
              amount: "₹82,000",
              color: AppColors.primaryTeal,
              icon: Icons.arrow_downward,
            ),
          ),
        ),

        SizedBox(width: 12.w),

        /// EXPENSE
        Expanded(
          child: InkWell(
            onTap: () {
              Get.toNamed(Routes.ExpenseView);
            },
            child: _card(
              title: "EXPENSE",
              amount: "₹14,500",
              color: AppColors.expenseRed,
              icon: Icons.arrow_upward,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: CircleAvatar(
                  radius: 16.r,
                  backgroundColor: Colors.white24,
                  child: Icon(icon, color: Colors.white, size: 16.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _item(
            "Lend Back",
            "₹47,500",
            Icons.account_balance_wallet,
            AppColors.iconTeal,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(child: _item("To Pay", "₹0", Icons.money, AppColors.iconRed)),
        SizedBox(width: 10.w),
        Expanded(
          child: _item(
            "Net Bal",
            "₹47,500",
            Icons.account_balance,
            AppColors.iconLightTeal,
          ),
        ),
      ],
    );
  }

  Widget _item(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20.sp, color: color),
          SizedBox(height: 6.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: color,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }
}
