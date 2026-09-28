import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/post_expense_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PostExpenseView extends GetView<PostExpenseController> {
  const PostExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),

      /// ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F7F),

        elevation: 0,
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: const Icon(Icons.arrow_back, color: AppColors.cardBgWhite),
        ),
        title: Text(
          "Expense",
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.cardBgWhite,
          ),
        ),
        actions: const [
          Icon(Icons.more_vert, color: AppColors.cardBgWhite),
          SizedBox(width: 8),
        ],
      ),

      /// ================= BODY =================
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== CATEGORY =====
            Text(
              "Select a Category",
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 12.h),

            SizedBox(
              height: 70.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (_, index) {
                  final isSelected = controller.selectedIndex.value == index;

                  return GestureDetector(
                    onTap: () => controller.selectCategory(index),
                    child: Container(
                      margin: EdgeInsets.only(right: 12.w),
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppColors.expenseRed, width: 2)
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: 26.r,
                        backgroundColor: const Color(0xFF9FC7C3),
                        backgroundImage: const AssetImage(
                          'assets/images/beauty.jpg',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 18.h),

            /// ===== DATE =====
            Text(
              "Transaction Date",
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),

            SizedBox(height: 6.h),

            GestureDetector(
              onTap: controller.pickDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    /// 🔥 Asset icon instead of default
                    const Icon(Icons.calendar_today, size: 18),

                    SizedBox(width: 8.w),
                    Obx(
                      () => Text(
                        controller.selectedDate.value,
                        style: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 18.h),

            /// ===== AMOUNT =====
            Text(
              "Amount",
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),

            SizedBox(height: 6.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    "₹",
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expenseRed,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: controller.amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter amount",
                        hintStyle: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            /// ===== DESCRIPTION =====
            Text(
              "Description",
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),

            SizedBox(height: 6.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Add a note (e.g. Grocery shopping)",
                  hintStyle: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            /// ===== BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expenseRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {},
                child: Text(
                  "Save Entry ✓",
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: 10.h),

            /// ===== FOOTER =====
            Center(
              child: Text(
                "Entry will be reflected in your monthly\nwealth report.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 11.sp,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
