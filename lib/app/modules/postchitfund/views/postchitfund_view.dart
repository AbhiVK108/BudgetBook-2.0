import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/postchitfund_controller.dart';

class PostchitfundView extends GetView<PostchitfundController> {
  const PostchitfundView({super.key});

  static const teal = Color(0xFF079B8D);
  static const ink = Color(0xFF263445);
  static const muted = Color(0xFF71808E);
  static const page = Color(0xFFF3F6F6);
  static const field = Color(0xFFF8FAFB);
  static const line = Color(0xFFE3E9EC);

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
                  padding: EdgeInsets.fromLTRB(11.w, 10.h, 11.w, 18.h),
                  child: Column(
                    children: [
                      _section(
                        icon: Icons.credit_card_outlined,
                        title: 'Card Identification',
                        subtitle: 'Basic card identity details',
                        children: [
                          _fieldLabel('Card Nickname / Display Name'),
                          _input(
                            controller.nameController,
                            'Sapphire Rewards • Primary',
                            Icons.edit_outlined,
                            capitalization: TextCapitalization.words,
                            validator: _required('Enter a card name'),
                          ),
                          _note(
                            'Friendly hint for notes and categorization only.',
                          ),
                          _fieldLabel('Bank / Card Issuer'),
                          _input(
                            controller.organizerNameController,
                            'HDFC Bank / Postman Issuer',
                            Icons.account_balance_outlined,
                            capitalization: TextCapitalization.words,
                            validator: _required('Enter the issuer'),
                          ),
                          _fieldLabel('Cardholder name', optional: true),
                          _input(
                            controller.memberReferenceController,
                            'ALEXANDER POSTMAN',
                            Icons.person_outline,
                            capitalization: TextCapitalization.words,
                          ),
                          _fieldLabel('Last 4 Digits', optional: true),
                          _input(
                            controller.groupReferenceController,
                            '1234',
                            Icons.more_horiz,
                            keyboardType: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          _note(
                            'Used solely to identify physical card and stored securely.',
                          ),
                        ],
                      ),
                      _section(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Credit Terms & Limit',
                        subtitle: 'Card commitment & currency limits',
                        children: [
                          _fieldLabel('Approved Credit Line'),
                          _input(
                            controller.chitValueController,
                            '1,50,000.00',
                            Icons.currency_rupee,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            formatters: [_amountFormatter],
                            validator: _positive('credit line'),
                          ),
                          _note(
                            'Total available credit limit assigned by the financial institution.',
                          ),
                          _fieldLabel('Ledger Currency'),
                          _readonly(
                            'INR (₹) • Regional Lock',
                            Icons.language_outlined,
                          ),
                        ],
                      ),
                      _section(
                        icon: Icons.calendar_month_outlined,
                        title: 'Billing Cycle & Due Dates',
                        subtitle: 'Statement generation & payment timelines',
                        children: [
                          _fieldLabel('Statement Generation Date'),
                          _dropdown(
                            controller.installmentCountController,
                            '15th of every month',
                            Icons.calendar_today_outlined,
                          ),
                          _fieldLabel('Payment Due Date'),
                          _dropdown(
                            controller.installmentAmountController,
                            '05th of next month (20 days grace)',
                            Icons.schedule_outlined,
                          ),
                        ],
                      ),
                      _section(
                        icon: Icons.notes_outlined,
                        title: 'Audit Notes & Purpose',
                        subtitle: 'Optional notes for the ledger',
                        children: [
                          _fieldLabel(
                            'Primary corporate expense & travel rewards card',
                          ),
                          TextFormField(
                            controller: controller.notesController,
                            maxLines: 2,
                            style: _textStyle(),
                            decoration: _decoration(
                              'Stored with ledger timestamp',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '47 / 180',
                              style: TextStyle(color: muted, fontSize: 9.sp),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: 38.h,
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.postChit,
                            icon: controller.isLoading.value
                                ? SizedBox(
                                    width: 15.w,
                                    height: 15.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(Icons.check_circle_outline, size: 15.sp),
                            label: Text(
                              controller.isLoading.value
                                  ? 'Saving...'
                                  : 'Save Credit Card',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: Get.back,
                        child: Text(
                          'Cancel & Discard',
                          style: TextStyle(color: muted, fontSize: 10.sp),
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

  Widget _appBar() => Container(
    height: 36.h,
    padding: EdgeInsets.symmetric(horizontal: 8.w),
    decoration: BoxDecoration(
      color: teal,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.r)),
    ),
    child: Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 16.sp),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Text(
            'Add Credit Card',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Icon(Icons.more_vert, color: Colors.white, size: 15.sp),
      ],
    ),
  );

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) => Container(
    width: double.infinity,
    margin: EdgeInsets.only(bottom: 7.h),
    padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 7.h),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 17.w,
              height: 17.w,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Icon(icon, color: const Color(0xFF3979D4), size: 11.sp),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ink,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: muted, fontSize: 7.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ...children.map(
          (child) => Padding(
            padding: EdgeInsets.only(bottom: 5.h),
            child: child,
          ),
        ),
      ],
    ),
  );

  Widget _fieldLabel(String text, {bool optional = false}) => Padding(
    padding: EdgeInsets.only(bottom: 2.h),
    child: Text(
      '$text${optional ? ' (Optional)' : ''}',
      style: TextStyle(
        color: ink,
        fontSize: 7.5.sp,
        fontWeight: FontWeight.w600,
      ),
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
  }) => TextFormField(
    controller: c,
    validator: validator,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    inputFormatters: formatters,
    style: _textStyle(),
    decoration: _decoration(hint, icon),
  );

  Widget _readonly(String value, IconData icon) => InputDecorator(
    decoration: _decoration(value, icon),
    child: Text(value, style: _textStyle()),
  );

  Widget _dropdown(TextEditingController c, String value, IconData icon) =>
      DropdownButtonFormField<String>(
        initialValue: c.text.isEmpty ? null : c.text,
        isExpanded: true,
        items: [DropdownMenuItem(value: value, child: Text(value))],
        onChanged: (v) => c.text = v ?? value,
        style: _textStyle(),
        decoration: _decoration(value, icon),
      );

  InputDecoration _decoration(String hint, [IconData? icon]) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: muted, fontSize: 7.5.sp),
    prefixIcon: icon == null ? null : Icon(icon, color: muted, size: 11.sp),
    prefixIconConstraints: BoxConstraints(minWidth: 25.w),
    isDense: true,
    filled: true,
    fillColor: field,
    contentPadding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5.r),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5.r),
      borderSide: const BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5.r),
      borderSide: const BorderSide(color: teal),
    ),
  );

  Widget _note(String text) => Padding(
    padding: EdgeInsets.only(left: 2.w, bottom: 2.h),
    child: Text(
      text,
      style: TextStyle(color: muted, fontSize: 6.5.sp),
    ),
  );
  TextStyle _textStyle() =>
      TextStyle(color: ink, fontSize: 8.sp, fontWeight: FontWeight.w500);
  String? Function(String?) _required(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;
  String? Function(String?) _positive(String label) =>
      (value) =>
          (double.tryParse(value?.replaceAll(',', '').trim() ?? '') ?? 0) <= 0
          ? 'Enter a valid $label'
          : null;
  static final _amountFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9,.]'),
  );
}
