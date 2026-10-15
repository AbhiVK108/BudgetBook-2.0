
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/reminders_controller.dart';

class RemindersView extends GetView<RemindersController> {
  const RemindersView({super.key});

  static const Color primaryColor = Color(0xFF079B8D);
  static const Color scaffoldColor = Color(0xFFF6F6F6);
  static const Color labelColor = Color(0xFF4F4F4F);
  static const String fontFamily = 'HankenGrotesk';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: scaffoldColor,
        appBar: _buildAppBar(),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: 26.w,
              vertical: 20.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction date label
                Text(
                  'Transaction Date',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),

                SizedBox(height: 5.h),

                // Date picker field
                Obx(() => _buildDateField(context)),

                SizedBox(height: 10.h),

                // Description label
                Text(
                  'Description',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),

                SizedBox(height: 5.h),

                // Description input
                _buildDescriptionField(),

                SizedBox(height: 27.h),

                // Save button with loading indicator
                _buildSaveButton(),

                SizedBox(height: 11.h),

                // Bottom helper text
                Center(
                  child: Text(
                    'Entry will be reflected in your monthly\nwealth report.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11.sp,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF909090),
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

  // ================= APP BAR =================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: primaryColor,
      surfaceTintColor: primaryColor,
      toolbarHeight: 66.h,
      leadingWidth: 54.w,
      leading: IconButton(
        onPressed: Get.back,
        splashRadius: 21.r,
        icon: Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 21.sp,
        ),
      ),
      titleSpacing: 0,
      title: Text(
        'Reminder',
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: controller.onMenuPressed,
          splashRadius: 21.r,
          icon: Icon(
            Icons.more_vert,
            color: Colors.white,
            size: 23.sp,
          ),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }

  // ================= DATE FIELD =================

  Widget _buildDateField(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.selectDate(context),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: double.infinity,
          height: 43.h,
          padding: EdgeInsets.symmetric(horizontal: 13.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.20),
                offset: Offset(0, 2.h),
                blurRadius: 1.5.r,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 17.sp,
                color: const Color(0xFF71817F),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  controller.formattedSelectedDate,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF494949),
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20.sp,
                color: const Color(0xFF71817F),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DESCRIPTION FIELD =================

  Widget _buildDescriptionField() {
    return Container(
      width: double.infinity,
      height: 105.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.20),
            offset: Offset(0, 2.h),
            blurRadius: 1.5.r,
          ),
        ],
      ),
      child: TextField(
        controller: controller.descriptionController,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        maxLines: null,
        expands: true,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF424242),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 13.w,
            vertical: 13.h,
          ),
          hintText: 'Add a note (e.g. Q3 Bonus)',
          hintStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFB1B1B1),
          ),
        ),
      ),
    );
  }

  // ================= SAVE BUTTON =================

  Widget _buildSaveButton() {
    return Obx(
      () {
        final loading = controller.isLoading.value;

        return SizedBox(
          width: double.infinity,
          height: 47.h,
          child: ElevatedButton(
            onPressed: loading ? null : controller.saveEntry,
            style: ElevatedButton.styleFrom(
              elevation: 1,
              shadowColor: primaryColor.withValues(alpha: 0.25),
              backgroundColor: primaryColor,
              disabledBackgroundColor:
                  primaryColor.withValues(alpha: 0.6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: loading
                ? SizedBox(
                    height: 21.h,
                    width: 21.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Save Entry',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

