import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/postloan_controller.dart';

class PostloanView extends GetView<PostloanController> {
  const PostloanView({super.key});

  static const Color primary = Color(0xFF079B8D);
  static const Color dark = Color(0xFF263445);
  static const Color hint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2EAF0);
  static const Color background = Color(0xFFF3F5F5);
  static const Color fieldBackground = Color(0xFFF7F9FB);
  static const Color mintBorder = Color(0xFFBCEBE4);

  Future<void> _confirmContractCreation(BuildContext context) async {
    final sanctioned = double.tryParse(
      controller.sanctionedAmountController.text.trim(),
    );
    final principal = double.tryParse(
      controller.principalAmountController.text.trim(),
    );
    final annualRate = double.tryParse(
      controller.annualInterestRateController.text.trim(),
    );
    final tenure = int.tryParse(controller.tenureMonthsController.text.trim());
    if (controller.loanNameController.text.trim().isEmpty ||
        controller.lenderNameController.text.trim().isEmpty ||
        sanctioned == null ||
        principal == null ||
        annualRate == null ||
        tenure == null ||
        controller.firstDueDate.value == null ||
        controller.selectedAccountUuid.value == null ||
        controller.selectedExpenseCategoryUuid.value == null) {
      await controller.postLoan();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create loan contract?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loan: ${controller.loanNameController.text.trim()}'),
            SizedBox(height: 6.h),
            Text('Lender: ${controller.lenderNameController.text.trim()}'),
            SizedBox(height: 6.h),
            Text('Principal: INR ${principal.toStringAsFixed(2)}'),
            SizedBox(height: 6.h),
            Text('Sanctioned: INR ${sanctioned.toStringAsFixed(2)}'),
            SizedBox(height: 6.h),
            Text('Annual interest rate: ${annualRate.toStringAsFixed(4)}%'),
            SizedBox(height: 6.h),
            Text('Tenure: $tenure months'),
            SizedBox(height: 12.h),
            const Text(
              'This creates the loan contract only. It does not disburse '
              'funds; record a disbursement separately when money is received.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create contract'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.postLoan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section(
                      title: 'LOAN DETAILS',
                      icon: Icons.account_balance_outlined,
                      children: [
                        _label('Loan name'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.loanNameController,
                          hint: 'e.g. Home loan',
                          icon: Icons.edit_note_outlined,
                          textCapitalization: TextCapitalization.words,
                        ),
                        SizedBox(height: 14.h),
                        _label('Loan type'),
                        SizedBox(height: 8.h),
                        Obx(
                          () => _dropdown<String>(
                            value: controller.selectedLoanType.value,
                            icon: Icons.category_outlined,
                            items: PostloanController.loanTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(_titleCase(type)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedLoanType.value = value;
                              }
                            },
                          ),
                        ),
                        _helper(
                          'Choose the type that best describes this loan',
                        ),
                        SizedBox(height: 14.h),
                        _label('Lender name'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.lenderNameController,
                          hint: 'Bank or lender name',
                          icon: Icons.business_outlined,
                          textCapitalization: TextCapitalization.words,
                        ),
                        SizedBox(height: 14.h),
                        _label('Lender reference (optional)'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.lenderReferenceController,
                          hint: 'Loan account or reference number',
                          icon: Icons.tag_outlined,
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _section(
                      title: 'AMOUNT & INTEREST',
                      icon: Icons.payments_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _label('Sanctioned amount')),
                            SizedBox(width: 12.w),
                            Expanded(child: _label('Principal amount')),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: _input(
                                controller:
                                    controller.sanctionedAmountController,
                                hint: '0.00',
                                icon: Icons.currency_rupee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _input(
                                controller:
                                    controller.principalAmountController,
                                hint: '0.00',
                                icon: Icons.currency_rupee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        _helper(
                          'Amounts are recorded in INR. Principal cannot exceed the sanctioned amount.',
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(child: _label('Annual interest rate')),
                            SizedBox(width: 12.w),
                            Expanded(child: _label('Tenure')),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: _input(
                                controller:
                                    controller.annualInterestRateController,
                                hint: 'e.g. 8.5000',
                                icon: Icons.percent_rounded,
                                suffixText: '%',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _input(
                                controller: controller.tenureMonthsController,
                                hint: 'Months',
                                icon: Icons.calendar_month_outlined,
                                suffixText: 'months',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _section(
                      title: 'REPAYMENT SETUP',
                      icon: Icons.event_available_outlined,
                      children: [
                        _label('First due date'),
                        SizedBox(height: 8.h),
                        Obx(
                          () => _dateField(
                            controller.firstDueDate.value,
                            onTap: () => controller.selectFirstDueDate(context),
                          ),
                        ),
                        _helper('Select the date your first repayment is due'),
                        SizedBox(height: 14.h),
                        _label('Repayment account'),
                        SizedBox(height: 8.h),
                        Obx(() => _accountSelector()),
                        _helper('Account used to make loan repayments'),
                        SizedBox(height: 14.h),
                        _label('Interest expense category'),
                        SizedBox(height: 8.h),
                        Obx(() => _categorySelector()),
                        _helper('Expense category used to track loan interest'),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _section(
                      title: 'NOTES',
                      icon: Icons.notes_outlined,
                      children: [
                        _label('Notes (optional)'),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: controller.notesController,
                          minLines: 3,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: _fieldTextStyle(),
                          decoration: _decoration(
                            hint: 'Add any details about this loan...',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Obx(
                      () => SizedBox(
                        height: 52.h,
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => _confirmContractCreation(context),
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
                                ? 'Saving loan...'
                                : 'Create loan contract',
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

  Widget _appBar() {
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
            'Post a loan',
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

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 19.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF26796F),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String value) => Text(
    value,
    style: TextStyle(
      fontSize: 14.sp,
      color: dark,
      fontWeight: FontWeight.w700,
      fontFamily: 'HankenGrotesk',
    ),
  );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: _fieldTextStyle(),
      decoration: _decoration(hint: hint, icon: icon, suffixText: suffixText),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      style: _fieldTextStyle(),
      decoration: _decoration(hint: '', icon: icon),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: hint, size: 22.sp),
    );
  }

  Widget _accountSelector() {
    if (controller.isLoadingAccounts.value) return _loadingSelector();
    if (controller.accountLoadError.value.isNotEmpty) {
      return _retrySelector(
        controller.accountLoadError.value,
        controller.loadAccounts,
      );
    }
    if (controller.accounts.isEmpty) {
      return _retrySelector(
        'No active accounts available. Add an account and retry.',
        controller.loadAccounts,
      );
    }
    return _dropdown<String>(
      value:
          controller.accounts.any(
            (account) =>
                controller.accountUuid(account) ==
                controller.selectedAccountUuid.value,
          )
          ? controller.selectedAccountUuid.value!
          : controller.accountUuid(controller.accounts.first),
      icon: Icons.account_balance_wallet_outlined,
      items: controller.accounts
          .map(
            (account) => DropdownMenuItem(
              value: controller.accountUuid(account),
              child: Text(
                controller.accountName(account),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) => controller.selectedAccountUuid.value = value,
    );
  }

  Widget _categorySelector() {
    if (controller.isLoadingCategories.value) return _loadingSelector();
    if (controller.categoryLoadError.value.isNotEmpty) {
      return _retrySelector(
        controller.categoryLoadError.value,
        controller.loadExpenseCategories,
      );
    }
    if (controller.expenseCategories.isEmpty) {
      return _retrySelector(
        'No expense categories available. Add a category and retry.',
        controller.loadExpenseCategories,
      );
    }
    return _dropdown<String>(
      value:
          controller.expenseCategories.any(
            (category) =>
                controller.categoryUuid(category) ==
                controller.selectedExpenseCategoryUuid.value,
          )
          ? controller.selectedExpenseCategoryUuid.value!
          : controller.categoryUuid(controller.expenseCategories.first),
      icon: Icons.receipt_long_outlined,
      items: controller.expenseCategories
          .map(
            (category) => DropdownMenuItem(
              value: controller.categoryUuid(category),
              child: Text(
                controller.categoryName(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) =>
          controller.selectedExpenseCategoryUuid.value = value,
    );
  }

  Widget _loadingSelector() => Container(
    height: 48.h,
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.symmetric(horizontal: 14.w),
    decoration: BoxDecoration(
      color: fieldBackground,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: SizedBox(
      width: 18.w,
      height: 18.w,
      child: const CircularProgressIndicator(strokeWidth: 2, color: primary),
    ),
  );

  Widget _retrySelector(String message, VoidCallback onRetry) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: fieldBackground,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: const Color(0xFF7D8DA1), fontSize: 12.sp),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _dateField(DateTime? date, {required VoidCallback onTap}) {
    final text = date == null
        ? 'Select first repayment date'
        : controller.formatDate(date);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: fieldBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: hint, size: 19.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: date == null ? hint : dark,
                  fontSize: 14.sp,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: hint, size: 22.sp),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    IconData? icon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      hintStyle: TextStyle(color: PostloanView.hint, fontSize: 13.sp),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: PostloanView.hint, size: 19.sp),
      prefixIconConstraints: icon == null
          ? null
          : BoxConstraints(minWidth: 42.w, minHeight: 48.h),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: dark.withValues(alpha: 0.65),
        fontSize: 12.sp,
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

  TextStyle _fieldTextStyle() => TextStyle(
    color: dark,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    fontFamily: 'HankenGrotesk',
  );

  Widget _helper(String text) {
    return Padding(
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
                fontSize: 11.sp,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) =>
      value[0].toUpperCase() + value.substring(1);
}
