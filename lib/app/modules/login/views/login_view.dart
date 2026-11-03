import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/widgets/home_widget.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  static const _primary = AppColors.primaryTeal;

  @override
  Widget build(BuildContext context) {
    // Keep the country code prefilled without overwriting a number the user entered.
    if (controller.phoneController.text.trim().isEmpty) {
      controller.phoneController.text = '+91';
      controller.phoneController.selection = TextSelection.collapsed(
        offset: controller.phoneController.text.length,
      );
    }

    return Scaffold(
      backgroundColor: HomeStyle.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 460.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 8.h, bottom: 26.h),
                    child: Column(
                      children: [
                        Container(
                          width: 62.w,
                          height: 62.w,
                          decoration: BoxDecoration(
                            color: HomeStyle.tealLight,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.primaryTeal,
                            size: 30.sp,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            color: HomeStyle.ink,
                            fontSize: 29.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Text(
                          'Sign in securely with a one-time code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            color: HomeStyle.muted,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: HomeStyle.border),
                      boxShadow: [
                        BoxShadow(
                          color: HomeStyle.ink.withOpacity(0.035),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Phone verification',
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            color: HomeStyle.ink,
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          'We’ll text a verification code to your number.',
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            color: HomeStyle.muted,
                            fontSize: 13.sp,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Obx(
                          () => TextField(
                            controller: controller.fullNameController,
                            readOnly: controller.isOtpSent.value,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            style: _fieldTextStyle,
                            decoration: _decoration(
                              label: 'Full name',
                              hint: 'Your name',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                        ),
                        SizedBox(height: 13.h),
                        Obx(
                          () => TextField(
                            controller: controller.phoneController,
                            readOnly: controller.isOtpSent.value,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            style: _fieldTextStyle,
                            decoration:
                                _decoration(
                                  label: 'Phone number',
                                  hint: '+91',
                                  icon: Icons.phone_outlined,
                                ).copyWith(
                                  helperText: 'Enter Country code Eg:+91',
                                  helperStyle: TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    color: HomeStyle.muted,
                                    fontSize: 11.sp,
                                  ),
                                ),
                          ),
                        ),
                        Obx(() {
                          if (!controller.isOtpSent.value) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: 13.h),
                            child: TextField(
                              controller: controller.otpController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: 6,
                              onSubmitted: (_) => controller.verifyPhoneOtp(),
                              style: _fieldTextStyle,
                              decoration: _decoration(
                                label: '6-digit verification code',
                                hint: 'Enter the code from your SMS',
                                icon: Icons.password_rounded,
                              ).copyWith(counterText: ''),
                            ),
                          );
                        }),
                        SizedBox(height: 18.h),
                        Obx(() {
                          final codeSent = controller.isOtpSent.value;
                          final busy =
                              controller.isSendingOtp.value ||
                              controller.isVerifyingOtp.value ||
                              controller.isLoading.value;
                          return SizedBox(
                            height: 50.h,
                            child: FilledButton(
                              onPressed: busy
                                  ? null
                                  : codeSent
                                  ? controller.verifyPhoneOtp
                                  : controller.sendPhoneOtp,
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                disabledBackgroundColor: AppColors.primaryTeal
                                    .withOpacity(0.45),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                              ),
                              child: busy
                                  ? SizedBox.square(
                                      dimension: 21.w,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      codeSent
                                          ? 'Verify code and sign in'
                                          : 'Send verification code',
                                      style: TextStyle(
                                        fontFamily: 'HankenGrotesk',
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          );
                        }),
                        Obx(() {
                          if (!controller.isOtpSent.value) {
                            return const SizedBox.shrink();
                          }
                          final busy =
                              controller.isSendingOtp.value ||
                              controller.isVerifyingOtp.value ||
                              controller.isLoading.value;
                          return Padding(
                            padding: EdgeInsets.only(top: 7.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : controller.sendPhoneOtp,
                                  child: Text(
                                    'Resend code',
                                    style: TextStyle(
                                      fontFamily: 'HankenGrotesk',
                                      color: AppColors.primaryTeal,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '·',
                                  style: TextStyle(color: HomeStyle.muted),
                                ),
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () {
                                          controller.isOtpSent.value = false;
                                          controller.otpController.clear();
                                        },
                                  child: Text(
                                    'Change number',
                                    style: TextStyle(
                                      fontFamily: 'HankenGrotesk',
                                      color: AppColors.primaryTeal,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Your phone number is verified securely by Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      color: HomeStyle.muted,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _fieldTextStyle => TextStyle(
    fontFamily: 'HankenGrotesk',
    color: HomeStyle.ink,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
  );

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: HomeStyle.muted, size: 20.sp),
      labelStyle: TextStyle(
        fontFamily: 'HankenGrotesk',
        color: HomeStyle.muted,
        fontSize: 13.sp,
      ),
      hintStyle: TextStyle(
        fontFamily: 'HankenGrotesk',
        color: HomeStyle.muted.withOpacity(0.65),
        fontSize: 13.sp,
      ),
      filled: true,
      fillColor: HomeStyle.background,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13.r),
        borderSide: BorderSide(color: HomeStyle.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13.r),
        borderSide: BorderSide(color: HomeStyle.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13.r),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
    );
  }
}
