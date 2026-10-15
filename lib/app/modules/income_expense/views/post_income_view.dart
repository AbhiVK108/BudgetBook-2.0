import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/post_income_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PostIncomeView extends GetView<PostIncomeController> {
  const PostIncomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F7F),
        elevation: 0,

        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.cardBgWhite,
          ),
        ),

        title: Text(
          "Income",
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.cardBgWhite,
          ),
        ),

        actions: const [
          Icon(
            Icons.more_vert,
            color: AppColors.cardBgWhite,
          ),
          SizedBox(width: 8),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ========================================================
            // CATEGORY TITLE
            // ========================================================

            Text(
              "Select a Category",
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 12.h),

            // ========================================================
            // CATEGORIES
            // ========================================================

            Obx(() {
              if (controller
                  .isLoadingCategories.value) {
                return SizedBox(
                  height: 110.h,
                  child: const Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.categories.isEmpty) {
                return SizedBox(
                  height: 110.h,
                  child: const Center(
                    child: Text(
                      "No income categories available",
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 125.h,

                child: ListView.builder(
                  scrollDirection:
                      Axis.horizontal,

                  itemCount:
                      controller.categories.length,

                  itemBuilder:
                      (context, index) {
                    final category =
                        controller
                            .categories[index];

                    final categoryName =
                        category[
                                'categoryName']
                            ?.toString() ??
                            '';

                    final imagePath =
                        category[
                                'categoryImg']
                            ?.toString() ??
                            '';

                    return Obx(() {
                      final isSelected =
                          controller
                                  .selectedIndex
                                  .value ==
                              index;

                      return GestureDetector(
                        behavior:
                            HitTestBehavior.opaque,

                        onTap: () {
                          controller
                              .selectCategory(
                            index,
                          );
                        },

                        child: Container(
                          width: 85.w,

                          margin:
                              EdgeInsets.only(
                            right: 12.w,
                          ),

                          child: Column(
                            children: [
                              // ==========================
                              // CATEGORY IMAGE
                              // ==========================

                              Container(
                                padding:
                                    EdgeInsets.all(
                                  3.w,
                                ),

                                decoration:
                                    BoxDecoration(
                                  shape:
                                      BoxShape
                                          .circle,

                                  border:
                                      Border.all(
                                    color: isSelected
                                        ? const Color(
                                            0xFF0F8F7F,
                                          )
                                        : Colors
                                            .transparent,
                                    width: 3,
                                  ),
                                ),

                                child:
                                    CircleAvatar(
                                  radius: 28.r,

                                  backgroundColor:
                                      const Color(
                                    0xFF9FC7C3,
                                  ),

                                  backgroundImage:
                                      imagePath
                                              .isNotEmpty
                                          ? NetworkImage(
                                              'https://budgetbook.in/$imagePath',
                                            )
                                          : null,

                                  child: imagePath
                                          .isEmpty
                                      ? Icon(
                                          Icons
                                              .category,
                                          color:
                                              Colors
                                                  .white,
                                          size:
                                              24.sp,
                                        )
                                      : null,
                                ),
                              ),

                              SizedBox(
                                height: 6.h,
                              ),

                              // ==========================
                              // CATEGORY NAME
                              // ==========================

                              Text(
                                categoryName,

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                textAlign:
                                    TextAlign
                                        .center,

                                style:
                                    TextStyle(
                                  fontFamily:
                                      'HankenGrotesk',

                                  fontSize:
                                      11.sp,

                                  fontWeight:
                                      isSelected
                                          ? FontWeight
                                              .bold
                                          : FontWeight
                                              .normal,

                                  color: isSelected
                                      ? const Color(
                                          0xFF0F8F7F,
                                        )
                                      : Colors
                                          .black,
                                ),
                              ),

                              SizedBox(
                                height: 3.h,
                              ),

                              // ==========================
                              // CHECK ICON
                              // ==========================

                              if (isSelected)
                                Icon(
                                  Icons
                                      .check_circle,
                                  size: 16.sp,
                                  color:
                                      const Color(
                                    0xFF0F8F7F,
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

            // ========================================================
            // DATE
            // ========================================================

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
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 14.h,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12.r,
                  ),

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
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                    ),

                    SizedBox(width: 8.w),

                    Obx(
                      () => Text(
                        controller
                            .selectedDate
                            .value,

                        style: TextStyle(
                          fontFamily:
                              'HankenGrotesk',
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 18.h),

            // ========================================================
            // AMOUNT
            // ========================================================

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
              padding:
                  EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  12.r,
                ),

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
                    "₹",
                    style: TextStyle(
                      fontFamily:
                          'HankenGrotesk',
                      fontSize: 18.sp,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          const Color(
                        0xFF0F8F7F,
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  Expanded(
                    child: TextField(
                      controller:
                          controller
                              .amountController,

                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),

                      decoration:
                          const InputDecoration(
                        border:
                            InputBorder.none,
                        hintText:
                            "Enter amount",
                        hintStyle:
                            TextStyle(
                          fontFamily:
                              'HankenGrotesk',
                          color:
                              Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // ========================================================
            // DESCRIPTION
            // ========================================================

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
              padding:
                  EdgeInsets.symmetric(
                horizontal: 12.w,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  12.r,
                ),

                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),

              child: TextField(
                controller:
                    controller.noteController,

                maxLines: 4,

                decoration:
                    const InputDecoration(
                  border:
                      InputBorder.none,

                  hintText:
                      "Add a note (e.g. Q3 Bonus)",

                  hintStyle:
                      TextStyle(
                    fontFamily:
                        'HankenGrotesk',
                    color:
                        Colors.grey,
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // ========================================================
            // SAVE BUTTON
            // ========================================================

            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 48.h,

                child:
                    ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF0F8F7F,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12.r,
                      ),
                    ),
                  ),

                  onPressed: controller
                          .isSavingIncome
                          .value
                      ? null
                      : () {
                          controller
                              .saveIncome();
                        },

                  child:
                      controller
                              .isSavingIncome
                              .value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : Text(
                              "Save Entry ✓",

                              style:
                                  TextStyle(
                                fontFamily:
                                    'HankenGrotesk',
                                fontSize:
                                    14.sp,
                                fontWeight:
                                    FontWeight
                                        .w600,
                                color: AppColors
                                    .cardBgWhite,
                              ),
                            ),
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // ========================================================
            // FOOTER
            // ========================================================

            Center(
              child: Text(
                "Entry will be reflected in your monthly\nwealth report.",

                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  fontFamily:
                      'HankenGrotesk',
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