import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../modules/home/widgets/home_widget.dart';
import '../controllers/add_expense_category_controller.dart';

class AddExpenseCategoryView extends GetView<AddExpenseCategoryController> {
  const AddExpenseCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final selectedIcon = RxString('home');
    final icons = const [
      ('home', 'Home', Icons.home_outlined),
      ('food', 'Food', Icons.restaurant_outlined),
      ('transport', 'Transport', Icons.directions_car_outlined),
      ('shopping', 'Shopping', Icons.shopping_bag_outlined),
      ('health', 'Health', Icons.favorite_outline),
      ('utilities', 'Utilities', Icons.bolt_outlined),
      ('education', 'Education', Icons.school_outlined),
      ('other', 'Other', Icons.category_outlined),
    ];

    IconData iconFor(String value) {
      return icons
          .firstWhere((item) => item.$1 == value, orElse: () => icons.first)
          .$3;
    }

    return Scaffold(
      backgroundColor: HomeStyle.background,
      appBar: AppBar(
        backgroundColor: HomeStyle.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back_rounded, color: HomeStyle.ink),
        ),
        title: Text(
          'Add expense category',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: HomeStyle.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organize your spending',
                        style: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontSize: 13.sp,
                          color: HomeStyle.muted,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: HomeStyle.tealLight,
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: AppColors.primaryTeal.withValues(alpha: .12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Obx(
                              () => Container(
                                width: 50.w,
                                height: 50.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15.r),
                                ),
                                child: Icon(
                                  iconFor(selectedIcon.value),
                                  color: AppColors.primaryTeal,
                                  size: 25.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: nameController,
                                builder: (_, value, child) => Text(
                                  value.text.trim().isEmpty
                                      ? 'New expense category'
                                      : value.text.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: HomeStyle.ink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _fieldLabel('Category name'),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('e.g. Groceries'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a category name'
                            : null,
                      ),
                      SizedBox(height: 24.h),
                      _fieldLabel('Category icon'),
                      SizedBox(height: 10.h),
                      Obx(
                        () => Wrap(
                          spacing: 10.w,
                          runSpacing: 10.h,
                          children: icons.map((item) {
                            final selected = selectedIcon.value == item.$1;
                            return InkWell(
                              borderRadius: BorderRadius.circular(13.r),
                              onTap: () => selectedIcon.value = item.$1,
                              child: Container(
                                width: 100.w,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primaryTeal.withValues(
                                          alpha: .10,
                                        )
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(13.r),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primaryTeal
                                        : HomeStyle.border,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      item.$3,
                                      color: selected
                                          ? AppColors.primaryTeal
                                          : HomeStyle.muted,
                                    ),
                                    SizedBox(height: 5.h),
                                    Text(
                                      item.$2,
                                      style: TextStyle(
                                        fontFamily: 'HankenGrotesk',
                                        fontSize: 10.sp,
                                        color: selected
                                            ? AppColors.primaryTeal
                                            : HomeStyle.ink,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Obx(
                        () => controller.errorMessage.value.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: EdgeInsets.only(top: 16.h),
                                child: Text(
                                  controller.errorMessage.value,
                                  style: TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    fontSize: 12.sp,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
                decoration: BoxDecoration(
                  color: HomeStyle.background,
                  border: Border(top: BorderSide(color: HomeStyle.border)),
                ),
                child: Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: controller.isCreating.value
                          ? null
                          : () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (formKey.currentState?.validate() ?? false) {
                                controller.create(
                                  name: nameController.text,
                                  icon: selectedIcon.value,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: controller.isCreating.value
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create category',
                              style: TextStyle(
                                fontFamily: 'HankenGrotesk',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'HankenGrotesk',
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: HomeStyle.ink,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontFamily: 'HankenGrotesk', color: HomeStyle.muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: HomeStyle.border),
      ),
    );
  }
}
