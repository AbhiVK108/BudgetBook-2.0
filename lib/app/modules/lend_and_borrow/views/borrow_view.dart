import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/lend_and_borrow/controllers/borrow_controller.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class BorrowView extends GetView<BorrowController> {
  const BorrowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F8F7F),
        onPressed: () async {
          await Get.toNamed(Routes.POSTBORROW);
          await controller.fetchBorrows();
        },
        child: const Icon(Icons.add, color: AppColors.cardBgWhite),
      ),
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
                  "Borrow",
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

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.borrows.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  SizedBox(
                    height: 94.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        _summaryCard(
                          title: 'Total',
                          amount: controller.formatAmount(controller.totalAmount),
                          color: const Color(0xFF1FA97A),
                        ),
                        SizedBox(width: 10.w),
                        _summaryCard(
                          title: 'Paid',
                          amount: controller.formatAmount(controller.paidAmount),
                          color: Colors.red,
                        ),
                        SizedBox(width: 10.w),
                        _summaryCard(
                          title: 'Due',
                          amount: controller.formatAmount(controller.dueAmount),
                          color: const Color(0xFFF2994A),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: controller.borrows.isEmpty
                        ? Center(
                            child: Text(
                              controller.errorMessage.value.isEmpty
                                  ? 'No borrow records found.'
                                  : controller.errorMessage.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14.sp,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: controller.fetchBorrows,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              itemCount: controller.borrows.length,
                              itemBuilder: (_, index) {
                                final borrow = controller.borrows[index];
                                final name = controller.nameFor(borrow);
                                return GestureDetector(
                                  onTap: () => Get.toNamed(
                                    Routes.GET_BORROW,
                                    arguments: borrow,
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 14.h),
                                    padding: EdgeInsets.all(14.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14.r),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x331BBCAC),
                                          blurRadius: 6,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22.r,
                                          backgroundColor:
                                              const Color(0xFFD4E6E4),
                                          child: Text(
                                            name.isEmpty
                                                ? '?'
                                                : name[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF0F8F7D),
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'HankenGrotesk',
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'HankenGrotesk',
                                                ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                'Total: ${controller.formatAmount(controller.amountFor(borrow))}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey[600],
                                                  fontFamily: 'HankenGrotesk',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            }),
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
      width: 110.w,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
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
