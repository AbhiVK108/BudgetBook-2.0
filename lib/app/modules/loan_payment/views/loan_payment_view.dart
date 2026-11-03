import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/loan_payment_controller.dart';

class LoanPaymentView extends GetView<LoanPaymentController> {
  const LoanPaymentView({super.key});

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
          'Record loan payment',
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
                    _paymentForm(context),
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
    final due = double.tryParse(controller.dueAmount);
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
            'PAYMENT FOR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            controller.lenderName,
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
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.sp,
                  ),
                ),
              ),
              Text(
                due == null || !due.isFinite
                    ? '—'
                    : '₹${due.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentForm(BuildContext context) {
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
            'Payment details',
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
            decoration: _decoration(
              hint: '0.00',
              prefixText: '₹ ',
              icon: Icons.payments_outlined,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Enter the amount paid toward the selected installment. '
            'A smaller amount records a partial EMI payment.',
            style: TextStyle(color: _muted, fontSize: 11.sp),
          ),
          SizedBox(height: 16.h),
          _label('Installment'),
          SizedBox(height: 7.h),
          Obx(() {
            if (controller.isLoadingInstallments.value) {
              return _choiceMessage('Loading installments...');
            }
            if (controller.installmentError.value.isNotEmpty) {
              return _choiceMessage(
                controller.installmentError.value,
                action: TextButton(
                  onPressed: controller.loadInstallments,
                  child: const Text('Retry'),
                ),
              );
            }
            if (controller.installments.isEmpty) {
              return _choiceMessage(
                'No unpaid installments are available for this loan.',
              );
            }
            return DropdownButtonFormField<String>(
              key: ValueKey(controller.selectedInstallmentUuid.value),
              initialValue: controller.selectedInstallmentUuid.value,
              isExpanded: true,
              decoration: _decoration(icon: Icons.event_note_outlined),
              hint: Text(
                'Choose an installment',
                style: TextStyle(color: _muted, fontSize: 14.sp),
              ),
              items: controller.installments
                  .map(
                    (installment) => DropdownMenuItem<String>(
                      value: controller.installmentUuid(installment),
                      child: Text(
                        controller.installmentLabel(installment),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _dark, fontSize: 14.sp),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (uuid) =>
                  controller.selectedInstallmentUuid.value = uuid,
            );
          }),
          SizedBox(height: 16.h),
          _label('Payment date'),
          SizedBox(height: 7.h),
          Obx(
            () => InkWell(
              onTap: () => controller.selectPaymentDate(context),
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
                  controller.formatDate(controller.paymentDate.value),
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
              return _choiceMessage('Loading source accounts...');
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
              decoration: _decoration(icon: Icons.account_balance_outlined),
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
          _label('Reference (optional)'),
          SizedBox(height: 7.h),
          TextField(
            controller: controller.referenceController,
            textCapitalization: TextCapitalization.characters,
            decoration: _decoration(
              hint: 'e.g. PM-EMI-PARTIAL',
              icon: Icons.tag_outlined,
            ),
          ),
          SizedBox(height: 16.h),
          _label('Description (optional)'),
          SizedBox(height: 7.h),
          TextField(
            controller: controller.descriptionController,
            maxLines: 3,
            maxLength: 250,
            decoration: _decoration(
              hint: 'Add a note about this payment',
              icon: Icons.notes_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: Obx(
          () => ElevatedButton.icon(
            onPressed: controller.isSubmitting.value
                ? null
                : () => _confirmPayment(context),
            icon: controller.isSubmitting.value
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              controller.isSubmitting.value
                  ? 'Recording payment...'
                  : 'Record payment',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13.r),
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

  Future<void> _confirmPayment(BuildContext context) async {
    final amount = double.tryParse(controller.amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      await controller.submitPayment();
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
    Map<String, dynamic>? installment;
    for (final item in controller.installments) {
      if (controller.installmentUuid(item) ==
          controller.selectedInstallmentUuid.value) {
        installment = item;
        break;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm EMI payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${amount.toStringAsFixed(2)}'),
            SizedBox(height: 6.h),
            Text(
              'Payment date: ${controller.formatDate(controller.paymentDate.value)}',
            ),
            if (accountName != null) ...[
              SizedBox(height: 6.h),
              Text('Source account: $accountName'),
            ],
            if (installment != null) ...[
              SizedBox(height: 6.h),
              Text('For: ${controller.installmentLabel(installment)}'),
            ],
            SizedBox(height: 10.h),
            const Text(
              'Confirm the amount and installment before recording this payment.',
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
            child: const Text('Confirm payment'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.submitPayment();
  }

  Widget _choiceMessage(String message, {Widget? action}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _muted, fontSize: 13.sp),
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
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _decoration({
    required IconData icon,
    String? hint,
    String? prefixText,
    Widget? suffix,
  }) => InputDecoration(
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: Icon(icon, color: _muted, size: 19.sp),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFFBFCFD),
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
    hintStyle: TextStyle(color: _muted, fontSize: 14.sp),
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
