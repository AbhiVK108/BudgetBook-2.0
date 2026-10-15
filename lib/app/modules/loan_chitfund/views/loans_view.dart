import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/loan_chitfund/controllers/loans_controller.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class LoansView extends GetView<LoansController> {
  const LoansView({super.key});

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F8F7F),
        onPressed: () async {
          await Get.toNamed(Routes.POSTLOAN);
          controller.fetchLoans();
        },
        child: Icon(Icons.add, color: AppColors.cardBgWhite),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 20.h),
              decoration: const BoxDecoration(
                color: Color(0xFF0F8F7D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Loans',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: controller.fetchLoans,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Obx(
              () => Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'Loans',
                        controller.loans.length.toString(),
                        const Color(0xFF1FA97A),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _summaryCard(
                        'Total payable',
                        _money(controller.totalAmount),
                        const Color(0xFFF2994A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.loans.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.loadError.value.isNotEmpty &&
                    controller.loans.isEmpty) {
                  return _messageState(
                    controller.loadError.value,
                    onRetry: controller.fetchLoans,
                  );
                }
                if (controller.loans.isEmpty) {
                  return _messageState('No loans found.');
                }
                return RefreshIndicator(
                  onRefresh: controller.fetchLoans,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 90.h),
                    itemCount: controller.loans.length,
                    itemBuilder: (context, index) {
                      final loan = controller.loans[index];
                      final name =
                          loan['nameOfLender']?.toString().trim().isNotEmpty ==
                                  true
                              ? loan['nameOfLender'].toString()
                              : 'Loan';
                      return Card(
                        margin: EdgeInsets.only(bottom: 12.h),
                        elevation: 1,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFD4E6E4),
                            child: Text(
                              name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF0F8F7D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              'Total: ${_money(loan['totalAmount'])}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Get.toNamed(Routes.GET_LOANS, arguments: loan);
                            controller.fetchLoans();
                          },
                        ),
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

  Widget _summaryCard(String title, String amount, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageState(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              SizedBox(height: 12.h),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
