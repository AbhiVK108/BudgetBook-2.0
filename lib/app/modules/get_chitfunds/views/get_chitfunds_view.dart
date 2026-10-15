
import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/get_chitfunds_controller.dart';

class GetChitfundsView extends GetView<GetChitfundsController> {
  const GetChitfundsView({super.key});

  static const Color primary = Color(0xFF009688);
  static const Color teal = Color(0xFF078B7D);
  static const Color pink = Color(0xFFFF4564);
  static const Color dark = Color(0xFF263344);
  static const Color label = Color(0xFF8291A5);
  static const Color border = Color(0xFFEDF1F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () {
          // Add chitfund navigation here
        },
        child: Icon(
          Icons.add,
          color: AppColors.cardBgWhite,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chitfunds app bar
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20.w,
                24.h,
                20.w,
                24.h,
              ),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18.r),
                  bottomRight: Radius.circular(18.r),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 28.w),
                  Text(
                    'Chitfunds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ],
              ),
            ),

            SizedBox(height: 22.h),

            // Summary cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title: 'Total',
                      amount: '₹47,500',
                      color: const Color(0xFF06A579),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _summaryCard(
                      title: 'Pay',
                      amount: '₹0',
                      color: const Color(0xFFFF0808),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _summaryCard(
                      title: 'Due',
                      amount: '₹47,500',
                      color: const Color(0xFFFF9854),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _summaryCard(
                      title: 'Completed',
                      amount: '₹47,500',
                      color: const Color(0xFF08BE8A),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 28.h),

            // Scrollable chitfund card
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  14.w,
                  0,
                  14.w,
                  90.h,
                ),
                children: [
                  _chitfundCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary card
  Widget _summaryCard({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: 100.h),
      padding: EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 14.h,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sri Laxmi chitfund card
  Widget _chitfundCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(color: const Color(0xFFF0F2F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chitfund name and status
          Row(
            children: [
              Container(
                width: 16.w,
                height: 16.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFD5F7E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '1. Sri Laxmi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 9.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFFF7),
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color: const Color(0xFFB5F0D5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 15.sp,
                      color: const Color(0xFF079B70),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: const Color(0xFF087F62),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Months and members
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            children: [
              _chitBadge(
                icon: Icons.access_time,
                text: '12 Months',
              ),
              _chitBadge(
                icon: Icons.people_outline,
                text: '5 Members',
              ),
            ],
          ),

          SizedBox(height: 28.h),

          // Total value and action buttons
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL VALUE',
                      style: TextStyle(
                        color: label,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₹1,00,000',
                        style: TextStyle(
                          color: const Color(0xFF079B70),
                          fontSize: 30.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _chitAction(
                icon: Icons.edit_outlined,
                background: const Color(0xFFF8FAFC),
                foreground: const Color(0xFF475569),
                borderColor: const Color(0xFFE2E8F0),
                onTap: () {
                  Get.snackbar(
                    'Edit Chitfund',
                    'Edit chitfund clicked',
                  );
                },
              ),
              SizedBox(width: 8.w),
              _chitAction(
                icon: Icons.delete_outline,
                background: const Color(0xFFFFF1F3),
                foreground: pink,
                borderColor: const Color(0xFFFFD9E0),
                onTap: () {
                  Get.defaultDialog(
                    title: 'Delete Chitfund',
                    middleText:
                        'Are you sure you want to delete Sri Laxmi?',
                    textCancel: 'Cancel',
                    textConfirm: 'Delete',
                    confirmTextColor: Colors.white,
                    buttonColor: pink,
                    onConfirm: () => Get.back(),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 20.h),
          const Divider(color: border),
          SizedBox(height: 18.h),

          // Start, end and lift amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _chitDetail(
                  title: 'Start',
                  value: '2026-10-13',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _chitDetail(
                  title: 'End',
                  value: '2026-10-13',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _chitDetail(
                  title: 'Lift Amt',
                  value: '₹10,000',
                ),
              ),
            ],
          ),

          SizedBox(height: 22.h),

          // Before lift, after lift and lifted date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _chitDetail(
                  title: 'Before Lift',
                  value: '₹5,000',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _chitDetail(
                  title: 'After Lift',
                  value: '₹6,000',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFFF7),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: const Color(0xFFB5F0D5),
                    ),
                  ),
                  child: Text(
                    'Lifted: 13th Oct 26',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF087F62),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Months and members badge
  Widget _chitBadge({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(
          color: const Color(0xFFE9EEF4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 19.sp,
            color: teal,
          ),
          SizedBox(width: 7.w),
          Text(
            text,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  // Circular edit and delete buttons
  Widget _chitAction({
    required IconData icon,
    required Color background,
    required Color foreground,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      shape: CircleBorder(
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48.w,
          height: 48.w,
          child: Icon(
            icon,
            color: foreground,
            size: 22.sp,
          ),
        ),
      ),
    );
  }

  // Chitfund detail field
  Widget _chitDetail({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF175F59),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: dark,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
