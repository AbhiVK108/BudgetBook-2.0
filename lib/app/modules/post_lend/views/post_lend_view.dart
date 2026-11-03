import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/post_lend_controller.dart';

class PostLendView extends GetView<PostLendController> {
  const PostLendView({super.key});

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
                    // BORROWER DETAILS
                    _section(
                      children: [
                        _label('Borrower name'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.personController,
                          hint: 'Person name',
                          icon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                        ),
                        _helper(
                          'Enter the person or business you are lending to',
                        ),

                        SizedBox(height: 14.h),

                        _label('Mobile number (optional)'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.phoneController,
                          hint: '98765 43210',
                          icon: Icons.phone_outlined,
                          prefixText: '+91  ',
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                        ),
                        _helper(
                          'Add a 10-digit number if you want to record it',
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // PRINCIPAL AND INTEREST
                    _section(
                      children: [
                        _label('Principal amount'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.amountController,
                          hint: '0.00',
                          icon: Icons.currency_rupee,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        _helper('Enter the amount you are lending'),

                        SizedBox(height: 14.h),

                        _label('Interest method'),
                        SizedBox(height: 8.h),
                        _readOnlyField(
                          'Fixed interest',
                          icon: Icons.percent_rounded,
                        ),
                        _helper(
                          'Fixed amount due in addition to the principal',
                        ),

                        SizedBox(height: 12.h),

                        _label('Fixed interest amount'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.interestController,
                          hint: '0.00',
                          icon: Icons.currency_rupee,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        _helper('Enter the total fixed interest amount'),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // CATEGORY AND SOURCE ACCOUNT
                    _section(
                      children: [
                        _label('Interest income category'),
                        SizedBox(height: 8.h),
                        _categorySelector(),
                        _helper('Choose the income category for this lending'),

                        SizedBox(height: 12.h),

                        _label('Source account'),
                        SizedBox(height: 8.h),
                        _sourceAccountSelector(),
                        _helper(
                          'The account the lending amount will be paid from',
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // DATES
                    _section(
                      children: [
                        _label('Lending date'),
                        SizedBox(height: 8.h),
                        Obx(
                          () => _dateField(
                            date: controller.giveDate.value,
                            onTap: () => controller.selectGiveDate(context),
                          ),
                        ),
                        _helper('Select when you gave the lending amount'),

                        SizedBox(height: 14.h),

                        _label('Expected repayment date'),
                        SizedBox(height: 8.h),
                        Obx(
                          () => _dateField(
                            date: controller.returnDate.value,
                            onTap: () => controller.selectReturnDate(context),
                          ),
                        ),
                        _helper('Select when you expect repayment'),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // NOTES
                    _section(
                      children: [
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
                        _helper(
                          'Optional details saved with this lending record',
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // SAVE / UPDATE
                    Obx(
                      () => SizedBox(
                        height: 52.h,
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.postLend,
                          icon: controller.isLoading.value
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.save_outlined, size: 21.sp),
                          label: Text(
                            controller.isLoading.value
                                ? (controller.isEditMode.value
                                      ? 'Updating...'
                                      : 'Saving...')
                                : (controller.isEditMode.value
                                      ? 'Update Lending'
                                      : 'Save Lending'),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
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

  // COMPACT TEAL HEADER
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
          Expanded(
            child: Obx(
              () => Text(
                controller.isEditMode.value ? 'Update Lending' : 'Lending',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ),
          ),
          Icon(Icons.more_vert, color: Colors.white, size: 24.sp),
        ],
      ),
    );
  }

  // WHITE CARD WITH MINT BORDER AND BOTTOM SHADOW
  Widget _section({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
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
  }

  // FIELD LABEL
  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.sp,
        color: dark,
        fontWeight: FontWeight.w700,
        fontFamily: 'HankenGrotesk',
      ),
    );
  }

  // TEXT INPUT
  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? prefixText,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      style: _fieldTextStyle(),
      decoration: _decoration(
        hint: hint,
        icon: icon,
        prefixText: prefixText,
        suffixText: suffixText,
      ).copyWith(counterText: ''),
    );
  }

  TextStyle _fieldTextStyle() {
    return TextStyle(
      color: dark,
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      fontFamily: 'HankenGrotesk',
    );
  }

  // SHARED COMPACT INPUT DECORATION
  InputDecoration _decoration({
    required String hint,
    IconData? icon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: hint == '0.00' ? primary : hintColor,
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
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: dark.withValues(alpha: 0.6),
        fontSize: 13.sp,
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
  }

  static const Color hintColor = Color(0xFF94A3B8);

  // HELPER TEXT WITH OPTIONAL TRAILING LABEL
  Widget _helper(String text, {String? trailing}) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w, top: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14.sp, color: hintColor),
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
          if (trailing != null)
            Flexible(
              child: Text(
                trailing,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: hintColor,
                  fontSize: 11.sp,
                  height: 1.25,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _readOnlyField(String value, {required IconData icon}) {
    return Container(
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
          Icon(icon, color: hint, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: dark,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySelector() {
    return Obx(() {
      if (controller.isLoadingCategories.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.categoryLoadError.value.isNotEmpty) {
        return _selectorError(
          controller.categoryLoadError.value,
          controller.loadIncomeCategories,
        );
      }
      if (controller.categories.isEmpty) {
        return _selectorError(
          'No active income categories available.',
          controller.loadIncomeCategories,
        );
      }

      final selectedUuid = controller.selectedInterestCategoryUuid.value;
      final selectedValue =
          controller.categories.any(
            (category) => controller.categoryUuid(category) == selectedUuid,
          )
          ? selectedUuid
          : null;
      return DropdownButtonFormField<String>(
        initialValue: selectedValue,
        isExpanded: true,
        decoration: _decoration(
          hint: 'Select an income category',
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
        onChanged: (uuid) =>
            controller.selectedInterestCategoryUuid.value = uuid,
      );
    });
  }

  Widget _sourceAccountSelector() {
    return Obx(() {
      if (controller.isLoadingAccounts.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.accountLoadError.value.isNotEmpty) {
        return _selectorError(
          controller.accountLoadError.value,
          controller.loadSourceAccounts,
        );
      }
      if (controller.accounts.isEmpty) {
        return _selectorError(
          'No active accounts available.',
          controller.loadSourceAccounts,
        );
      }

      final selectedUuid = controller.selectedSourceAccountUuid.value;
      final selectedValue =
          controller.accounts.any(
            (account) => controller.accountUuid(account) == selectedUuid,
          )
          ? selectedUuid
          : null;
      return DropdownButtonFormField<String>(
        initialValue: selectedValue,
        isExpanded: true,
        decoration: _decoration(
          hint: 'Select the source account',
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
        onChanged: (uuid) => controller.selectedSourceAccountUuid.value = uuid,
      );
    });
  }

  Widget _selectorError(String message, Future<void> Function() onRetry) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: hint, fontSize: 13.sp),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  // DATE PICKER FIELD
  Widget _dateField({required DateTime? date, required VoidCallback onTap}) {
    final String displayDate = date == null
        ? 'mm/dd/yyyy'
        : '${date.month.toString().padLeft(2, '0')}/'
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: fieldBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayDate,
                style: TextStyle(
                  color: date == null ? dark : dark,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.calendar_month_outlined, color: primary, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
