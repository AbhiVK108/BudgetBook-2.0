import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/postchitfund_controller.dart';

class PostchitfundView extends GetView<PostchitfundController> {
  const PostchitfundView({super.key});

  static const Color primary = Color(0xFF009688);
  static const Color background = Color(0xFFF4F6F6);
  static const Color dark = Color(0xFF374151);
  static const Color muted = Color(0xFF718096);
  static const Color fieldBackground = Color(0xFFF8FAFC);
  static const Color fieldBorder = Color(0xFFDFE6EC);
  static const String fontFamily = 'HankenGrotesk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 78.h,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'Chitfund',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 25.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'reset') {
                _resetForm();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'reset', child: Text('Reset form')),
            ],
          ),
          SizedBox(width: 8.w),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18.r)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 24.h),
            child: Column(
              children: [
                // CARD 1: CHIT NAME AND AMOUNT
                _formCard(
                  children: [
                    _label('Chit Fund Name'),
                    _inputField(
                      controller: controller.chitNameController,
                      hint: 'Chit Fund Name',
                      icon: Icons.person_outline,
                      helper: 'Enter the name of the Chit',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the chit fund name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 22.h),
                    _label('Amount'),
                    _inputField(
                      controller: controller.amountController,
                      hint: '0.00',
                      icon: Icons.currency_rupee,
                      helper: 'Enter the total chit amount',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                SizedBox(height: 22.h),

                // CARD 2: MEMBERS AND DURATION
                _formCard(
                  children: [
                    _label('Members'),
                    _inputField(
                      controller: controller.membersController,
                      hint: 'Members',
                      icon: Icons.groups_outlined,
                      helper: 'Total no of members involved',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        final members = int.tryParse(value?.trim() ?? '');
                        if (members == null || members <= 0) {
                          return 'Enter the number of members';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 22.h),
                    _label('Duration(Months)'),
                    _inputField(
                      controller: controller.durationController,
                      hint: '12',
                      icon: Icons.calendar_month_outlined,
                      helper: 'Enter the no of months for the chit',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        final months = int.tryParse(value?.trim() ?? '');
                        if (months == null || months <= 0) {
                          return 'Enter the duration in months';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                SizedBox(height: 22.h),

                // CARD 3: START AND END DATES
                _formCard(
                  children: [
                    _label('Start Date'),
                    _dateField(
                      controller: controller.startDateController,
                      hint: 'mm/dd/yyyy',
                      helper: 'Start Date Of the Chit',
                      onTap: () =>
                          _pickDate(context, controller.startDateController),
                    ),
                    SizedBox(height: 22.h),
                    _label('End Date'),
                    _dateField(
                      controller: controller.endDateController,
                      hint: 'mm/dd/yyyy',
                      helper: 'End Date of the chit',
                      onTap: () =>
                          _pickDate(context, controller.endDateController),
                    ),
                  ],
                ),

                SizedBox(height: 22.h),

                // CARD 4: BEFORE LIFT AND AFTER LIFT
                _formCard(
                  children: [
                    _label('Before Lift'),
                    _dateField(
                      controller: controller.beforeLiftController,
                      hint: 'mm/dd/yyyy',
                      helper: 'Monthly Contribution Before Lift',
                      onTap: () =>
                          _pickDate(context, controller.beforeLiftController),
                    ),
                    SizedBox(height: 22.h),
                    _label('After Lift'),
                    _dateField(
                      controller: controller.afterLiftController,
                      hint: 'mm/dd/yyyy',
                      helper: 'Monthly Contribution after Lift',
                      onTap: () =>
                          _pickDate(context, controller.afterLiftController),
                    ),
                  ],
                ),

                SizedBox(height: 30.h),

                // SAVE BUTTON
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 62.h,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              if (controller.formKey.currentState!.validate()) {
                                controller.saveChitFund();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primary.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined, size: 25.sp),
                                SizedBox(width: 10.w),
                                Text(
                                  'Save',
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 21.sp,
                                    fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _formCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: const Color(0xFFC8F0EB), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.12),
            blurRadius: 0,
            offset: Offset(0, 5.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          color: dark,
          fontFamily: fontFamily,
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String helper,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: TextStyle(
            color: dark,
            fontFamily: fontFamily,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: muted,
              fontFamily: fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: hint == '0.00' ? primary : muted,
              size: 24.sp,
            ),
            filled: true,
            fillColor: fieldBackground,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 19.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19.r),
              borderSide: const BorderSide(color: fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19.r),
              borderSide: const BorderSide(color: fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19.r),
              borderSide: const BorderSide(color: primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19.r),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        SizedBox(height: 9.h),
        _helperText(helper),
      ],
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String hint,
    required String helper,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19.r),
          child: IgnorePointer(
            child: TextFormField(
              controller: controller,
              readOnly: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select a date';
                }
                return null;
              },
              style: TextStyle(
                color: dark,
                fontFamily: fontFamily,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: dark,
                  fontFamily: fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
                suffixIcon: Icon(
                  Icons.calendar_month_outlined,
                  color: primary,
                  size: 25.sp,
                ),
                filled: true,
                fillColor: fieldBackground,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 17.w,
                  vertical: 19.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(19.r),
                  borderSide: const BorderSide(color: fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(19.r),
                  borderSide: const BorderSide(color: fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(19.r),
                  borderSide: const BorderSide(color: primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 9.h),
        _helperText(helper),
      ],
    );
  }

  Widget _helperText(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 7.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(Icons.info_outline, size: 15.sp, color: muted),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: muted,
                fontFamily: fontFamily,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController dateController,
  ) async {
    final now = DateTime.now();
    final initialDate = DateTime.tryParse(dateController.text) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              onSurface: dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dateController.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _resetForm() {
    controller.chitNameController.clear();
    controller.amountController.clear();
    controller.membersController.clear();
    controller.durationController.text = '12';
    controller.startDateController.clear();
    controller.endDateController.clear();
    controller.beforeLiftController.clear();
    controller.afterLiftController.clear();
    controller.formKey.currentState?.reset();
  }
}
