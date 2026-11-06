import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/lending_repayment_controller.dart';

class LendingRepaymentView extends GetView<LendingRepaymentController> {
  const LendingRepaymentView({super.key});

  static const Color _primary = Color(0xFF0F8F7F);
  static const Color _primaryDark = Color(0xFF087568);
  static const Color _dark = Color(0xFF172B3A);
  static const Color _label = Color(0xFF647582);
  static const Color _muted = Color(0xFF87949F);
  static const Color _border = Color(0xFFE8EEEE);
  static const Color _background = Color(0xFFF4F7F8);
  static const String _fontFamily = 'HankenGrotesk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _loanSummary(),
                    SizedBox(height: 14.h),
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
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp, color: _dark),
      ),
      titleSpacing: 4.w,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LENDING',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: _primary,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Record repayment',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 19.sp,
              fontWeight: FontWeight.w800,
              color: _dark,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOAN SUMMARY
  // ---------------------------------------------------------------------------

  Widget _loanSummary() {
    final outstanding = double.tryParse(controller.outstandingAmount) ?? 0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryDark, _primary],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32.w,
            top: -42.h,
            child: Container(
              width: 125.w,
              height: 125.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 20,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 19.sp,
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REPAYMENT FOR',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            fontFamily: _fontFamily,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          controller.borrowerName.isEmpty
                              ? 'Unknown person'
                              : controller.borrowerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: _fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 19.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 13.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.13),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 18.sp,
                    ),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: Text(
                        'Outstanding balance',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: _fontFamily,
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
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: _fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORM
  // ---------------------------------------------------------------------------

  Widget _formCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173C45).withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Repayment details',
            icon: Icons.receipt_long_outlined,
          ),
          SizedBox(height: 20.h),

          // AMOUNT
          _fieldLabel(
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
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              fontFamily: _fontFamily,
            ),
            decoration: _decoration(
              hint: '0.00',
              prefixText: '${controller.currency} ',
              icon: Icons.currency_rupee_rounded,
            ),
          ),

          SizedBox(height: 18.h),

          // REPAYMENT DATE
          _fieldLabel('Repayment date'),
          SizedBox(height: 7.h),
          Obx(
            () => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.selectRepaymentDate(context),
                borderRadius: BorderRadius.circular(12.r),
                child: InputDecorator(
                  decoration: _decoration(
                    icon: Icons.calendar_month_outlined,
                    suffix: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _muted,
                      size: 21.sp,
                    ),
                  ),
                  child: Text(
                    controller.formatDate(controller.repaymentDate.value),
                    style: TextStyle(
                      color: _dark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: _fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 18.h),

          // ACCOUNT
          _fieldLabel(
            controller.isBorrowing ? 'Source account' : 'Receiving account',
          ),
          SizedBox(height: 7.h),

          Obx(() {
            if (controller.isLoadingAccounts.value) {
              return _accountMessage(
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: _primary,
                    strokeWidth: 2,
                  ),
                ),
                'Loading accounts...',
              );
            }

            if (controller.accountError.value.isNotEmpty) {
              return _accountMessage(
                Icon(
                  Icons.error_outline_rounded,
                  color: const Color(0xFFD45B55),
                  size: 19.sp,
                ),
                controller.accountError.value,
                action: TextButton(
                  onPressed: controller.loadAccounts,
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(40.w, 34.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: _fontFamily,
                    ),
                  ),
                ),
              );
            }

            if (controller.accounts.isEmpty) {
              return _accountMessage(
                Icon(
                  Icons.account_balance_outlined,
                  color: _muted,
                  size: 19.sp,
                ),
                'No active accounts are available.',
                action: TextButton(
                  onPressed: controller.loadAccounts,
                  child: Text(
                    'Refresh',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: _fontFamily,
                    ),
                  ),
                ),
              );
            }

            final accountIds = controller.accounts
                .map((account) => controller.accountUuid(account))
                .toSet();

            final selectedValue =
                accountIds.contains(controller.selectedAccountUuid.value)
                ? controller.selectedAccountUuid.value
                : null;

            return DropdownButtonFormField<String>(
              initialValue: selectedValue,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _muted,
                size: 21.sp,
              ),
              decoration: _decoration(icon: Icons.account_balance_outlined),
              hint: Text(
                controller.isBorrowing
                    ? 'Choose a source account'
                    : 'Choose an account',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: _fontFamily,
                ),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              items: controller.accounts.map((account) {
                final uuid = controller.accountUuid(account);

                return DropdownMenuItem<String>(
                  value: uuid,
                  child: Text(
                    controller.accountLabel(account),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _dark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (uuid) {
                controller.selectedAccountUuid.value = uuid;
              },
            );
          }),

          SizedBox(height: 18.h),

          // REFERENCE
          _fieldLabel('Reference'),
          SizedBox(height: 7.h),
          TextField(
            controller: controller.referenceController,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(
              color: _dark,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
            ),
            decoration: _decoration(
              hint: 'e.g. PAYMENT-REFERENCE',
              icon: Icons.tag_rounded,
            ),
          ),

          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13.sp, color: _muted),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  'Optional transaction reference',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: _fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACCOUNT MESSAGE
  // ---------------------------------------------------------------------------

  Widget _accountMessage(Widget icon, String message, {Widget? action}) {
    return Container(
      constraints: BoxConstraints(minHeight: 50.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          SizedBox(width: 20.w, height: 20.w, child: icon),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _label,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                fontFamily: _fontFamily,
              ),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMMON WIDGETS
  // ---------------------------------------------------------------------------

  Widget _sectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6F3),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: _primary, size: 17.sp),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _dark,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              fontFamily: _fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  // Renamed to avoid conflict with the static _label color.
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _dark,
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        fontFamily: _fontFamily,
      ),
    );
  }

  InputDecoration _decoration({
    String? hint,
    String? prefixText,
    Widget? suffix,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _muted,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        fontFamily: _fontFamily,
      ),
      prefixIcon: icon == null ? null : Icon(icon, color: _muted, size: 18.sp),
      prefixIconConstraints: BoxConstraints(minWidth: 43.w, minHeight: 46.h),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: _label,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        fontFamily: _fontFamily,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F9FA),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: _primary, width: 1.2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMIT BUTTON
  // ---------------------------------------------------------------------------

  Widget _submitButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 13.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border.withValues(alpha: 0.8))),
      ),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: 49.h,
          child: ElevatedButton.icon(
            onPressed: controller.isSubmitting.value
                ? null
                : () async {
                    await controller.submitRepayment();
                  },
            icon: controller.isSubmitting.value
                ? SizedBox(
                    width: 17.w,
                    height: 17.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.check_circle_outline_rounded, size: 19.sp),
            label: Text(
              controller.isSubmitting.value
                  ? 'Recording...'
                  : 'Record repayment',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                fontFamily: _fontFamily,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withValues(alpha: 0.65),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
