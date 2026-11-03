import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/loan_prepayment_controller.dart';

class LoanPrepaymentView extends GetView<LoanPrepaymentController> {
  const LoanPrepaymentView({super.key});

  static const Color _primary = Color(0xFF079B8D);
  static const Color _dark = Color(0xFF263445);
  static const Color _muted = Color(0xFF7D8DA1);
  static const Color _border = Color(0xFFE2EAF0);
  static const Color _background = Color(0xFFF3F7F6);

  @override
  Widget build(BuildContext context) {
    final outstanding = double.tryParse(controller.outstandingPrincipal ?? '');
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Principal prepayment',
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
                    if (outstanding != null && outstanding.isFinite) ...[
                      SizedBox(height: 10.h),
                      _outstandingPrincipalCard(outstanding),
                    ],
                    SizedBox(height: 12.h),
                    _partialInstallmentNotice(),
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
                  'PREPAYMENT FOR',
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

  Widget _outstandingPrincipalCard(double amount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: _primary,
            size: 19.sp,
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              'Outstanding principal',
              style: TextStyle(color: _muted, fontSize: 12.sp),
            ),
          ),
          Text(
            '${controller.currency} ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: _dark,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _partialInstallmentNotice() {
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: const Color(0xFF9A3412), size: 18.sp),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              'Resolve any partial installment before recording a principal '
              'prepayment.',
              style: TextStyle(color: const Color(0xFF9A3412), fontSize: 12.sp),
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
            'Prepayment details',
            style: TextStyle(
              color: _dark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 18.h),
          _label('Amount'),
          SizedBox(height: 7.h),
          TextField(
            controller: controller.amountController,
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
              hint: '0.00',
              prefixText: '${controller.currency} ',
              icon: Icons.payments_outlined,
            ),
          ),
          SizedBox(height: 16.h),
          _label('Payment date'),
          SizedBox(height: 7.h),
          Obx(
            () => InkWell(
              onTap: () => controller.selectPrepaymentDate(context),
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
                  controller.formatDate(controller.prepaymentDate.value),
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
          _label('Source account'),
          SizedBox(height: 7.h),
          Obx(() {
            if (controller.isLoadingAccounts.value) {
              return _accountMessage(
                const CircularProgressIndicator(
                  color: _primary,
                  strokeWidth: 2,
                ),
                'Loading accounts...',
              );
            }
            if (controller.accountError.value.isNotEmpty) {
              return _accountMessage(
                Icon(Icons.error_outline, color: Colors.red.shade600),
                controller.accountError.value,
                action: TextButton(
                  onPressed: controller.loadAccounts,
                  child: const Text('Retry'),
                ),
              );
            }
            if (controller.accounts.isEmpty) {
              return _accountMessage(
                Icon(Icons.account_balance_outlined, color: _muted),
                'No active accounts are available.',
              );
            }
            return DropdownButtonFormField<String>(
              key: ValueKey(controller.selectedAccountUuid.value),
              initialValue: controller.selectedAccountUuid.value,
              isExpanded: true,
              decoration: _decoration(
                icon: Icons.account_balance_wallet_outlined,
              ),
              hint: Text(
                'Choose a source account',
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
          SizedBox(height: 16.h),
          _label('Reference'),
          SizedBox(height: 7.h),
          TextField(
            controller: controller.referenceController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 80,
            decoration: _decoration(
              hint: 'Optional payment reference',
              icon: Icons.tag_outlined,
            ).copyWith(counterText: ''),
          ),
          SizedBox(height: 16.h),
          _label('Description'),
          SizedBox(height: 7.h),
          TextField(
            controller: controller.descriptionController,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: _decoration(
              hint: 'Describe this principal prepayment',
              icon: Icons.notes_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountMessage(Widget icon, String message, {Widget? action}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          SizedBox(width: 20.w, height: 20.h, child: icon),
          SizedBox(width: 9.w),
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
                : () => _confirmPrepayment(context),
            icon: controller.isSubmitting.value
                ? SizedBox(
                    width: 18.w,
                    height: 18.h,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              controller.isSubmitting.value
                  ? 'Recording...'
                  : 'Record prepayment',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              textStyle: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPrepayment(BuildContext context) async {
    final amount = double.tryParse(controller.amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      await controller.submitPrepayment();
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
    final outstanding = double.tryParse(controller.outstandingPrincipal ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm principal prepayment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${controller.currency} ${amount.toStringAsFixed(2)}'),
            SizedBox(height: 6.h),
            Text(
              'Payment date: ${controller.formatDate(controller.prepaymentDate.value)}',
            ),
            if (accountName != null) ...[
              SizedBox(height: 6.h),
              Text('Source account: $accountName'),
            ],
            if (outstanding != null && outstanding.isFinite) ...[
              SizedBox(height: 6.h),
              Text(
                'Outstanding principal: ${controller.currency} '
                '${outstanding.toStringAsFixed(2)}',
              ),
            ],
            SizedBox(height: 10.h),
            const Text(
              'This records an early principal payment. Confirm the details '
              'before submitting.',
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
            child: const Text('Confirm prepayment'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.submitPrepayment();
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      color: _dark,
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _decoration({
    String? hint,
    String? prefixText,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: Icon(icon, color: _muted, size: 19.sp),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFCFDFE),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      hintStyle: TextStyle(color: _muted, fontSize: 13.sp),
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
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
    );
  }
}
