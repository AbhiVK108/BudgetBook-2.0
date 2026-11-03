import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBgWhite,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.scaffoldGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.profile.value == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryTeal,
                      ),
                    );
                  }

                  if (controller.errorMessage.value.isNotEmpty &&
                      controller.profile.value == null) {
                    return _buildError();
                  }

                  final profile = controller.profile.value;

                  if (profile == null) {
                    return _buildError();
                  }

                  return RefreshIndicator(
                    color: AppColors.primaryTeal,
                    onRefresh: controller.fetchProfile,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
                      children: [
                        if (controller.errorMessage.value.isNotEmpty) ...[
                          _buildInlineError(),
                          SizedBox(height: 14.h),
                        ],

                        _buildIdentityCard(profile),
                        SizedBox(height: 24.h),

                        _sectionHeading(
                          title: 'Account details',
                          subtitle: 'Your personal information',
                          icon: Icons.person_outline_rounded,
                        ),
                        SizedBox(height: 12.h),

                        _buildDetailsCard(profile),
                        SizedBox(height: 22.h),

                        _sectionHeading(
                          title: 'Verification',
                          subtitle: 'Your account security status',
                          icon: Icons.verified_user_outlined,
                        ),
                        SizedBox(height: 12.h),

                        _buildVerificationCard(profile),
                        SizedBox(height: 24.h),

                        _buildFooter(),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // HEADER
  // ======================================================

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      child: Row(
        children: [
          _headerButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Go back',
            onTap: () {
              if (Get.key.currentState?.canPop() ?? false) {
                Get.back();
              }
            },
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUDGETBOOK',
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontSize: 9.sp,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'My Profile',
                  style: TextStyle(
                    color: HomeStyle.ink,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'HankenGrotesk',
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => _headerButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh profile',
              onTap: controller.isLoading.value
                  ? null
                  : controller.fetchProfile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(13.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13.r),
          child: Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13.r),
              border: Border.all(color: HomeStyle.border),
            ),
            child: Icon(icon, color: HomeStyle.ink, size: 20.sp),
          ),
        ),
      ),
    );
  }

  // ======================================================
  // IDENTITY
  // ======================================================

  Widget _buildIdentityCard(ProfileData profile) {
    final name = _valueOrFallback(profile.fullName, 'User');
    final status = _valueOrFallback(profile.status, 'Unknown');
    final isActive = status.toLowerCase() == 'active';

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: HomeStyle.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(size: 70.r, imageUrl: profile.profileImage),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: HomeStyle.ink,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'HankenGrotesk',
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      _valueOrFallback(
                        profile.mobile,
                        'Mobile number not provided',
                      ),
                      style: TextStyle(
                        color: HomeStyle.muted,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? HomeStyle.tealLight
                            : HomeStyle.amberLight,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                            color: isActive
                                ? AppColors.primaryTeal
                                : HomeStyle.amber,
                            size: 13.sp,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.primaryTeal
                                  : HomeStyle.amber,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: HomeStyle.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: AppColors.primaryTeal,
                  size: 17.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Keep your account information up to date.',
                    style: TextStyle(
                      color: HomeStyle.muted,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // SECTION HEADING
  // ======================================================

  Widget _sectionHeading({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(icon, color: AppColors.primaryTeal, size: 19.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: HomeStyle.ink,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: HomeStyle.muted,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ======================================================
  // ACCOUNT DETAILS
  // ======================================================

  Widget _buildDetailsCard(ProfileData profile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: HomeStyle.border),
      ),
      child: Column(
        children: [
          _detailRow(
            icon: Icons.person_outline_rounded,
            label: 'Full name',
            value: _valueOrFallback(profile.fullName, 'Not provided'),
          ),
          _divider(),
          _detailRow(
            icon: Icons.phone_outlined,
            label: 'Mobile number',
            value: _valueOrFallback(profile.mobile, 'Not provided'),
          ),
          _divider(),
          _detailRow(
            icon: Icons.email_outlined,
            label: 'Email address',
            value: _valueOrFallback(profile.email, 'Not provided'),
          ),
          _divider(),
          _detailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member since',
            value: _formatDate(profile.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 13.h),
      child: Row(
        children: [
          Container(
            width: 35.w,
            height: 35.w,
            decoration: BoxDecoration(
              color: HomeStyle.tealLight,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.primaryTeal, size: 18.sp),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: HomeStyle.muted,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HomeStyle.ink,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.only(left: 59.w),
      child: const Divider(height: 1, thickness: 1, color: HomeStyle.border),
    );
  }

  // ======================================================
  // VERIFICATION
  // ======================================================

  Widget _buildVerificationCard(ProfileData profile) {
    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: HomeStyle.border),
      ),
      child: Column(
        children: [
          _verificationRow(
            label: 'Mobile number',
            verified: profile.mobileVerifiedAt != null,
          ),
          SizedBox(height: 12.h),
          _verificationRow(
            label: 'Email address',
            verified: profile.emailVerifiedAt != null,
          ),
        ],
      ),
    );
  }

  Widget _verificationRow({required String label, required bool verified}) {
    final color = verified ? AppColors.primaryTeal : HomeStyle.muted;

    return Row(
      children: [
        Icon(
          verified ? Icons.check_circle_rounded : Icons.pending_outlined,
          color: color,
          size: 18.sp,
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: HomeStyle.ink,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: verified ? HomeStyle.tealLight : HomeStyle.background,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            verified ? 'Verified' : 'Not verified',
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
      ],
    );
  }

  // ======================================================
  // ERROR STATES
  // ======================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.r),
        child: Container(
          padding: EdgeInsets.all(22.r),
          decoration: BoxDecoration(
            color: AppColors.cardBgWhite,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: HomeStyle.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  color: HomeStyle.tealLight,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.person_off_outlined,
                  size: 27.sp,
                  color: AppColors.primaryTeal,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                controller.errorMessage.value.isEmpty
                    ? 'Profile details are unavailable.'
                    : controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HomeStyle.muted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
              SizedBox(height: 17.h),
              FilledButton.icon(
                onPressed: controller.fetchProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.cardBgWhite,
                  padding: EdgeInsets.symmetric(
                    horizontal: 17.w,
                    vertical: 11.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                ),
                icon: Icon(Icons.refresh_rounded, size: 17.sp),
                label: Text(
                  'Try again',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineError() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: HomeStyle.redLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.expenseRed.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.iconRed,
            size: 18.sp,
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              controller.errorMessage.value,
              style: TextStyle(
                color: HomeStyle.ink,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          TextButton(
            onPressed: controller.fetchProfile,
            child: Text(
              'Retry',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // FOOTER
  // ======================================================

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.primaryTeal.withValues(alpha: 0.55),
            size: 20.sp,
          ),
          SizedBox(height: 6.h),
          Text(
            'BUDGETBOOK  •  YOUR MONEY, YOUR CONTROL',
            style: TextStyle(
              color: HomeStyle.muted,
              fontSize: 8.5.sp,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // AVATAR & HELPERS
  // ======================================================

  Widget _avatar({required double size, String? imageUrl}) {
    final image = imageUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HomeStyle.tealLight,
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.20),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null || image.isEmpty
          ? Icon(
              Icons.person_rounded,
              size: size * 0.58,
              color: AppColors.primaryTeal,
            )
          : Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.person_rounded,
                size: size * 0.58,
                color: AppColors.primaryTeal,
              ),
            ),
    );
  }

  String _valueOrFallback(String? value, String fallback) {
    return value == null || value.trim().isEmpty ? fallback : value;
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Not available';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
