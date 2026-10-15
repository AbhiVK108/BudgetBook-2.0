
import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

// ================= HOME HEADER =================

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

            // Refresh personal summary API
            IconButton(
              onPressed: controller.fetchTotals,
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 22.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= HOME BANNER =================

class HomeBanner extends GetView<HomeController> {
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
          Positioned(
            top: 20,
            left: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 25,
                  width: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    color: Colors.white24,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    child: Text(
                      "TOTAL BALANCE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // Dynamic balance from API
                Obx(
                  () => Text(
                    controller.isLoading.value
                        ? "Loading..."
                        : "₹${controller.available.value.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 13,
            top: 8,
            child: Image.asset(
              "assets/images/3D Mini Wallet Asset Illustration.png",
              height: 140.h,
            ),
          ),
          Positioned(
            bottom: 15.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(true),
                _dot(false),
                _dot(false),
              ],
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

// ================= INCOME AND EXPENSE =================

class IncomeExpenseRow extends GetView<HomeController> {
  const IncomeExpenseRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Get.toNamed(Routes.INCOME_EXPENSE);
              },
              child: _card(
                title: "INCOME",
                amount: controller.isLoading.value
                    ? "Loading..."
                    : "₹${controller.totalIncome.value.toStringAsFixed(2)}",
                color: AppColors.primaryTeal,
                icon: Icons.arrow_downward,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: InkWell(
              onTap: () {
                Get.toNamed(Routes.ExpenseView);
              },
              child: _card(
                title: "EXPENSE",
                amount: controller.isLoading.value
                    ? "Loading..."
                    : "₹${controller.totalExpense.value.toStringAsFixed(2)}",
                color: AppColors.expenseRed,
                icon: Icons.arrow_upward,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                    Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                height: 48,
                width: 25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white24,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= SUMMARY ROW =================

class SummaryRow extends GetView<HomeController> {
  const SummaryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 150.h,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xff1EB99A),
          ),
          borderRadius: BorderRadius.circular(18.r),
          color: const Color(0xffE1F2ED),
        ),
        child: Row(
          children: [
            Expanded(
              child: _item(
                "LEND BACK",
                controller.isLoading.value
                    ? "..."
                    : "₹${controller.loanDue.value.toStringAsFixed(2)}",
                AppColors.iconTeal,
                imagePath: "assets/images/lendback.png",
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _item(
                "TO PAY",
                controller.isLoading.value
                    ? "..."
                    : "₹${controller.debitDue.value.toStringAsFixed(2)}",
                AppColors.iconRed,
                imagePath: "assets/images/topay.png",
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _item(
                "NET BAL",
                controller.isLoading.value
                    ? "..."
                    : "₹${controller.available.value.toStringAsFixed(2)}",
                AppColors.iconLightTeal,
                imagePath: "assets/images/netbal.png",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    String title,
    String value,
    Color color, {
    String? imagePath,
  }) {
    return Container(
      height: 122,
      width: 102,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        border: Border.all(
          color: const Color(0xff1EB99A),
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath,
              width: 55.w,
              height: 55.h,
              fit: BoxFit.contain,
            ),
          SizedBox(height: 5.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'HankenGrotesk',
              color: const Color(0xff41484C),
            ),
          ),
          SizedBox(height: 2.h),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
                color: color,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
