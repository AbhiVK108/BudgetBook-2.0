import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/post_lend_controller.dart';

class PostLendView extends GetView<PostLendController> {
  const PostLendView({super.key});

  static const Color _teal = Color(0xFF0F8F7F);
  static const Color _ink = Color(0xFF172B3A);
  static const Color _muted = Color(0xFF87949F);
  static const Color _background = Color(0xFFF4F7F8);
  static const Color _border = Color(0xFFE8EEEE);
  static const Color _fieldBackground = Color(0xFFF8FAFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BORROWER DETAILS
              _section(
                title: 'Borrower details',
                subtitle: 'Who are you lending money to?',
                icon: Icons.person_outline_rounded,
                children: [
                  _label('Borrower name'),
                  SizedBox(height: 6.h),
                  _input(
                    controller: controller.personController,
                    hint: 'Enter person or business name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                  ),
                  _helper('Enter the person or business name'),

                  SizedBox(height: 12.h),

                  _label('Mobile number', optional: true),
                  SizedBox(height: 6.h),
                  _input(
                    controller: controller.phoneController,
                    hint: '98765 43210',
                    icon: Icons.phone_outlined,
                    prefixText: '+91  ',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                  ),
                  _helper('Add a number for quick contact'),
                ],
              ),

              SizedBox(height: 12.h),

              // PRINCIPAL AND INTEREST
              _section(
                title: 'Amount & interest',
                subtitle: 'Set the lending amount and interest',
                icon: Icons.account_balance_wallet_outlined,
                children: [
                  _label('Principal amount'),
                  SizedBox(height: 6.h),
                  _input(
                    controller: controller.amountController,
                    hint: '0.00',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _helper('Enter the amount you are lending'),

                  SizedBox(height: 12.h),

                  _label('Interest method'),
                  SizedBox(height: 6.h),
                  _readOnlyField('Fixed interest', icon: Icons.percent_rounded),
                  _helper('A fixed amount added to the principal'),

                  SizedBox(height: 12.h),

                  _label('Fixed interest amount'),
                  SizedBox(height: 6.h),
                  _input(
                    controller: controller.interestController,
                    hint: '0.00',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _helper('Enter the total fixed interest amount'),
                ],
              ),

              SizedBox(height: 12.h),

              // CATEGORY AND SOURCE ACCOUNT
              _section(
                title: 'Financial details',
                subtitle: 'Choose where the transaction belongs',
                icon: Icons.account_balance_outlined,
                children: [
                  _label('Interest income category'),
                  SizedBox(height: 6.h),
                  _categorySelector(),
                  _helper('Select the category for interest income'),

                  SizedBox(height: 12.h),

                  _label('Source account'),
                  SizedBox(height: 6.h),
                  _sourceAccountSelector(),
                  _helper('Account from which money will be paid'),
                ],
              ),

              SizedBox(height: 12.h),

              // DATES
              _section(
                title: 'Lending schedule',
                subtitle: 'Set the lending and repayment dates',
                icon: Icons.calendar_month_outlined,
                children: [
                  _label('Lending date'),
                  SizedBox(height: 6.h),
                  Obx(
                    () => _dateField(
                      date: controller.giveDate.value,
                      onTap: () => controller.selectGiveDate(context),
                    ),
                  ),
                  _helper('When you gave the lending amount'),

                  SizedBox(height: 12.h),

                  _label('Expected repayment date'),
                  SizedBox(height: 6.h),
                  Obx(
                    () => _dateField(
                      date: controller.returnDate.value,
                      onTap: () => controller.selectReturnDate(context),
                    ),
                  ),
                  _helper('When you expect the amount to be repaid'),
                ],
              ),

              SizedBox(height: 12.h),

              // NOTES
              _section(
                title: 'Additional notes',
                subtitle: 'Add any useful agreement details',
                icon: Icons.notes_rounded,
                children: [
                  _label('Notes', optional: true),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: controller.descriptionController,
                    maxLines: 4,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: _fieldTextStyle(),
                    decoration: _decoration(
                      hint: 'Add purpose or agreement details...',
                    ),
                  ),
                  _helper('Optional details saved with this record'),
                ],
              ),

              SizedBox(height: 18.h),

              // SAVE / UPDATE
              Obx(
                () => SizedBox(
                  height: 49.h,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.postLend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      disabledBackgroundColor: _teal.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                controller.isEditMode.value
                                    ? 'Updating...'
                                    : 'Saving...',
                                style: _buttonTextStyle(),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined, size: 19.sp),
                              SizedBox(width: 9.w),
                              Text(
                                controller.isEditMode.value
                                    ? 'Update lending'
                                    : 'Save lending',
                                style: _buttonTextStyle(),
                              ),
                            ],
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

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 66.h,
      leadingWidth: 48.w,
      leading: IconButton(
        onPressed: Get.back,
        splashRadius: 22.r,
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp, color: _ink),
      ),
      titleSpacing: 4.w,
      title: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.isEditMode.value ? 'MONEY OUT' : 'MONEY OUT',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: _teal,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              controller.isEditMode.value ? 'Update lending' : 'Add lending',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: _ink,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION CARD
  // ---------------------------------------------------------------------------

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173C45).withValues(alpha: 0.035),
            blurRadius: 13,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 33.w,
                height: 33.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F3),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, size: 17.sp, color: _teal),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          ...children,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LABELS AND INPUTS
  // ---------------------------------------------------------------------------

  Widget _label(String text, {bool optional = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5.sp,
            color: _ink,
            fontWeight: FontWeight.w700,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        if (optional) ...[
          SizedBox(width: 5.w),
          Text(
            'OPTIONAL',
            style: TextStyle(
              color: _muted,
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ],
    );
  }

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
      color: _ink,
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      fontFamily: 'HankenGrotesk',
    );
  }

  TextStyle _buttonTextStyle() {
    return TextStyle(
      color: Colors.white,
      fontSize: 14.sp,
      fontWeight: FontWeight.w800,
      fontFamily: 'HankenGrotesk',
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED INPUT DECORATION
  // ---------------------------------------------------------------------------

  InputDecoration _decoration({
    required String hint,
    IconData? icon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _muted.withValues(alpha: 0.9),
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        fontFamily: 'HankenGrotesk',
      ),
      prefixIcon: icon == null ? null : Icon(icon, color: _teal, size: 18.sp),
      prefixIconConstraints: icon == null
          ? null
          : BoxConstraints(minWidth: 42.w, minHeight: 44.h),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: _ink,
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        fontFamily: 'HankenGrotesk',
      ),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: _muted,
        fontSize: 11.sp,
        fontFamily: 'HankenGrotesk',
      ),
      isDense: true,
      filled: true,
      fillColor: _fieldBackground,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: const BorderSide(color: _teal, width: 1.2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER TEXT
  // ---------------------------------------------------------------------------

  Widget _helper(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w, top: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 12.sp, color: _muted),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _muted,
                fontSize: 10.sp,
                height: 1.25,
                fontFamily: 'HankenGrotesk',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // READ-ONLY FIELD
  // ---------------------------------------------------------------------------

  Widget _readOnlyField(String value, {required IconData icon}) {
    return Container(
      width: double.infinity,
      height: 45.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _teal, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _ink,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 14.sp, color: _muted),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY SELECTOR
  // ---------------------------------------------------------------------------

  Widget _categorySelector() {
    return Obx(() {
      if (controller.isLoadingCategories.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_selectorLoading(), _addIncomeCategoryButton()],
        );
      }

      final selector = controller.categoryLoadError.value.isNotEmpty
          ? _selectorError(
              controller.categoryLoadError.value,
              controller.loadIncomeCategories,
            )
          : controller.categories.isEmpty
          ? _emptyCategorySelector()
          : _categoryDropdown();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [selector, _addIncomeCategoryButton()],
      );
    });
  }

  Widget _categoryDropdown() {
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
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: _muted, size: 22.sp),
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
                style: _fieldTextStyle(),
              ),
            ),
          )
          .toList(),
      onChanged: (uuid) => controller.selectedInterestCategoryUuid.value = uuid,
    );
  }

  Widget _addIncomeCategoryButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _openAddIncomeCategory,
        icon: Icon(Icons.add_rounded, size: 17.sp),
        label: const Text('Add new'),
        style: TextButton.styleFrom(
          foregroundColor: _teal,
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          minimumSize: Size(0, 32.h),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'HankenGrotesk',
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SOURCE ACCOUNT SELECTOR
  // ---------------------------------------------------------------------------

  Widget _sourceAccountSelector() {
    return Obx(() {
      if (controller.isLoadingAccounts.value) {
        return _selectorLoading();
      }

      if (controller.accountLoadError.value.isNotEmpty) {
        return _selectorError(
          controller.accountLoadError.value,
          controller.loadSourceAccounts,
        );
      }

      if (controller.accounts.isEmpty) {
        return _noSourceAccounts();
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
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _muted,
          size: 22.sp,
        ),
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
                  style: _fieldTextStyle(),
                ),
              ),
            )
            .toList(),
        onChanged: (uuid) => controller.selectedSourceAccountUuid.value = uuid,
      );
    });
  }

  Widget _noSourceAccounts() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F1),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: const Color(0xFFF3DED5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: const Color(0xFFD47755),
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'No active accounts available.',
              style: TextStyle(
                color: _ink,
                fontSize: 10.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Get.toNamed(Routes.bankAccounts);
              await controller.loadSourceAccounts();
            },
            style: TextButton.styleFrom(
              foregroundColor: _teal,
              padding: EdgeInsets.symmetric(horizontal: 7.w),
              minimumSize: Size(0, 30.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Add account',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SELECTOR STATES
  // ---------------------------------------------------------------------------

  Widget _selectorLoading() {
    return Container(
      height: 45.h,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 15.w,
            height: 15.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: _teal,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Loading...',
            style: TextStyle(
              color: _muted,
              fontSize: 11.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorError(String message, Future<void> Function() onRetry) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F1),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: const Color(0xFFF3DED5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: const Color(0xFFD47755),
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _ink,
                fontSize: 10.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: _teal,
              padding: EdgeInsets.symmetric(horizontal: 7.w),
              minimumSize: Size(0, 30.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCategorySelector() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F1),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: const Color(0xFFF3DED5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_outlined,
            color: const Color(0xFFD47755),
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'No income categories yet. Add one to continue.',
              style: TextStyle(
                color: _ink,
                fontSize: 10.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddIncomeCategory() async {
    final result = await Get.toNamed(Routes.ADD_INCOME_CATEGORY);
    await controller.loadIncomeCategories();
    if (result is! Map) return;

    final category = Map<String, dynamic>.from(result);
    final uuid = controller.categoryUuid(category);
    if (uuid.isEmpty) return;

    final existingIndex = controller.categories.indexWhere(
      (item) => controller.categoryUuid(item) == uuid,
    );
    if (existingIndex >= 0) {
      controller.categories[existingIndex] = category;
    } else {
      controller.categories.add(category);
    }
    controller.selectedInterestCategoryUuid.value = uuid;
  }

  // ---------------------------------------------------------------------------
  // DATE PICKER FIELD
  // ---------------------------------------------------------------------------

  Widget _dateField({required DateTime? date, required VoidCallback onTap}) {
    final String displayDate = date == null
        ? 'Select date'
        : '${date.month.toString().padLeft(2, '0')}/'
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.year}';

    return Material(
      color: _fieldBackground,
      borderRadius: BorderRadius.circular(11.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11.r),
        child: Container(
          height: 45.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: _teal, size: 18.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  displayDate,
                  style: TextStyle(
                    color: date == null ? _muted : _ink,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _muted,
                size: 21.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
