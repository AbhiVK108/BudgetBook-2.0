import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/lend_controller.dart';

class LendView extends GetView<LendController> {
  const LendView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: Column(
        children: [
          /// 🔥 CUSTOM HEADER
          Container(
            padding: EdgeInsets.only(
              top: 40.h,
              left: 16.w,
              right: 16.w,
              bottom: 20.h,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F8F7D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                SizedBox(width: 12.w),
                Text(
                  "Lend",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_vert, color: Colors.white),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          /// 🔥 SUMMARY CARDS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: "Total",
                    amount: "₹47,500",
                    color: const Color(0xFF1FA97A),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _summaryCard(
                    title: "Pay",
                    amount: "₹0",
                    color: Colors.red,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _summaryCard(
                    title: "Due",
                    amount: "₹47,500",
                    color: const Color(0xFFF2994A),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          /// 🔥 LIST
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: 5,
              itemBuilder: (_, index) {
                final isSelected = index == 0;

                return Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x331BBCAC),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// AVATAR
                      CircleAvatar(
                        radius: 22.r,
                        backgroundColor: const Color(0xFFD4E6E4),
                        child: Text(
                          "S",
                          style: TextStyle(
                            color: const Color(0xFF0F8F7D),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'HankenGrotesk',
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      /// NAME + AMOUNT
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "shouley",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            "Total: ₹54,635",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 SUMMARY CARD WIDGET
  Widget _summaryCard({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }
}
