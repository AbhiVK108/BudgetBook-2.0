import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/postborrow_controller.dart';

class PostborrowView extends GetView<PostborrowController> {
  const PostborrowView({super.key});

  static const Color primary = Color(0xFF079B8D);
  static const Color dark = Color(0xFF263445);
  static const Color hint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2EAF0);
  static const Color background = Color(0xFFF3F5F5);
  static const Color fieldBackground = Color(0xFFF7F9FB);
  static const Color mintBorder = Color(0xFFBCEBE4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section([
                      _label('Lender name'),
                      SizedBox(height: 8.h),
                      _input(
                        controller.personController,
                        hint: 'Person name',
                        icon: Icons.person_outline,
                        capitalization: TextCapitalization.words,
                      ),
                      _helper('Enter the person or business you borrowed from'),
                      SizedBox(height: 14.h),
                      _label('Mobile number (optional)'),
                      SizedBox(height: 8.h),
                      _input(
                        controller.phoneController,
                        hint: '98765 43210',
                        icon: Icons.phone_outlined,
                        prefixText: '+91  ',
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                      ),
                      _helper('Add a 10-digit number if you want to record it'),
                    ]),
                    SizedBox(height: 16.h),
                    _section([
                      _label('Principal amount'),
                      SizedBox(height: 8.h),
                      _input(
                        controller.amountController,
                        hint: '0.00',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _helper('Enter the amount you are borrowing'),
                      SizedBox(height: 14.h),
                      _label('Interest method'),
                      SizedBox(height: 8.h),
                      _readOnlyField('Fixed interest'),
                      _helper('Fixed amount due in addition to the principal'),
                      SizedBox(height: 12.h),
                      _label('Fixed interest amount'),
                      SizedBox(height: 8.h),
                      _input(
                        controller.interestController,
                        hint: '0.00',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _helper('Enter the total fixed interest amount'),
                    ]),
                    SizedBox(height: 16.h),
                    _section([
                      _label('Interest expense category'),
                      SizedBox(height: 8.h),
                      _categorySelector(),
                      _helper(
                        'Choose the expense category for borrowing interest',
                      ),
                      SizedBox(height: 12.h),
                      _label('Receiving account'),
                      SizedBox(height: 8.h),
                      _accountSelector(),
                      _helper('The account receiving the borrowed amount'),
                    ]),
                    SizedBox(height: 16.h),
                    _section([
                      _label('Borrowing date'),
                      SizedBox(height: 8.h),
                      Obx(
                        () => _dateField(
                          controller.receiveDate.value,
                          () => controller.selectReceiveDate(context),
                        ),
                      ),
                      _helper('Select when you receive the borrowed amount'),
                      SizedBox(height: 14.h),
                      _label('Expected repayment date'),
                      SizedBox(height: 8.h),
                      Obx(
                        () => _dateField(
                          controller.returnDate.value,
                          () => controller.selectReturnDate(context),
                        ),
                      ),
                      _helper('Select when you expect to repay'),
                    ]),
                    SizedBox(height: 16.h),
                    _section([
                      _label('Notes (optional)'),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: controller.descriptionController,
                        maxLines: 4,
                        minLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        style: _fieldTextStyle(),
                        decoration: _decoration(
                          hint: 'Add the purpose or agreement details...',
                        ),
                      ),
                      _helper('Optional details saved with this borrowing'),
                    ]),
                    SizedBox(height: 20.h),
                    Obx(
                      () => SizedBox(
                        height: 52.h,
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.postBorrow,
                          icon: controller.isLoading.value
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            controller.isLoading.value
                                ? 'Saving...'
                                : 'Save Borrowing',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primary.withValues(
                              alpha: 0.6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            textStyle: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 58.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10.r),
          bottomRight: Radius.circular(10.r),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Text(
            'Borrowing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(List<Widget> children) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11.r),
      border: Border.all(color: mintBorder, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.12),
          offset: Offset(0, 2.h),
          blurRadius: 1,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15.sp,
      color: dark,
      fontWeight: FontWeight.w700,
      fontFamily: 'HankenGrotesk',
    ),
  );

  Widget _input(
    TextEditingController textController, {
    required String hint,
    required IconData icon,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    int? maxLength,
  }) => TextField(
    controller: textController,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    maxLength: maxLength,
    style: _fieldTextStyle(),
    decoration: _decoration(
      hint: hint,
      icon: icon,
      prefixText: prefixText,
    ).copyWith(counterText: ''),
  );

  TextStyle _fieldTextStyle() => TextStyle(
    color: dark,
    fontSize: 15.sp,
    fontWeight: FontWeight.w500,
    fontFamily: 'HankenGrotesk',
  );

  InputDecoration _decoration({
    required String hint,
    IconData? icon,
    String? prefixText,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: PostborrowView.hint, fontSize: 14.sp),
    prefixIcon: icon == null
        ? null
        : Icon(
            icon,
            color: hint == '0.00' ? primary : PostborrowView.hint,
            size: 20.sp,
          ),
    prefixIconConstraints: icon == null
        ? null
        : BoxConstraints(minWidth: 44.w, minHeight: 48.h),
    prefixText: prefixText,
    prefixStyle: TextStyle(
      color: dark,
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
    ),
    isDense: true,
    filled: true,
    fillColor: fieldBackground,
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: primary, width: 1),
    ),
  );

  Widget _helper(String text) => Padding(
    padding: EdgeInsets.only(left: 2.w, top: 6.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 14.sp, color: hint),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: const Color(0xFF7D8DA1),
              fontSize: 12.sp,
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _readOnlyField(String value) => Container(
    width: double.infinity,
    height: 50.h,
    padding: EdgeInsets.symmetric(horizontal: 12.w),
    decoration: BoxDecoration(
      color: fieldBackground,
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: border),
    ),
    child: Row(
      children: [
        Icon(Icons.percent_rounded, color: hint, size: 20.sp),
        SizedBox(width: 12.w),
        Text(
          value,
          style: TextStyle(
            color: dark,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _categorySelector() => Obx(() {
    if (controller.isLoadingCategories.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.categoryLoadError.value.isNotEmpty) {
      return _selectorError(
        controller.categoryLoadError.value,
        controller.loadExpenseCategories,
      );
    }
    if (controller.categories.isEmpty) {
      return _selectorError(
        'No active expense categories available.',
        controller.loadExpenseCategories,
      );
    }
    final selected = controller.selectedInterestCategoryUuid.value;
    final selectedValue =
        controller.categories.any(
          (category) => controller.categoryUuid(category) == selected,
        )
        ? selected
        : null;
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: _decoration(
        hint: 'Select an expense category',
        icon: Icons.category_outlined,
      ),
      style: _fieldTextStyle(),
      items: controller.categories
          .map(
            (category) => DropdownMenuItem<String>(
              value: controller.categoryUuid(category),
              child: Text(
                controller.categoryName(category),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (uuid) => controller.selectedInterestCategoryUuid.value = uuid,
    );
  });

  Widget _accountSelector() => Obx(() {
    if (controller.isLoadingAccounts.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.accountLoadError.value.isNotEmpty) {
      return _selectorError(
        controller.accountLoadError.value,
        controller.loadReceivingAccounts,
      );
    }
    if (controller.accounts.isEmpty) {
      return _selectorError(
        'No active accounts available.',
        controller.loadReceivingAccounts,
      );
    }
    final selected = controller.selectedReceivingAccountUuid.value;
    final selectedValue =
        controller.accounts.any(
          (account) => controller.accountUuid(account) == selected,
        )
        ? selected
        : null;
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: _decoration(
        hint: 'Select the receiving account',
        icon: Icons.account_balance_wallet_outlined,
      ),
      style: _fieldTextStyle(),
      items: controller.accounts
          .map(
            (account) => DropdownMenuItem<String>(
              value: controller.accountUuid(account),
              child: Text(
                controller.accountName(account),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (uuid) => controller.selectedReceivingAccountUuid.value = uuid,
    );
  });

  Widget _selectorError(String message, VoidCallback retry) => Row(
    children: [
      Expanded(
        child: Text(
          message,
          style: TextStyle(color: Colors.red.shade700, fontSize: 12.sp),
        ),
      ),
      TextButton(onPressed: retry, child: const Text('Retry')),
    ],
  );

  Widget _dateField(DateTime? date, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8.r),
    child: Container(
      width: double.infinity,
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: hint, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              date == null
                  ? 'Select date'
                  : '${date.day.toString().padLeft(2, '0')}/'
                        '${date.month.toString().padLeft(2, '0')}/'
                        '${date.year}',
              style: TextStyle(
                color: date == null ? hint : dark,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: hint, size: 20.sp),
        ],
      ),
    ),
  );
}
