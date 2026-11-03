import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/lending_repayment_controller.dart';

class LendingRepaymentView extends GetView<LendingRepaymentController> {
  const LendingRepaymentView({super.key});

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
          'Record repayment',
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
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _loanSummary() {
    final outstanding = double.tryParse(controller.outstandingAmount) ?? 0;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPAYMENT FOR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            controller.borrowerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white.withValues(alpha: 0.85),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Outstanding balance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${controller.currency} ${outstanding.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
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
            'Repayment details',
            style: TextStyle(
              color: _dark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 18.h),
          _label(
            controller.isBorrowing ? 'Amount paid' : 'Amount received',
          ),
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
          _label('Repayment date'),
          SizedBox(height: 7.h),
          Obx(
            () => InkWell(
              onTap: () => controller.selectRepaymentDate(context),
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
                  controller.formatDate(controller.repaymentDate.value),
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
          _label(
            controller.isBorrowing ? 'Source account' : 'Receiving account',
          ),
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
              initialValue: controller.selectedAccountUuid.value,
              isExpanded: true,
              decoration: _decoration(icon: Icons.account_balance_outlined),
              hint: Text(
                controller.isBorrowing
                    ? 'Choose a source account'
                    : 'Choose an account',
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
            style: TextStyle(color: _dark, fontSize: 14.sp),
            decoration: _decoration(
              hint: 'e.g. POSTMAN-LEND-REPAYMENT',
              icon: Icons.tag_outlined,
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            'Optional transaction reference',
            style: TextStyle(color: _muted, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _accountMessage(Widget icon, String message, {Widget? action}) {
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
          SizedBox(width: 20.w, height: 20.w, child: icon),
          SizedBox(width: 10.w),
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

  Widget _submitButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton.icon(
            onPressed: controller.isSubmitting.value
                ? null
                : controller.submitRepayment,
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
                  : 'Record repayment',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withValues(alpha: 0.65),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
