import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
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

  Future<void> _submit(BuildContext context) async {
    final saved = await controller.postLoan();
    if (!saved || !context.mounted) return;

    Navigator.of(context).pop(true);
  }

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
      await _submit(context);
      return;
    }

    final loanName = controller.loanNameController.text.trim();
    final lenderName = controller.lenderNameController.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFE5EFED)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF163D38).withValues(alpha: 0.12),
                  blurRadius: 24.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F4),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD3F0E9),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.fact_check_outlined,
                          color: const Color(0xFF078779),
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review loan contract',
                              style: TextStyle(
                                color: const Color(0xFF263445),
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              'Confirm the details before creating',
                              style: TextStyle(
                                color: const Color(0xFF71808E),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loan identity
                      Text(
                        'LOAN DETAILS',
                        style: TextStyle(
                          color: const Color(0xFF71808E),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                      SizedBox(height: 10.h),

                      _confirmationDetailRow(
                        icon: Icons.description_outlined,
                        label: 'Loan name',
                        value: loanName,
                      ),
                      SizedBox(height: 11.h),
                      _confirmationDetailRow(
                        icon: Icons.account_balance_outlined,
                        label: 'Lender',
                        value: lenderName,
                      ),

                      SizedBox(height: 17.h),

                      // Principal highlight
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(15.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F8F6),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFFD5ECE6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRINCIPAL AMOUNT',
                              style: TextStyle(
                                color: const Color(0xFF64817B),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              '₹${principal.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: const Color(0xFF08796F),
                                fontSize: 23.sp,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Financial summary
                      Text(
                        'CONTRACT SUMMARY',
                        style: TextStyle(
                          color: const Color(0xFF71808E),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                      SizedBox(height: 10.h),

                      _confirmationSummaryRow(
                        'Sanctioned amount',
                        '₹${sanctioned.toStringAsFixed(2)}',
                      ),
                      _confirmationSummaryRow(
                        'Annual interest rate',
                        '${annualRate.toStringAsFixed(4)}%',
                      ),
                      _confirmationSummaryRow('Loan tenure', '$tenure months'),

                      SizedBox(height: 15.h),

                      // Important information
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EB),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFF1E2C2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: const Color(0xFFB17A27),
                              size: 18.sp,
                            ),
                            SizedBox(width: 9.w),
                            Expanded(
                              child: Text(
                                'Creating this contract will only save the loan details. '
                                'It will not disburse any funds. Record a separate '
                                'disbursement when the loan amount is received.',
                                style: TextStyle(
                                  color: const Color(0xFF806333),
                                  fontSize: 11.sp,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'HankenGrotesk',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46.h,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(false);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF52616D),
                                  side: const BorderSide(
                                    color: Color(0xFFDCE5E8),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9.r),
                                  ),
                                ),
                                child: Text(
                                  'Review',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'HankenGrotesk',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 46.h,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(true);
                                },
                                icon: Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 17.sp,
                                ),
                                label: Text(
                                  'Create contract',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'HankenGrotesk',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF079B8D),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9.r),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;

    if (confirmed == true) {
      await _submit(context);
    }
  }

  Widget _confirmationDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6F7),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: const Color(0xFF71808E), size: 17.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF87939D),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF263445),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _confirmationSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF71808E),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF263445),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
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
      return _emptySelector(
        'No active accounts available. Add an account and retry.',
        'Add account',
        () async {
          await Get.toNamed(Routes.bankAccounts);
          await controller.loadAccounts();
        },
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
    Widget selector;

    if (controller.isLoadingCategories.value) {
      selector = _loadingSelector();
    } else if (controller.categoryLoadError.value.isNotEmpty) {
      selector = _retrySelector(
        controller.categoryLoadError.value,
        controller.loadExpenseCategories,
      );
    } else if (controller.expenseCategories.isEmpty) {
      selector = _emptySelector(
        'No expense categories available. Add one to continue.',
        'Add category',
        _openAddExpenseCategory,
      );
    } else {
      final selectedUuid = controller.selectedExpenseCategoryUuid.value;

      final selectedValue =
          controller.expenseCategories.any(
            (category) => controller.categoryUuid(category) == selectedUuid,
          )
          ? selectedUuid
          : controller.categoryUuid(controller.expenseCategories.first);

      selector = _dropdown<String>(
        value: selectedValue.toString(),
        icon: Icons.receipt_long_outlined,
        items: controller.expenseCategories.map((category) {
          return DropdownMenuItem<String>(
            value: controller.categoryUuid(category),
            child: Text(
              controller.categoryName(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          controller.selectedExpenseCategoryUuid.value = value;
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [selector, _addExpenseCategoryButton()],
    );
  }

  Widget _addExpenseCategoryButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _openAddExpenseCategory,
        icon: Icon(Icons.add_rounded, size: 17.sp),
        label: const Text('Add new'),
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          minimumSize: Size(0, 32.h),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'HankenGrotesk',
          ),
        ),
      ),
    );
  }

  Future<void> _openAddExpenseCategory() async {
    await Get.toNamed(Routes.ADD_EXPENSE_CATEGORY);

    await controller.loadExpenseCategories();
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

  Widget _emptySelector(
    String message,
    String actionLabel,
    VoidCallback onAction,
  ) {
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
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: TextStyle(color: primary, fontWeight: FontWeight.w700),
            ),
          ),
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
