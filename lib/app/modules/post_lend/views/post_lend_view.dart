
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/post_lend_controller.dart';

class PostLendView extends GetView<PostLendController> {
  const PostLendView({super.key});

  static const Color primary = Color(0xFF079B8D);
  static const Color dark = Color(0xFF374151);
  static const Color hint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFDCE4EC);
  static const Color background = Color(0xFFF5F6F6);
  static const Color fieldBackground = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18.r),
                  bottomRight: Radius.circular(18.r),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 27.sp,
                    ),
                  ),
                  SizedBox(width: 25.w),
                  Obx(
                    () => Text(
                      controller.isEditMode.value ? 'Update Lending' : 'Lending',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 27.sp,
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Person details
                    _section(
                      children: [
                        _label('Person'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.personController,
                          hint: 'Person name',
                          icon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                        ),
                        _helper('Enter the name of the person'),
                        SizedBox(height: 18.h),

                        _label('Mobile Number'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.phoneController,
                          hint: '98765 43210',
                          icon: Icons.phone_outlined,
                          prefixText: '+91  ',
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                        ),
                        _helper('Enter a 10-digit mobile number'),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // Amount and interest
                    _section(
                      children: [
                        _label('Amount'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.amountController,
                          hint: '0.00',
                          icon: Icons.currency_rupee,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        _helper('Enter the amount'),
                        SizedBox(height: 22.h),

                        Row(
                          children: [
                            Expanded(
                              child: _label('Rate of Interest'),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFFFFB),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: const Color(0xFFC8F5EC),
                                ),
                              ),
                              child: Text(
                                'Interest in ₹ / month',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        _input(
                          controller: controller.interestController,
                          hint: '0',
                          icon: Icons.currency_rupee,
                          suffixText: '/ 100 ₹',
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        _helper(
                          'Enter interest in Rupees (₹)',
                          trailing: 'Per month standard',
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // Receive date and return date
                    _section(
                      children: [
                        _label('Give Date'),
                        SizedBox(height: 8.h),
                        Obx(
                          () => _dateField(
                            date: controller.giveDate.value,
                            onTap: () =>
                                controller.selectGiveDate(context),
                          ),
                        ),
                        _helper('Select the date you gave the amount'),
                        SizedBox(height: 20.h),

                        _label('Return Date'),
                        SizedBox(height: 8.h),
                        Obx(
                          () => _dateField(
                            date: controller.returnDate.value,
                            onTap: () =>
                                controller.selectReturnDate(context),
                          ),
                        ),
                        _helper('Expected repayment date'),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // Description and receipt
                    _section(
                      children: [
                        _label('Description'),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: controller.descriptionController,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _decoration(
                            hint:
                                'Mention the reason or loan agreement terms...',
                          ),
                        ),
                        _helper('Purpose of borrowing'),
                        SizedBox(height: 24.h),

                        Row(
                          children: [
                            Expanded(
                              child: _label('Upload Receipt (optional)'),
                            ),
                            Text(
                              'PNG, JPG or PDF',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: hint,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Receipt placeholder.
                        // File selection and upload are not connected yet.
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 24.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFDFE),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(15.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: border),
                                ),
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  size: 36.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'Tap to attach receipt or photo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: dark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'PNG, JPG or PDF files',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: hint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Save button
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 58.h,
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.postLend,
                          icon: controller.isLoading.value
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            controller.isLoading.value
                                ? (controller.isEditMode.value
                                    ? 'Updating...'
                                    : 'Saving...')
                                : (controller.isEditMode.value
                                    ? 'Update'
                                    : 'Save'),
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                primary.withValues(alpha: 0.6),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.r),
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

  // Section card
  Widget _section({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFC9F1EA)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.12),
            offset: Offset(0, 5.h),
            blurRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Field label
  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        color: dark,
        fontWeight: FontWeight.w600,
        fontFamily: 'HankenGrotesk',
      ),
    );
  }

  // Text input
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
      decoration: _decoration(
        hint: hint,
        icon: icon,
        prefixText: prefixText,
        suffixText: suffixText,
      ).copyWith(counterText: ''),
    );
  }

  // Shared input decoration
  InputDecoration _decoration({
    required String hint,
    IconData? icon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 14.sp,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: hint == '0.00' ? primary : hintColor,
              size: 21.sp,
            ),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: dark,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
      ),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: hintColor,
        fontSize: 12.sp,
      ),
      filled: true,
      fillColor: fieldBackground,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 17.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(
          color: primary,
          width: 1.4,
        ),
      ),
    );
  }

  static const Color hintColor = Color(0xFF94A3B8);

  // Helper text
  Widget _helper(String text, {String? trailing}) {
    return Padding(
      padding: EdgeInsets.only(left: 5.w, top: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 13.sp,
            color: hintColor,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 11.sp,
              ),
            ),
          ),
          if (trailing != null)
            Flexible(
              child: Text(
                trailing,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: hintColor,
                  fontSize: 10.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Date picker field
  Widget _dateField({
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final String displayDate = date == null
        ? 'mm/dd/yyyy'
        : '${date.month.toString().padLeft(2, '0')}/'
            '${date.day.toString().padLeft(2, '0')}/'
            '${date.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: InputDecorator(
        decoration: _decoration(hint: '').copyWith(
          suffixIcon: Icon(
            Icons.calendar_month_outlined,
            color: primary,
            size: 22.sp,
          ),
        ),
        child: Text(
          displayDate,
          style: TextStyle(
            color: date == null ? hint : dark,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
