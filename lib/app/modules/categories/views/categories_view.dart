import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../controllers/categories_controller.dart';

class CategoriesView extends GetView<CategoriesController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),

      /// ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F7F),
        elevation: 0,
        leading: const Icon(Icons.arrow_back),
        title: Text(
          "Categories",
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.cardBgWhite,
          ),
        ),
        actions: const [
          Icon(Icons.refresh, color: AppColors.cardBgWhite),
          SizedBox(width: 12),
          Icon(Icons.more_vert, color: AppColors.cardBgWhite),
          SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F8F7F),
        onPressed: () {},
        child: const Icon(Icons.add, color: AppColors.cardBgWhite),
      ),

      /// ================= BODY =================
      body: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          children: [
            /// ===== Toggle Tabs =====
            Obx(() => _toggleTabs()),

            SizedBox(height: 20.h),

            /// ===== Grid =====
            Expanded(
              child: Obx(
                () => GridView.builder(
                  itemCount: _data().length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (_, index) {
                    final item = _data()[index];
                    return CategoryItem(
                      title: item['title'],
                      amount: item['amount'],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= TOGGLE =================
  Widget _toggleTabs() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          /// Income
          Expanded(
            child: GestureDetector(
              onTap: () => controller.toggle(true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: controller.isIncome.value
                      ? const Color(0xFF0F8F7F)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    "Income",
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: controller.isIncome.value
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// Expense
          Expanded(
            child: GestureDetector(
              onTap: () => controller.toggle(false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: !controller.isIncome.value
                      ? AppColors.expenseRed
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    "Expense",
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: !controller.isIncome.value
                          ? AppColors.cardBgWhite
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= DATA =================
  List<Map<String, dynamic>> _data() {
    if (controller.isIncome.value) {
      return [
        {"title": "Grants", "amount": "₹ 1000"},
        {"title": "Salary", "amount": "₹ 59635"},
        {"title": "Salary", "amount": "₹ 59635"},
        {"title": "Lend", "amount": "₹ 2500"},
        {"title": "Awards", "amount": "₹ 0"},
        {"title": "Sales", "amount": "₹ 0"},
        {"title": "malllll", "amount": "₹ 0"},
        {"title": "some", "amount": "₹ 0"},
        {"title": "Card", "amount": "₹ 0"},
        {"title": "Latest", "amount": "₹ 0"},
      ];
    } else {
      return [
        {"title": "Food", "amount": "₹ 2000"},
        {"title": "Shopping", "amount": "₹ 5000"},
        {"title": "Travel", "amount": "₹ 1500"},
        {"title": "Bills", "amount": "₹ 3000"},
        {"title": "EMI", "amount": "₹ 4000"},
        {"title": "Health", "amount": "₹ 1000"},
      ];
    }
  }
}

/// ================= ITEM =================

class CategoryItem extends GetView<CategoriesController> {
  final String title;
  final String amount;

  const CategoryItem({super.key, required this.title, required this.amount});

  /// ===== ICON MAPPER =====
  FaIconData _getIcon(String title) {
    switch (title.toLowerCase()) {
      case 'salary':
        return FontAwesomeIcons.moneyBillWave;
      case 'grants':
        return FontAwesomeIcons.handHoldingDollar;
      case 'lend':
        return FontAwesomeIcons.handHolding;
      case 'awards':
        return FontAwesomeIcons.trophy;
      case 'sales':
        return FontAwesomeIcons.chartLine;
      case 'card':
        return FontAwesomeIcons.creditCard;
      case 'food':
        return FontAwesomeIcons.utensils;
      case 'shopping':
        return FontAwesomeIcons.bagShopping;
      case 'travel':
        return FontAwesomeIcons.plane;
      case 'bills':
        return FontAwesomeIcons.fileInvoiceDollar;
      case 'emi':
        return FontAwesomeIcons.moneyCheckDollar;
      case 'health':
        return FontAwesomeIcons.heartPulse;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = !controller.isIncome.value;

    return Column(
      children: [
        /// ===== ICON CIRCLE =====
        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isExpense
                ? AppColors.expenseRed.withOpacity(0.5)
                : AppColors.primaryTeal.withOpacity(0.5),
            border: Border.all(
              color: isExpense ? AppColors.expenseRed : AppColors.primaryTeal,
              width: 1,
            ),
          ),
          child: Center(
            child: FaIcon(_getIcon(title), size: 18.sp, color: Colors.white),
          ),
        ),

        SizedBox(height: 8.h),

        /// ===== TITLE =====
        Text(
          title,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 2.h),

        /// ===== AMOUNT =====
        Text(
          amount,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 10.5.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
