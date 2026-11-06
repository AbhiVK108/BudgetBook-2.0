import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';

import '../controllers/get_borrow_controller.dart';

class GetBorrowView extends GetView<GetBorrowController> {
  const GetBorrowView({super.key});

  static const Color primaryColor = Color(0xFF0F8F7F);
  static const Color primaryDark = Color(0xFF087568);
  static const Color scaffoldColor = Color(0xFFF4F7F8);
  static const Color darkColor = Color(0xFF172B3A);
  static const Color labelColor = Color(0xFF647582);
  static const Color mutedColor = Color(0xFF87949F);
  static const Color borderColor = Color(0xFFE8EEEE);
  static const String fontFamily = 'HankenGrotesk';

  Map<String, dynamic> get _borrow => controller.selectedBorrow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value && controller.selectedBorrow.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.selectedBorrow.isEmpty) {
          return _errorState();
        }

        if (controller.selectedBorrow.isEmpty) {
          return _emptyState();
        }

        return RefreshIndicator(
          color: primaryColor,
          backgroundColor: Colors.white,
          onRefresh: _refreshDetails,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
            children: [
              _personHeader(),
              SizedBox(height: 14.h),
              _financialOverview(),
              SizedBox(height: 14.h),
              _borrowingInformation(),
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
              'BORROWING RECORD',
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
                  ? 'Borrowing details'
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
          child: _headerAction(
            icon: Icons.edit_outlined,
            onTap: _showEditDialog,
          ),
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
        _borrow['borrower_phone']?.toString() ??
        _borrow['lender_phone']?.toString() ??
        _borrow['phone']?.toString() ??
        _borrow['mobile']?.toString() ??
        controller.phone;

    final hasPhone = _normalizedPhone(mobile).isNotEmpty;
    final status = _status;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BORROWED FROM',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    fontFamily: fontFamily,
                  ),
                ),
                SizedBox(height: 3.h),
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
                    _statusBadge(status),
                  ],
                ),
                if (hasPhone) ...[
                  SizedBox(height: 6.h),
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
                        label: 'Call',
                        tooltip: 'Call lender',
                        foreground: const Color(0xFF2563EB),
                        background: const Color(0xFFEEF4FF),
                        onTap: () => _callNumber(mobile),
                      ),
                      SizedBox(width: 5.w),
                      _personContactButton(
                        icon: FontAwesomeIcons.whatsapp,
                        label: 'WhatsApp',
                        tooltip: 'Message on WhatsApp',
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

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  Widget _personContactButton({
    required FaIconData icon,
    required String label,
    required String tooltip,
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
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

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

  // ---------------------------------------------------------------------------
  // FINANCIAL OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _financialOverview() {
    final borrow = _borrow;

    final principal = _firstAmount([
      borrow['principal_amount'],
      borrow['amount'],
      borrow['borrowed_amount'],
    ]);

    final principalPaid = _firstAmount([
      borrow['principal_paid'],
      borrow['principal_repaid'],
      borrow['principal_recovered'],
    ]);

    final principalOutstanding = _firstAmount([
      borrow['principal_outstanding'],
      borrow['principal_due'],
    ]);

    final interestPaid = _firstAmount([
      borrow['interest_paid'],
      borrow['interest_repaid'],
      borrow['interest_received'],
    ]);

    final interestOutstanding = _firstAmount([
      borrow['interest_outstanding'],
      borrow['interest_due'],
    ]);

    final totalOutstanding = _firstAmount([
      borrow['total_outstanding'],
      borrow['outstanding_amount'],
      borrow['balance_due'],
    ]);

    final interestMethod =
        borrow['interest_method']?.toString().toLowerCase() ?? '';

    final interestDescription = interestMethod == 'fixed'
        ? _formatCurrency(
            _firstAmount([borrow['fixed_interest_amount'], borrow['interest']]),
          )
        : interestMethod == 'percentage'
        ? '${borrow['interest_rate'] ?? borrow['interest'] ?? '—'}% ${borrow['interest_period'] ?? ''}'
        : interestMethod.isEmpty
        ? 'Not specified'
        : interestMethod.capitalizeFirst!;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryDark, primaryColor],
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
                        'Borrowing overview',
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
                    _formatCurrency(
                      totalOutstanding > 0
                          ? totalOutstanding
                          : principalOutstanding + interestOutstanding,
                    ),
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
                              label: 'Borrowed',
                              value: _formatCurrency(principal),
                              icon: Icons.account_balance_outlined,
                            ),
                          ),
                          _metricDivider(),
                          Expanded(
                            child: _overviewMetric(
                              label: 'Principal paid',
                              value: _formatCurrency(principalPaid),
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      _overviewDivider(),
                      Row(
                        children: [
                          Expanded(
                            child: _overviewMetric(
                              label: 'Principal due',
                              value: _formatCurrency(principalOutstanding),
                              icon: Icons.pending_outlined,
                            ),
                          ),
                          _metricDivider(),
                          Expanded(
                            child: _overviewMetric(
                              label: 'Interest paid',
                              value: _formatCurrency(interestPaid),
                              icon: Icons.trending_up_rounded,
                            ),
                          ),
                        ],
                      ),
                      _overviewDivider(),
                      Row(
                        children: [
                          Expanded(
                            child: _overviewMetric(
                              label: 'Interest due',
                              value: _formatCurrency(interestOutstanding),
                              icon: Icons.percent_rounded,
                            ),
                          ),
                          _metricDivider(),
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

  Widget _metricDivider() {
    return Container(
      width: 1,
      height: 34.h,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }

  Widget _overviewDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
    );
  }

  // ---------------------------------------------------------------------------
  // BORROWING INFORMATION
  // ---------------------------------------------------------------------------

  Widget _borrowingInformation() {
    final note = controller.description.isNotEmpty
        ? controller.description
        : 'No description added';

    final interest = _firstAmount([
      _borrow['fixed_interest_amount'],
      _borrow['interest_amount'],
      _borrow['interest'],
    ]);

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
            title: 'Borrowing information',
            icon: Icons.receipt_long_outlined,
          ),
          SizedBox(height: 17.h),
          Row(
            children: [
              Expanded(
                child: _informationTile(
                  label: 'RECEIVED ON',
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
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6F3),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFDCEFEA)),
            ),
            child: Row(
              children: [
                Icon(Icons.percent_rounded, color: primaryColor, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Interest amount',
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
                Text(
                  _formatCurrency(interest),
                  style: TextStyle(
                    color: primaryDark,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: fontFamily,
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
                  'Making a repayment?',
                  style: TextStyle(
                    color: darkColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: fontFamily,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Keep your borrowing balance updated.',
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
        repayment['amount_paid'] ??
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

    final account =
        repayment['payment_account'] ??
        repayment['paying_account'] ??
        repayment['receiving_account'] ??
        repayment['account'];

    final accountName =
        repayment['payment_account_name'] ??
        repayment['paying_account_name'] ??
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
              Icons.north_east_rounded,
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
                '-${_formatCurrency(_parseAmount(amount))}',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: fontFamily,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Paid',
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
            'Payments made will appear here.',
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
    final raw = _borrow['status']?.toString() ?? '';
    final value = raw.toLowerCase();

    if (value.contains('overdue') || value.contains('late')) {
      return 'Overdue';
    }

    if (value.contains('paid') ||
        value.contains('settled') ||
        value.contains('closed')) {
      return 'Settled';
    }

    return raw.isEmpty ? 'Active' : raw.capitalizeFirst!;
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
              'No borrowing record found',
              style: TextStyle(
                color: darkColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                fontFamily: fontFamily,
              ),
            ),
            SizedBox(height: 7.h),
            Text(
              'This borrowing record may have been removed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedColor,
                fontSize: 12.sp,
                fontFamily: fontFamily,
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: controller.fetchBorrows,
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
              onPressed: controller.fetchBorrows,
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

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  double _firstAmount(List<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return _parseAmount(value);
      }
    }
    return 0;
  }

  String _formatCurrency(double value) {
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    return '₹$formatted';
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  Future<void> _refreshDetails() async {
    await controller.fetchBorrows();
    await controller.fetchRepayments();
  }

  Future<void> _recordRepayment() async {
    final result = await Get.toNamed(
      Routes.BORROWING_REPAYMENT,
      arguments: Map<String, dynamic>.from(_borrow),
    );

    if (result is Map) {
      controller.applyRepaymentAgreement(Map<String, dynamic>.from(result));
      await _refreshDetails();
    } else if (result == true) {
      await _refreshDetails();
    }
  }

  // ---------------------------------------------------------------------------
  // EDIT BORROW DIALOG
  // ---------------------------------------------------------------------------

  Future<void> _showEditDialog() async {
    final nameController = TextEditingController(text: controller.personName);
    final phoneController = TextEditingController(text: controller.phone);
    final amountController = TextEditingController(text: controller.amount);
    final interestController = TextEditingController(text: controller.interest);
    final receiveDateController = TextEditingController(
      text: controller.receiveDate,
    );
    final returnDateController = TextEditingController(
      text: controller.returnDate,
    );
    final descriptionController = TextEditingController(
      text: controller.description,
    );

    try {
      final updated = await Get.dialog<bool>(
        Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(19.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6F3),
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: primaryColor,
                          size: 19.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Edit borrowing',
                          style: TextStyle(
                            color: darkColor,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(result: false),
                        icon: Icon(
                          Icons.close_rounded,
                          color: mutedColor,
                          size: 21.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    'Update the borrowing record details.',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 11.sp,
                      fontFamily: fontFamily,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  _editField(nameController, 'Person name'),
                  _editField(
                    phoneController,
                    'Phone number',
                    keyboardType: TextInputType.phone,
                  ),
                  _editField(
                    amountController,
                    'Borrowed amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _editField(
                    interestController,
                    'Interest',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _editField(
                    receiveDateController,
                    'Received date (YYYY-MM-DD)',
                  ),
                  _editField(returnDateController, 'Return date (YYYY-MM-DD)'),
                  _editField(descriptionController, 'Description', maxLines: 3),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44.h,
                          child: OutlinedButton(
                            onPressed: () => Get.back(result: false),
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
                          height: 44.h,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.trim().isEmpty) {
                                _showValidationError(
                                  'Please enter the person name.',
                                );
                                return;
                              }

                              final amount = double.tryParse(
                                amountController.text.trim(),
                              );

                              if (amount == null || amount <= 0) {
                                _showValidationError(
                                  'Enter a valid borrowing amount.',
                                );
                                return;
                              }

                              final success = await controller.updateBorrow(
                                personName: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                amount: amountController.text.trim(),
                                interest: interestController.text.trim(),
                                receiveDate: receiveDateController.text.trim(),
                                returnDate: returnDateController.text.trim(),
                                description: descriptionController.text.trim(),
                              );

                              if (success) {
                                Get.back(result: true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Save changes',
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
        ),
        barrierDismissible: false,
      );

      if (updated == true) {
        await controller.fetchBorrows();
        await controller.fetchRepayments();
      }
    } finally {
      nameController.dispose();
      phoneController.dispose();
      amountController.dispose();
      interestController.dispose();
      receiveDateController.dispose();
      returnDateController.dispose();
      descriptionController.dispose();
    }
  }

  Widget _editField(
    TextEditingController textController,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextField(
        controller: textController,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          color: darkColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: labelColor,
            fontSize: 11.sp,
            fontFamily: fontFamily,
          ),
          filled: true,
          fillColor: const Color(0xFFF7F9FA),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 13.w,
            vertical: 13.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: primaryColor, width: 1.2),
          ),
        ),
      ),
    );
  }

  void _showValidationError(String message) {
    Get.snackbar(
      'Check details',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: darkColor,
      margin: EdgeInsets.all(14.w),
      borderRadius: 14.r,
    );
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
                'Delete borrowing record?',
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
                'Are you sure you want to delete this borrowing record? '
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
                        onPressed: () => Get.back(result: false),
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
                        onPressed: () => Get.back(result: true),
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

    // Connect this confirmation to the actual delete API.
    // Do not show a success message until the API confirms deletion.
    Get.snackbar(
      'Delete',
      'Connect the delete API to remove this borrowing record.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: darkColor,
      margin: EdgeInsets.all(14.w),
      borderRadius: 14.r,
    );
  }
}
