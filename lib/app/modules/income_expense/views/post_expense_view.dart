
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
          'Expense',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a Category',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),

            // EXPENSE CATEGORIES
            Obx(() {
              if (controller.isLoadingCategories.value) {
                return SizedBox(
                  height: 110.h,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.categories.isEmpty) {
                return SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 38.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8.h),
                      const Text(
                        'No expense categories found',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      TextButton.icon(
                        onPressed: controller.getExpenseCategories,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 110.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.categories.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(width: 12.w),
                  itemBuilder: (context, index) {
                    final category = controller.categories[index];

                    final categoryName =
                        category['categoryName']?.toString() ??
                            'Category';

                    final imagePath =
                        category['categoryImg']?.toString() ?? '';

                    final imageUrl = imagePath.isEmpty
                        ? ''
                        : imagePath.startsWith('http')
                            ? imagePath
                            : 'https://budgetbook.in/${imagePath.replaceFirst(RegExp(r'^/+'), '')}';

                    return Obx(() {
                      final isSelected =
                          controller.selectedIndex.value == index;

                      return GestureDetector(
                        onTap: () =>
                            controller.selectCategory(index),
                        child: Container(
                          width: 85.w,
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (imageUrl.isNotEmpty)
                                Image.network(
                                  imageUrl,
                                  width: 40.w,
                                  height: 40.h,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Icon(
                                      Icons.category,
                                      size: 40.sp,
                                    );
                                  },
                                )
                              else
                                Icon(
                                  Icons.category,
                                  size: 40.sp,
                                ),
                              SizedBox(height: 6.h),
                              Text(
                                categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'HankenGrotesk',
                                  fontSize: 11.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              );
            }),

            SizedBox(height: 18.h),

            // TRANSACTION DATE
            Text(
              'Transaction Date',
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
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 14.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
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
                    const Spacer(),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 18.h),

            // AMOUNT
            Text(
              'Amount',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '₹',
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
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter amount',
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

            // DESCRIPTION
            Text(
              'Description',
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
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add a note (e.g. Grocery shopping)',
                  hintStyle: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // SAVE EXPENSE
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expenseRed,
                    disabledBackgroundColor:
                        AppColors.expenseRed.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.savedExpense,
                  child: controller.isLoading.value
                      ? SizedBox(
                          height: 22.h,
                          width: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Entry ✓',
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            SizedBox(height: 10.h),

            Center(
              child: Text(
                'Entry will be reflected in your monthly\nwealth report.',
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
