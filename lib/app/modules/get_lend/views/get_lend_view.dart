import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_widget.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/get_lend_controller.dart';

class GetLendView extends GetView<GetLendController> {
  const GetLendView({super.key});

  static const Color primaryColor = Color(0xFF0F8F7F);
  static const Color primaryDark = Color(0xFF087568);
  static const Color scaffoldColor = Color(0xFFF4F7F8);
  static const Color darkColor = Color(0xFF172B3A);
  static const Color labelColor = Color(0xFF647582);
  static const Color mutedColor = Color(0xFF87949F);
  static const Color borderColor = Color(0xFFE8EEEE);
  static const String fontFamily = 'HankenGrotesk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _errorState();
        }

        if (controller.selectedLend.isEmpty) {
          return _emptyState();
        }

        return RefreshIndicator(
          color: primaryColor,
          backgroundColor: Colors.white,
          onRefresh: controller.refreshDetails,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
            children: [
              _personHeader(),
              SizedBox(height: 14.h),
              _financialOverview(),
              SizedBox(height: 14.h),
              _lendingInformation(),
              SizedBox(height: 14.h),
              _repaymentAction(),
              SizedBox(height: 18.h),
              _repaymentHistory(),
            ],
          ),
        );
      }),
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
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18.sp,
          color: darkColor,
        ),
      ),
      titleSpacing: 4.w,
      title: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LENDING RECORD',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              controller.personName.isEmpty
                  ? 'Lending details'
                  : controller.personName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                color: darkColor,
                height: 1,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: _headerAction(icon: Icons.edit_outlined, onTap: _editLend),
        ),
      ],
    );
  }

  Widget _headerAction({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFFEAF6F3),
      borderRadius: BorderRadius.circular(13.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13.r),
        child: Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, size: 20.sp, color: primaryColor),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PERSON HEADER
  // ---------------------------------------------------------------------------

  Widget _personHeader() {
    final name = controller.personName;
    final mobile =
        controller.selectedLend['borrower_phone']?.toString() ??
        controller.selectedLend['phone']?.toString() ??
        controller.selectedLend['mobile']?.toString() ??
        '';

    final hasPhone = _normalizedPhone(mobile).isNotEmpty;

    final status = _status;
    final statusColor = _statusColor(status);
    final statusBackground = _statusBackground(status);

    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173C45).withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Person avatar
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F1),
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                color: primaryDark,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                fontFamily: fontFamily,
              ),
            ),
          ),

          SizedBox(width: 11.w),

          // Person details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GIVEN TO',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    fontFamily: fontFamily,
                  ),
                ),

                SizedBox(height: 2.h),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isEmpty ? 'Unknown person' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: darkColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),

                if (hasPhone) ...[
                  SizedBox(height: 5.h),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mobile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),

                      SizedBox(width: 6.w),

                      _personContactButton(
                        icon: FontAwesomeIcons.phone,
                        tooltip: 'Call borrower',
                        label: 'Call',
                        foreground: const Color(0xFF2563EB),
                        background: const Color(0xFFEEF4FF),
                        onTap: () => _callNumber(mobile),
                      ),

                      SizedBox(width: 5.w),

                      _personContactButton(
                        icon: FontAwesomeIcons.whatsapp,
                        tooltip: 'Message on WhatsApp',
                        label: 'WhatsApp',
                        foreground: const Color(0xFF168C55),
                        background: const Color(0xFFEAF7EF),
                        onTap: () => _openWhatsApp(mobile),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personContactButton({
    required FaIconData icon,
    required String tooltip,
    required String label,
    required Color foreground,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(icon, size: 12.sp, color: foreground),
                SizedBox(width: 5.w),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _normalizedPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '').trim();
  }

  String _whatsAppPhone(String phone) {
    // Keep only digits for the WhatsApp URL.
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Handle Indian numbers:
    // 9876543210   -> 919876543210
    // 09876543210  -> 919876543210
    // 919876543210 -> 919876543210
    if (digits.length == 10) {
      digits = '91$digits';
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = '91${digits.substring(1)}';
    }

    return digits;
  }

  Future<void> _callNumber(String phone) async {
    final normalized = _normalizedPhone(phone);

    if (normalized.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: normalized);

    try {
      final launched = await launchUrl(uri);

      if (!launched) {
        _showContactError('Unable to open the phone dialer.');
      }
    } catch (_) {
      _showContactError('Unable to open the phone dialer.');
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final whatsappPhone = _whatsAppPhone(phone);

    if (whatsappPhone.isEmpty) return;

    final uri = Uri.parse('https://wa.me/$whatsappPhone');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showContactError('Unable to open WhatsApp.');
      }
    } catch (_) {
      _showContactError('Unable to open WhatsApp.');
    }
  }

  void _showContactError(String message) {
    Get.snackbar(
      'Contact action',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: darkColor,
      margin: EdgeInsets.all(14.w),
      borderRadius: 14.r,
    );
  }

  Widget _contactAction({
    required IconData icon,
    required Color color,
    required Color background,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(9.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9.r),
          child: SizedBox(
            width: 28.w,
            height: 28.w,
            child: Icon(icon, size: 15.sp, color: color),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FINANCIAL OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _financialOverview() {
    final lend = controller.selectedLend;

    final principal = _parseAmount(lend['principal_amount']);
    final principalRecovered = _parseAmount(lend['principal_recovered']);
    final principalOutstanding = _parseAmount(lend['principal_outstanding']);
    final interestReceived = _parseAmount(lend['interest_received']);
    final interestOutstanding = _parseAmount(lend['interest_outstanding']);
    final totalOutstanding = _parseAmount(lend['total_outstanding']);

    final interestMethod =
        lend['interest_method']?.toString().toLowerCase() ?? '';

    final interestDescription = interestMethod == 'fixed'
        ? 'Fixed: ${_formatCurrency(_parseAmount(lend['fixed_interest_amount']))}'
        : interestMethod == 'percentage'
        ? '${lend['interest_rate'] ?? '—'}% ${lend['interest_period'] ?? ''}'
        : interestMethod.isEmpty
        ? 'Not specified'
        : interestMethod.capitalizeFirst!;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF126F67), Color(0xFF0B8F7D)],
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35.w,
            top: -45.h,
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 24,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(17.w),
            child: Column(
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
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: Text(
                        'Lending overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                    _actionButton(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFFFD4D4),
                      background: Colors.white.withValues(alpha: 0.12),
                      borderColor: Colors.white.withValues(alpha: 0.15),
                      onTap: _showDeleteDialog,
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                Text(
                  'TOTAL OUTSTANDING',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontFamily: fontFamily,
                  ),
                ),

                SizedBox(height: 5.h),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCurrency(totalOutstanding),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),

                SizedBox(height: 17.h),

                // Principal and recovery breakdown
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 13.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _overviewMetric(
                              label: 'Principal',
                              value: _formatCurrency(principal),
                              icon: Icons.account_balance_outlined,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 34.h,
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          Expanded(
                            child: _overviewMetric(
                              label: 'Recovered',
                              value: _formatCurrency(principalRecovered),
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        child: Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: _overviewMetric(
                              label: 'Principal due',
                              value: _formatCurrency(principalOutstanding),
                              icon: Icons.pending_outlined,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 34.h,
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          Expanded(
                            child: _overviewMetric(
                              label: 'Interest received',
                              value: _formatCurrency(interestReceived),
                              icon: Icons.trending_up_rounded,
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        child: Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: _overviewMetric(
                              label: 'Interest due',
                              value: _formatCurrency(interestOutstanding),
                              icon: Icons.percent_rounded,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 34.h,
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          Expanded(
                            child: _overviewMetric(
                              label: 'Interest method',
                              value: interestDescription,
                              icon: Icons.calculate_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13.sp,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                fontFamily: fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LENDING INFORMATION
  // ---------------------------------------------------------------------------

  Widget _lendingInformation() {
    final note = controller.description.isNotEmpty
        ? controller.description
        : 'No description added';

    return Container(
      padding: EdgeInsets.all(17.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
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
            title: 'Lending information',
            icon: Icons.receipt_long_outlined,
          ),

          SizedBox(height: 17.h),

          Row(
            children: [
              Expanded(
                child: _informationTile(
                  label: 'GIVEN ON',
                  value: controller.receiveDate,
                  icon: Icons.calendar_today_outlined,
                ),
              ),

              SizedBox(width: 10.w),

              Expanded(
                child: _informationTile(
                  label: 'RETURN BY',
                  value: controller.returnDate,
                  icon: Icons.event_available_outlined,
                  isDueDate: true,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Container(
            padding: EdgeInsets.all(13.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F9FA),
              borderRadius: BorderRadius.circular(13.r),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 31.w,
                  height: 31.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6F3),
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Icon(
                    Icons.notes_rounded,
                    color: primaryColor,
                    size: 17.sp,
                  ),
                ),

                SizedBox(width: 10.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOTE',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontFamily: fontFamily,
                        ),
                      ),

                      SizedBox(height: 5.h),

                      Text(
                        note,
                        style: TextStyle(
                          color: darkColor,
                          fontSize: 12.sp,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          fontFamily: fontFamily,
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
    );
  }

  Widget _informationTile({
    required String label,
    required String value,
    required IconData icon,
    bool isDueDate = false,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDueDate ? const Color(0xFFFFF7EC) : const Color(0xFFEAF6F3),
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(
          color: isDueDate ? const Color(0xFFF5E5CF) : const Color(0xFFDCEFEA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isDueDate ? const Color(0xFFD18A35) : primaryColor,
                size: 14.sp,
              ),

              SizedBox(width: 6.w),

              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDueDate ? const Color(0xFFB77A2E) : primaryColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 9.h),

          Text(
            value.isEmpty ? '—' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: darkColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              fontFamily: fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REPAYMENT ACTION
  // ---------------------------------------------------------------------------

  Widget _repaymentAction() {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 43.w,
            height: 43.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6F3),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(
              Icons.payments_outlined,
              color: primaryColor,
              size: 22.sp,
            ),
          ),

          SizedBox(width: 12.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Received a payment?',
                  style: TextStyle(
                    color: darkColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: fontFamily,
                  ),
                ),

                SizedBox(height: 4.h),

                Text(
                  'Keep your lending balance updated.',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          Material(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: _recordRepayment,
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
                child: Text(
                  'Record',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REPAYMENT HISTORY
  // ---------------------------------------------------------------------------

  Widget _repaymentHistory() {
    return Obx(() {
      final repayments = controller.repayments;

      return Container(
        padding: EdgeInsets.all(17.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor),
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
            Row(
              children: [
                Expanded(
                  child: _sectionHeader(
                    title: 'Repayment history',
                    icon: Icons.history_rounded,
                  ),
                ),

                Material(
                  color: const Color(0xFFEAF6F3),
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: controller.fetchRepayments,
                    borderRadius: BorderRadius.circular(10.r),
                    child: SizedBox(
                      width: 34.w,
                      height: 34.w,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: primaryColor,
                        size: 19.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 15.h),

            if (controller.isLoadingRepayments.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              )
            else if (controller.repaymentError.value.isNotEmpty)
              _repaymentError()
            else if (repayments.isEmpty)
              _emptyRepaymentHistory()
            else
              ...repayments.map(_repaymentTile),
          ],
        ),
      );
    });
  }

  Widget _repaymentTile(Map<String, dynamic> repayment) {
    final amount =
        repayment['amount_received'] ??
        repayment['amount'] ??
        repayment['paid_amount'] ??
        '0.00';

    final date =
        repayment['repayment_date'] ??
        repayment['date'] ??
        repayment['transaction_date'] ??
        repayment['created_at'] ??
        '';

    final account = repayment['receiving_account'];

    final accountName =
        repayment['receiving_account_name'] ??
        repayment['account_name'] ??
        (account is Map ? account['name'] : null);

    final reference = repayment['reference'];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 13.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39.w,
            height: 39.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6F3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.south_west_rounded,
              color: primaryColor,
              size: 19.sp,
            ),
          ),

          SizedBox(width: 11.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date.toString(),
                  style: TextStyle(
                    color: darkColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: fontFamily,
                  ),
                ),

                if (accountName != null &&
                    accountName.toString().isNotEmpty) ...[
                  SizedBox(height: 4.h),

                  Text(
                    accountName.toString(),
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: fontFamily,
                    ),
                  ),
                ],

                if (reference != null && reference.toString().isNotEmpty) ...[
                  SizedBox(height: 3.h),

                  Text(
                    reference.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 10.sp,
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: 8.w),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_formatCurrency(_parseAmount(amount))}',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: fontFamily,
                ),
              ),

              SizedBox(height: 4.h),

              Text(
                'Received',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyRepaymentHistory() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 47.w,
            height: 47.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6F3),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(
              Icons.history_rounded,
              color: primaryColor,
              size: 24.sp,
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            'No repayments yet',
            style: TextStyle(
              color: darkColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              fontFamily: fontFamily,
            ),
          ),

          SizedBox(height: 5.h),

          Text(
            'Payments received will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              fontSize: 11.sp,
              fontFamily: fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _repaymentError() {
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF4D6CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.repaymentError.value,
            style: TextStyle(
              color: const Color(0xFFB45A3B),
              fontSize: 11.sp,
              fontFamily: fontFamily,
            ),
          ),

          SizedBox(height: 6.h),

          TextButton(
            onPressed: controller.fetchRepayments,
            child: const Text('Retry', style: TextStyle(color: primaryColor)),
          ),
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
          width: 31.w,
          height: 31.w,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6F3),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: primaryColor, size: 17.sp),
        ),

        SizedBox(width: 9.w),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: darkColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              fontFamily: fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required Color background,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(11.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11.r),
        child: Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: 18.sp, color: color),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATUS
  // ---------------------------------------------------------------------------

  String get _status {
    final raw = controller.selectedLend['status']?.toString() ?? '';
    final value = raw.toLowerCase();

    if (value.contains('overdue') || value.contains('late')) {
      return 'Overdue';
    }

    if (value.contains('paid') ||
        value.contains('settled') ||
        value.contains('closed')) {
      return 'Settled';
    }

    return raw.isEmpty ? 'Active' : raw;
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();

    if (value.contains('overdue') || value.contains('late')) {
      return const Color(0xFFD97732);
    }

    if (value.contains('paid') ||
        value.contains('settled') ||
        value.contains('closed')) {
      return const Color(0xFF168C6A);
    }

    return primaryColor;
  }

  Color _statusBackground(String status) {
    final value = status.toLowerCase();

    if (value.contains('overdue') || value.contains('late')) {
      return const Color(0xFFFFF2E6);
    }

    if (value.contains('paid') ||
        value.contains('settled') ||
        value.contains('closed')) {
      return const Color(0xFFEAF7F0);
    }

    return const Color(0xFFEAF6F3);
  }

  // ---------------------------------------------------------------------------
  // EMPTY / ERROR
  // ---------------------------------------------------------------------------

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _emptyIcon(Icons.account_balance_wallet_outlined),

            SizedBox(height: 16.h),

            Text(
              'No lending record found',
              style: TextStyle(
                color: darkColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                fontFamily: fontFamily,
              ),
            ),

            SizedBox(height: 7.h),

            Text(
              'This lending record may have been removed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedColor,
                fontSize: 12.sp,
                fontFamily: fontFamily,
              ),
            ),

            SizedBox(height: 12.h),

            TextButton(
              onPressed: controller.fetchLends,
              child: const Text(
                'Refresh',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _emptyIcon(Icons.error_outline_rounded),

            SizedBox(height: 16.h),

            Text(
              'Unable to load details',
              style: TextStyle(
                color: darkColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                fontFamily: fontFamily,
              ),
            ),

            SizedBox(height: 8.h),

            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontSize: 12.sp,
                height: 1.5,
                fontFamily: fontFamily,
              ),
            ),

            SizedBox(height: 16.h),

            ElevatedButton(
              onPressed: controller.fetchLends,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyIcon(IconData icon) {
    return Container(
      width: 75.w,
      height: 75.w,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F3),
        borderRadius: BorderRadius.circular(23.r),
      ),
      child: Icon(icon, color: primaryColor, size: 35.sp),
    );
  }

  // ---------------------------------------------------------------------------
  // FORMATTERS
  // ---------------------------------------------------------------------------

  String _formatCurrency(double value) {
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    return '₹$formatted';
  }

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  String _recordNumber() {
    final id = controller.selectedLend['id']?.toString();

    if (id == null || id.isEmpty) {
      return '1';
    }

    return id;
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  Future<void> _editLend() async {
    await Get.toNamed(
      Routes.POST_LEND,
      arguments: Map<String, dynamic>.from(controller.selectedLend),
    );

    await controller.refreshDetails();
  }

  Future<void> _recordRepayment() async {
    final result = await Get.toNamed(
      Routes.LENDING_REPAYMENT,
      arguments: Map<String, dynamic>.from(controller.selectedLend),
    );

    if (result is Map) {
      controller.applyRepaymentAgreement(Map<String, dynamic>.from(result));

      await controller.fetchRepayments();
    } else if (result == true) {
      await controller.refreshDetails();
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE CONFIRMATION
  // ---------------------------------------------------------------------------

  Future<void> _showDeleteDialog() async {
    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 55.w,
                height: 55.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(17.r),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: const Color(0xFFD94D4D),
                  size: 27.sp,
                ),
              ),

              SizedBox(height: 16.h),

              Text(
                'Delete lending record?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkColor,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: fontFamily,
                ),
              ),

              SizedBox(height: 9.h),

              Text(
                'Are you sure you want to delete this lending record? '
                'This action may affect your financial records.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12.sp,
                  height: 1.5,
                  fontFamily: fontFamily,
                ),
              ),

              SizedBox(height: 22.h),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 43.h,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back(result: false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: darkColor,
                          side: const BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  Expanded(
                    child: SizedBox(
                      height: 43.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back(result: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD94D4D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    // Connect this action to the actual delete API.
    // Do not show a success message until deletion succeeds.
    Get.snackbar(
      'Delete',
      'Connect the delete API to remove this lending record.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: darkColor,
    );
  }
}
