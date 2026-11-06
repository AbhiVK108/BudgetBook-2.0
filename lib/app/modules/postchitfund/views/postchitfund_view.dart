import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/postchitfund_controller.dart';

class PostchitfundView extends GetView<PostchitfundController> {
  const PostchitfundView({super.key});

  static const Color teal = Color(0xFF079B8D);
  static const Color tealDark = Color(0xFF08796F);
  static const Color ink = Color(0xFF263445);
  static const Color muted = Color(0xFF71808E);
  static const Color page = Color(0xFFF3F6F6);
  static const Color field = Color(0xFFF7F9FB);
  static const Color line = Color(0xFFE2EAF0);
  static const Color mintBorder = Color(0xFFBCEBE4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),
            Expanded(
              child: Form(
                key: controller.formKey,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _section(
                        icon: Icons.credit_card_outlined,
                        title: 'CHIT DETAILS',
                        children: [
                          _fieldLabel('Name'),
                          SizedBox(height: 8.h),
                          _input(
                            controller.nameController,
                            'e.g. Monthly chit fund',
                            Icons.edit_note_outlined,
                            capitalization: TextCapitalization.words,
                            validator: _required('Enter a chit name'),
                          ),
                          SizedBox(height: 14.h),
                          _fieldLabel('Organizer name'),
                          SizedBox(height: 8.h),
                          _input(
                            controller.organizerNameController,
                            'Enter organizer name',
                            Icons.account_balance_outlined,
                            capitalization: TextCapitalization.words,
                            validator: _required('Enter the organizer name'),
                          ),
                          SizedBox(height: 14.h),
                          _fieldLabel('Group reference', optional: true),
                          SizedBox(height: 8.h),
                          _input(
                            controller.groupReferenceController,
                            'e.g. PM-GROUP-1',
                            Icons.groups_outlined,
                            capitalization: TextCapitalization.characters,
                          ),
                          SizedBox(height: 14.h),
                          _fieldLabel('Member reference', optional: true),
                          SizedBox(height: 8.h),
                          _input(
                            controller.memberReferenceController,
                            'e.g. PM-TICKET-1',
                            Icons.confirmation_number_outlined,
                            capitalization: TextCapitalization.characters,
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _section(
                        icon: Icons.payments_outlined,
                        title: 'CHIT AMOUNTS',
                        children: [
                          _fieldLabel('Chit value'),
                          SizedBox(height: 8.h),
                          _input(
                            controller.chitValueController,
                            '0.00',
                            Icons.currency_rupee,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            formatters: [_amountFormatter],
                            validator: _positive('chit value'),
                          ),
                          _helper(
                            'Total available credit limit assigned by the financial institution.',
                          ),
                          SizedBox(height: 14.h),
                          _fieldLabel('Installment amount'),
                          SizedBox(height: 8.h),
                          _input(
                            controller.installmentAmountController,
                            '0.00',
                            Icons.currency_rupee,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            formatters: [_amountFormatter],
                            validator: _positive('installment amount'),
                          ),
                          SizedBox(height: 14.h),
                          _fieldLabel('Installment count'),
                          SizedBox(height: 8.h),
                          _input(
                            controller.installmentCountController,
                            'e.g. 12',
                            Icons.format_list_numbered_outlined,
                            keyboardType: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: _positiveInteger(
                              'Enter a valid installment count',
                            ),
                          ),
                          SizedBox(height: 14.h),
                          _fieldLabel('Currency'),
                          SizedBox(height: 8.h),
                          _readonly('INR', Icons.language_outlined),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _section(
                        icon: Icons.event_available_outlined,
                        title: 'DATES & CONTRIBUTION ACCOUNT',
                        children: [
                          _fieldLabel('Start date'),
                          SizedBox(height: 8.h),
                          Obx(
                            () => _dateButton(
                              controller.startDate.value,
                              () => controller.selectStartDate(context),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          _fieldLabel('First due date'),
                          SizedBox(height: 8.h),
                          Obx(
                            () => _dateButton(
                              controller.firstDueDate.value,
                              () => controller.selectFirstDueDate(context),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          _fieldLabel('Contribution account'),
                          SizedBox(height: 8.h),
                          Obx(() => _accountSelector()),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _section(
                        icon: Icons.tune_outlined,
                        title: 'STATUS, TYPE & NOTES',
                        children: [
                          // _fieldLabel('Status'),
                          // SizedBox(height: 8.h),
                          // _readonly('Active', Icons.check_circle_outline),
                          SizedBox(height: 14.h),
                          _fieldLabel('Chit type'),
                          SizedBox(height: 8.h),
                          Obx(() => _chitTypeDropdown()),
                          SizedBox(height: 14.h),
                          _fieldLabel('Notes', optional: true),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: controller.notesController,
                            minLines: 3,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            style: _textStyle(),
                            decoration: _decoration(
                              'Add any details about this chit...',
                              icon: Icons.notes_outlined,
                              alignLabelWithHint: true,
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
                                : controller.postChit,
                            icon: controller.isLoading.value
                                ? SizedBox(
                                    width: 19.w,
                                    height: 19.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(Icons.save_outlined, size: 20.sp),
                            label: Text(
                              controller.isLoading.value
                                  ? 'Saving chit...'
                                  : 'Create chit fund',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: teal.withValues(
                                alpha: 0.65,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextButton(
                        onPressed: Get.back,
                        child: Text(
                          'Cancel & Discard',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'HankenGrotesk',
                          ),
                        ),
                      ),
                    ],
                  ),
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
        color: teal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10.r),
          bottomRight: Radius.circular(10.r),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              'Add Chit Fund',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
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
            color: teal.withValues(alpha: 0.08),
            offset: Offset(0, 2.h),
            blurRadius: 8.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6F3),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(icon, color: tealDark, size: 19.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: tealDark,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                    fontFamily: 'HankenGrotesk',
                  ),
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

  Widget _fieldLabel(String text, {bool optional = false}) => Text(
    optional ? '$text (Optional)' : text,
    style: TextStyle(
      color: ink,
      fontSize: 13.sp,
      fontWeight: FontWeight.w700,
      fontFamily: 'HankenGrotesk',
    ),
  );

  Widget _input(
    TextEditingController c,
    String hint,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      inputFormatters: formatters,
      style: _textStyle(),
      decoration: _decoration(hint, icon: icon),
    );
  }

  Widget _readonly(String value, IconData icon) {
    return InputDecorator(
      decoration: _decoration('', icon: icon),
      child: Text(value, style: _textStyle()),
    );
  }

  Widget _dateButton(DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9.r),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: field,
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: muted, size: 19.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                date == null ? 'Select date' : controller.formatDate(date),
                style: TextStyle(
                  color: date == null ? muted : ink,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: muted, size: 22.sp),
          ],
        ),
      ),
    );
  }

  Widget _accountSelector() {
    if (controller.isLoadingAccounts.value) {
      return _loadingSelector();
    }
    if (controller.accountLoadError.value.isNotEmpty) {
      return _retrySelector(
        controller.accountLoadError.value,
        controller.loadContributionAccounts,
      );
    }
    if (controller.accounts.isEmpty) {
      return _emptyAccountSelector();
    }

    final selectedUuid = controller.selectedContributionAccountUuid.value;
    final selectedValue =
        controller.accounts.any(
          (account) => controller.accountUuid(account) == selectedUuid,
        )
        ? selectedUuid
        : controller.accountUuid(controller.accounts.first);

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      style: _textStyle(),
      decoration: _decoration(
        'Select contribution account',
        icon: Icons.account_balance_wallet_outlined,
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: muted, size: 22.sp),
      items: controller.accounts.map((account) {
        return DropdownMenuItem<String>(
          value: controller.accountUuid(account),
          child: Text(
            controller.accountName(account),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(),
          ),
        );
      }).toList(),
      onChanged: (value) {
        controller.selectedContributionAccountUuid.value = value;
      },
    );
  }

  Widget _emptyAccountSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: field,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'No active accounts available. Add an account to continue.',
              style: TextStyle(
                color: muted,
                fontSize: 12.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Get.toNamed(Routes.bankAccounts);
              await controller.loadContributionAccounts();
            },
            child: Text(
              'Add account',
              style: TextStyle(
                color: teal,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chitTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: controller.chitType.value,
      isExpanded: true,
      style: _textStyle(),
      decoration: _decoration(
        'Select chit type',
        icon: Icons.category_outlined,
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: muted, size: 22.sp),
      items: const [
        DropdownMenuItem(value: 'auction', child: Text('Auction')),
        DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
      ],
      onChanged: (value) {
        if (value != null) controller.chitType.value = value;
      },
    );
  }

  Widget _loadingSelector() {
    return Container(
      height: 48.h,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: field,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: SizedBox(
        width: 18.w,
        height: 18.w,
        child: const CircularProgressIndicator(strokeWidth: 2, color: teal),
      ),
    );
  }

  Widget _retrySelector(String message, VoidCallback onRetry) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: field,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: muted,
                fontSize: 12.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                color: teal,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(
    String hint, {
    IconData? icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      hintStyle: TextStyle(
        color: muted,
        fontSize: 13.sp,
        fontFamily: 'HankenGrotesk',
      ),
      prefixIcon: icon == null ? null : Icon(icon, color: muted, size: 19.sp),
      prefixIconConstraints: icon == null
          ? null
          : BoxConstraints(minWidth: 42.w, minHeight: 48.h),
      alignLabelWithHint: alignLabelWithHint,
      isDense: true,
      filled: true,
      fillColor: field,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: const BorderSide(color: teal, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: const BorderSide(color: Color(0xFFD95C5C)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: const BorderSide(color: Color(0xFFD95C5C), width: 1.2),
      ),
    );
  }

  Widget _helper(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w, top: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14.sp, color: muted),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: muted,
                fontSize: 11.sp,
                height: 1.25,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _textStyle() => TextStyle(
    color: ink,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    fontFamily: 'HankenGrotesk',
  );

  String? Function(String?) _required(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  String? Function(String?) _positive(String label) => (value) {
    final amount = double.tryParse(value?.replaceAll(',', '').trim() ?? '');
    return amount == null || amount <= 0 ? 'Enter a valid $label' : null;
  };

  String? Function(String?) _positiveInteger(String message) => (value) {
    final count = int.tryParse(value?.trim() ?? '');
    return count == null || count <= 0 ? message : null;
  };

  static final _amountFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9,.]'),
  );
}
