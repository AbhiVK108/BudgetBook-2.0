import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

// ======================================================
// SHARED DASHBOARD STYLES
// ======================================================

class HomeStyle {
  HomeStyle._();

  static const Color ink = Color(0xFF24332F);
  static const Color muted = Color(0xFF87938F);
  static const Color border = Color(0xFFE8EFEC);
  static const Color background = Color(0xFFF4FAFD);

  static const Color tealLight = Color(0xFFE7F5F2);
  static const Color redLight = Color(0xFFFFF0E9);
  static const Color blueLight = Color(0xFFEDF3FA);

  static const Color amber = Color(0xFFB77A32);
  static const Color amberLight = Color(0xFFFFF5E8);
}

// ======================================================
// SECTION TITLE
// ======================================================

class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle = '',
    this.action,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            height: 37.w,
            width: 37.w,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(icon, color: AppColors.primaryTeal, size: 19.sp),
          ),
          SizedBox(width: 10.w),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: HomeStyle.ink,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'HankenGrotesk',
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HomeStyle.muted,
                    fontSize: 10.5.sp,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 7.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action!,
                    style: TextStyle(
                      color: AppColors.primaryTeal,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14.sp,
                    color: AppColors.primaryTeal,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ======================================================
// FINANCE SHORTCUT
// ======================================================

Widget _financeShortcut({
  required String title,
  required String image,
  required VoidCallback onTap,
}) {
  return Material(
    color: AppColors.cardBgWhite,
    borderRadius: BorderRadius.circular(15.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        width: 82.w,
        height: 88.h,
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 9.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: HomeStyle.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 30.w, width: 30.w, fit: BoxFit.contain),
            SizedBox(height: 8.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: HomeStyle.ink,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ======================================================
// LENDING & BORROWING
// ======================================================

class IncomeRow extends StatelessWidget {
  const IncomeRow({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['Lend', 'Borrow', 'Loans', 'Payments'];

    final images = [
      'assets/images/home lend.png',
      'assets/images/home borrow.png',
      'assets/images/home loans.png',
      'assets/images/home payments.png',
    ];

    return SizedBox(
      height: 94.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          return _financeShortcut(
            title: items[index],
            image: images[index],
            onTap: () {
              switch (index) {
                case 0:
                  Get.toNamed(Routes.LEND_AND_BORROW, arguments: 'lend');
                  break;
                case 1:
                  Get.toNamed(Routes.BorrowView, arguments: 'borrow');
                  break;
                case 2:
                  Get.toNamed(Routes.LoansView, arguments: 'loans');
                  break;
                case 3:
                  Get.toNamed(Routes.LOAN_CHITFUND, arguments: 'chitfunds');
                  break;
              }
            },
          );
        },
      ),
    );
  }
}

// ======================================================
// FINANCIAL PLANNING
// ======================================================

class ExpenseRow extends StatelessWidget {
  const ExpenseRow({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['Budget', 'Cards', 'EMI', 'Invest'];

    final images = [
      'assets/images/home budget.png',
      'assets/images/home cardex.png',
      'assets/images/home emi.png',
      'assets/images/home invest.png',
    ];

    return SizedBox(
      height: 94.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          return _financeShortcut(
            title: items[index],
            image: images[index],
            onTap: () {
              switch (index) {
                case 0:
                  Get.toNamed(Routes.BUDGET_SPENDING_HOME);
                  break;
                case 1:
                  Get.toNamed(Routes.CREDIT_CARDS);
                  break;
                case 2:
                  Get.snackbar(
                    'EMI',
                    'EMI navigation is not connected yet.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  break;
                case 3:
                  Get.snackbar(
                    'Investments',
                    'Investment navigation is not connected yet.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  break;
              }
            },
          );
        },
      ),
    );
  }
}

// ======================================================
// REMINDER CARD
// ======================================================

class ReminderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String date;

  const ReminderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: HomeStyle.border),
      ),
      child: Row(
        children: [
          Container(
            height: 40.w,
            width: 40.w,
            decoration: BoxDecoration(
              color: HomeStyle.amberLight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.event_note_rounded,
              color: HomeStyle.amber,
              size: 19.sp,
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: HomeStyle.ink,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: HomeStyle.muted,
                    fontSize: 10.5.sp,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: HomeStyle.ink,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
              SizedBox(height: 5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: HomeStyle.amberLight,
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Text(
                  date,
                  style: TextStyle(
                    color: HomeStyle.amber,
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
