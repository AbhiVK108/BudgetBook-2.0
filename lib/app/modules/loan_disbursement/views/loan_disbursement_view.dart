import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/loan_disbursement_controller.dart';

class LoanDisbursementView extends GetView<LoanDisbursementController> {
  const LoanDisbursementView({super.key});

  static const Color _primary = Color(0xFF079B8D);
  static const Color _dark = Color(0xFF263445);
  static const Color _muted = Color(0xFF7D8DA1);
  static const Color _border = Color(0xFFE2EAF0);
  static const Color _background = Color(0xFFF3F7F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Record disbursement',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _loanSummary(),
                    SizedBox(height: 18.h),
                    _formCard(context),
                  ],
                ),
              ),
            ),
            _submitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _loanSummary() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF079B8D), Color(0xFF087E74)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_outlined,
            color: Colors.white.withValues(alpha: 0.9),
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISBURSEMENT FOR',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  controller.lenderName.isEmpty
                      ? 'Selected loan'
                      : controller.lenderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disbursement details',
            style: TextStyle(
              color: _dark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Enter the gross amount and any processing fee for this '
            'disbursement. The fee is recorded as part of this transaction.',
            style: TextStyle(color: _muted, fontSize: 12.sp),
          ),
          SizedBox(height: 18.h),
          _label('Gross amount'),
          SizedBox(height: 7.h),
          _amountField(controller.grossAmountController, hint: '0.00'),
          SizedBox(height: 16.h),
          _label('Processing fee'),
          SizedBox(height: 7.h),
          _amountField(controller.processingFeeController, hint: '0.00'),
          SizedBox(height: 6.h),
          Text(
            'Enter 0.00 if no processing fee was charged.',
            style: TextStyle(color: _muted, fontSize: 12.sp),
          ),
          SizedBox(height: 16.h),
          _label('Fee expense category'),
          SizedBox(height: 7.h),
          Obx(() {
            if (controller.isLoadingCategories.value) {
              return _choiceMessage('Loading expense categories...');
            }
            if (controller.categoryError.value.isNotEmpty) {
              return _choiceMessage(
                controller.categoryError.value,
                action: TextButton(
                  onPressed: controller.loadExpenseCategories,
                  child: const Text('Retry'),
                ),
              );
            }
            if (controller.expenseCategories.isEmpty) {
              return _choiceMessage('No expense categories are available.');
            }
            return DropdownButtonFormField<String>(
              key: ValueKey(controller.selectedCategoryUuid.value),
              initialValue: controller.selectedCategoryUuid.value,
              isExpanded: true,
              decoration: _decoration(icon: Icons.category_outlined),
              hint: Text(
                'Choose an expense category',
                style: TextStyle(color: _muted, fontSize: 14.sp),
              ),
              items: controller.expenseCategories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: controller.categoryUuid(category),
                      child: Text(
                        controller.categoryLabel(category),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _dark, fontSize: 14.sp),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (uuid) => controller.selectedCategoryUuid.value = uuid,
            );
          }),
          SizedBox(height: 16.h),
          _label('Disbursement date'),
          SizedBox(height: 7.h),
          Obx(
            () => InkWell(
              onTap: () => controller.selectDisbursementDate(context),
              borderRadius: BorderRadius.circular(11.r),
              child: InputDecorator(
                decoration: _decoration(
                  icon: Icons.calendar_today_outlined,
                  suffix: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _muted,
                    size: 22.sp,
                  ),
                ),
                child: Text(
                  controller.formatDate(controller.disbursementDate.value),
                  style: TextStyle(
                    color: _dark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _label('Receiving account'),
          SizedBox(height: 7.h),
          Obx(() {
            if (controller.isLoadingAccounts.value) {
              return _choiceMessage('Loading receiving accounts...');
            }
            if (controller.accountError.value.isNotEmpty) {
              return _choiceMessage(
                controller.accountError.value,
                action: TextButton(
                  onPressed: controller.loadAccounts,
                  child: const Text('Retry'),
                ),
              );
            }
            if (controller.accounts.isEmpty) {
              return _choiceMessage('No active accounts are available.');
            }
            return DropdownButtonFormField<String>(
              key: ValueKey(controller.selectedAccountUuid.value),
              initialValue: controller.selectedAccountUuid.value,
              isExpanded: true,
              decoration: _decoration(
                icon: Icons.account_balance_wallet_outlined,
              ),
              hint: Text(
                'Choose an account',
                style: TextStyle(color: _muted, fontSize: 14.sp),
              ),
              items: controller.accounts
                  .map(
                    (account) => DropdownMenuItem<String>(
                      value: controller.accountUuid(account),
                      child: Text(
                        controller.accountLabel(account),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _dark, fontSize: 14.sp),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (uuid) => controller.selectedAccountUuid.value = uuid,
            );
          }),
        ],
      ),
    );
  }

  Widget _amountField(
    TextEditingController textController, {
    required String hint,
  }) {
    return TextField(
      controller: textController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          return RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newValue.text)
              ? newValue
              : oldValue;
        }),
      ],
      style: TextStyle(
        color: _dark,
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
      ),
      decoration: _decoration(
        hint: hint,
        prefixText: '₹ ',
        icon: Icons.payments_outlined,
      ),
    );
  }

  Widget _choiceMessage(String message, {Widget? action}) {
    return Container(
      constraints: BoxConstraints(minHeight: 52.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _muted, fontSize: 12.sp),
            ),
          ),
          ?action,
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      color: _dark,
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _decoration({
    String? hint,
    String? prefixText,
    Widget? suffix,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _muted, fontSize: 14.sp),
      prefixIcon: icon == null ? null : Icon(icon, color: _muted, size: 19.sp),
      prefixIconConstraints: BoxConstraints(minWidth: 44.w, minHeight: 48.h),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: _muted,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F9FB),
      contentPadding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 13.h),
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
        borderSide: const BorderSide(color: _primary, width: 1.2),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton.icon(
            onPressed: controller.isSubmitting.value
                ? null
                : () => _confirmDisbursement(context),
            icon: controller.isSubmitting.value
                ? SizedBox(
                    width: 19.w,
                    height: 19.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              controller.isSubmitting.value
                  ? 'Recording...'
                  : 'Record disbursement',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withValues(alpha: 0.65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDisbursement(BuildContext context) async {
    final gross = double.tryParse(controller.grossAmountController.text.trim());
    final feeText = controller.processingFeeController.text.trim();
    final fee = feeText.isEmpty ? 0.0 : double.tryParse(feeText);
    if (gross == null ||
        !gross.isFinite ||
        gross <= 0 ||
        fee == null ||
        !fee.isFinite ||
        fee < 0) {
      await controller.submitDisbursement();
      return;
    }

    String? accountName;
    for (final account in controller.accounts) {
      if (controller.accountUuid(account) ==
          controller.selectedAccountUuid.value) {
        accountName = controller.accountLabel(account);
        break;
      }
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm loan disbursement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gross amount: ₹${gross.toStringAsFixed(2)}'),
            SizedBox(height: 6.h),
            Text('Processing fee: ₹${fee.toStringAsFixed(2)}'),
            SizedBox(height: 6.h),
            Text(
              'Disbursement date: '
              '${controller.formatDate(controller.disbursementDate.value)}',
            ),
            if (accountName != null) ...[
              SizedBox(height: 6.h),
              Text('Receiving account: $accountName'),
            ],
            SizedBox(height: 10.h),
            const Text(
              'The API records the gross amount and fee. Confirm the net '
              'amount with your lender before submitting.',
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
            child: const Text('Confirm disbursement'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.submitDisbursement();
  }
}
