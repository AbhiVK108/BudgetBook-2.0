import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_widget.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/lend_controller.dart';

class LendView extends GetView<LendController> {
  const LendView({super.key});

  static const Color _teal = Color(0xFF0F8F7F);
  static const Color _tealDark = Color(0xFF087568);
  static const Color _ink = Color(0xFF172B3A);
  static const Color _muted = Color(0xFF87949F);
  static const Color _background = Color(0xFFF4F7F8);
  static const Color _border = Color(0xFFE8EEEE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFab(),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isLoading.value && controller.lends.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: _teal));
          }

          return Column(
            children: [
              SizedBox(height: 12.h),

              _lendingSummary(),

              if (controller.errorMessage.value.isNotEmpty &&
                  controller.lends.isNotEmpty)
                _errorBanner(),

              Expanded(
                child: controller.lends.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: _teal,
                        backgroundColor: Colors.white,
                        onRefresh: controller.refreshLending,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                          itemCount: controller.lends.length + 1,
                          itemBuilder: (_, index) {
                            if (index == controller.lends.length) {
                              return _paginationFooter();
                            }

                            return _lendCard(controller.lends[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        }),
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
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18.sp,
          color: HomeStyle.ink,
        ),
      ),
      titleSpacing: 4.w,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONEY OUT',
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: _teal,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Lending',
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(
            child: Obx(
              () => _iconAction(
                icon: Icons.refresh_rounded,
                isLoading: controller.isLoading.value,
                onTap: controller.refreshLending,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconAction({
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: const Color(0xFFEAF6F3),
      borderRadius: BorderRadius.circular(13.r),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(13.r),
        child: Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13.r),
            border: Border.all(color: _teal.withValues(alpha: 0.12)),
          ),
          child: isLoading
              ? Padding(
                  padding: EdgeInsets.all(12.w),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _teal,
                  ),
                )
              : Icon(icon, size: 21.sp, color: _teal),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FLOATING ACTION BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildFab() {
    return FloatingActionButton.extended(
      backgroundColor: _teal,
      foregroundColor: Colors.white,
      elevation: 3,
      extendedPadding: EdgeInsets.symmetric(horizontal: 20.w),
      icon: Icon(Icons.add_rounded, size: 22.sp),
      label: Text(
        'Add lend',
        style: TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
      onPressed: () async {
        await Get.toNamed(Routes.POST_LEND);
        await controller.refreshLending();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY
  // ---------------------------------------------------------------------------

  Widget _lendingSummary() {
    if (controller.isLoadingSummary.value &&
        controller.lendingSummary.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 10.h),
        child: const LinearProgressIndicator(color: _teal, minHeight: 2),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF126F67), Color(0xFF0B8F7D)],
        ),
        borderRadius: BorderRadius.circular(19.r),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.13),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30.w,
            top: -45.h,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact header
                Row(
                  children: [
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(9.r),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 17.sp,
                      ),
                    ),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: Text(
                        'Lending overview',
                        style: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (controller.isLoadingSummary.value)
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else if (controller.summaryError.value.isNotEmpty)
                      InkWell(
                        onTap: controller.fetchLendingSummary,
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 11.h),

                // Activity counts
                Row(
                  children: [
                    Expanded(
                      child: _summaryCount(
                        label: 'Active records',
                        count: controller.activeRecordCount.value,
                        icon: Icons.people_alt_outlined,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34.h,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    Expanded(
                      child: _summaryCount(
                        label: 'Overdue',
                        count: controller.overdueRecordCount.value,
                        icon: Icons.schedule_rounded,
                        isOverdue: true,
                      ),
                    ),
                  ],
                ),

                if (controller.summaryError.value.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    controller.summaryError.value,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ],

                if (controller.lendingSummary.isEmpty &&
                    controller.summaryError.value.isEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'No currency totals available.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ],

                for (final summary in controller.lendingSummary) ...[
                  SizedBox(height: 10.h),
                  _currencySummary(summary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCount({
    required String label,
    required int count,
    required IconData icon,
    bool isOverdue = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Icon(
              icon,
              size: 16.sp,
              color: isOverdue ? const Color(0xFFFFD3A8) : Colors.white,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencySummary(LendingCurrencySummary summary) {
    return Container(
      padding: EdgeInsets.only(top: 9.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.17)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                summary.currency,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
              const Spacer(),
              Text(
                'FINANCIAL BREAKDOWN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 7.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ],
          ),

          SizedBox(height: 9.h),

          Row(
            children: [
              Expanded(
                child: _amountMetric('Principal', summary.principalTotal),
              ),
              Expanded(
                child: _amountMetric('Recovered', summary.principalRecovered),
              ),
              Expanded(
                child: _amountMetric(
                  'Principal due',
                  summary.principalOutstanding,
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          Row(
            children: [
              Expanded(
                child: _amountMetric(
                  'Interest received',
                  summary.interestReceived,
                ),
              ),
              Expanded(
                child: _amountMetric(
                  'Interest due',
                  summary.interestOutstanding,
                ),
              ),
              Expanded(
                child: _amountMetric(
                  'Total due',
                  summary.totalOutstanding,
                  emphasize: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountMetric(String label, double amount, {bool emphasize = false}) {
    return Padding(
      padding: EdgeInsets.only(right: 3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 8.sp,
              fontFamily: 'HankenGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 3.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount.toStringAsFixed(2),
              style: TextStyle(
                color: emphasize ? const Color(0xFFD2FFF0) : Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LENDING RECORD CARD
  // ---------------------------------------------------------------------------

  Widget _lendCard(Map<String, dynamic> lend) {
    final name = controller.lendName(lend);
    final amount = controller.lendAmount(lend);
    final date = controller.dateFor(lend);
    final outstanding = controller.dueFor(lend);
    final status = controller.statusFor(lend);

    final rawPhone =
        lend['mobile_number']?.toString() ??
        lend['phone']?.toString() ??
        lend['mobile']?.toString() ??
        '';

    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    final hasPhone = phone.replaceAll(RegExp(r'\D'), '').length >= 10;

    final statusColor = _statusColor(status);
    final statusBackground = _statusBackground(status);

    return GestureDetector(
      onTap: () async {
        await Get.toNamed(Routes.GET_LEND, arguments: lend);
        await controller.refreshLending();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19.r),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF173C45).withValues(alpha: 0.035),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _personAvatar(name),

                SizedBox(width: 12.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),

                      SizedBox(height: 5.h),

                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 12.sp,
                            color: _muted,
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              'Principal ${controller.formatAmount(amount)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (date.isNotEmpty) ...[
                        SizedBox(height: 5.h),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11.sp,
                              color: _muted,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              date,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 10.sp,
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (hasPhone) ...[
                        SizedBox(height: 5.h),
                        Text(
                          rawPhone,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 10.sp,
                            fontFamily: 'HankenGrotesk',
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
                      controller.formatAmount(outstanding),
                      style: TextStyle(
                        color: _teal,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),

                    SizedBox(height: 5.h),

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
                        status.isEmpty ? 'Outstanding' : status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 15.h),

            Container(height: 1, color: const Color(0xFFF0F3F4)),

            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'LENDING DETAILS',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _muted,
                  size: 12.sp,
                ),
              ],
            ),

            if (hasPhone) ...[
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: _contactButton(
                      label: 'Call',
                      icon: Icons.call_outlined,
                      color: const Color(0xFF168C6A),
                      background: const Color(0xFFEDF8F3),
                      onTap: () => _callPhone(phone),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  Expanded(
                    child: _contactButton(
                      label: 'WhatsApp',
                      icon: Icons.chat_outlined,
                      color: const Color(0xFF168C50),
                      background: const Color(0xFFEDF8F0),
                      onTap: () => _openWhatsApp(phone),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _personAvatar(String name) {
    return Container(
      width: 45.w,
      height: 45.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE2F4EF), Color(0xFFD1EAE5)],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _teal.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            color: _tealDark,
            fontSize: 19.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'HankenGrotesk',
          ),
        ),
      ),
    );
  }

  Widget _contactButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(11.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11.r),
        child: Container(
          height: 39.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(color: color.withValues(alpha: 0.09)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.sp, color: color),
              SizedBox(width: 7.w),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

    return const Color(0xFF0F8F7F);
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
  // CONTACT ACTIONS
  // ---------------------------------------------------------------------------

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll('+', ''));

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar('Unable to call', 'Could not open the phone dialer.');
      }
    } catch (_) {
      Get.snackbar(
        'Unable to call',
        'Something went wrong while opening the dialer.',
      );
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final whatsappPhone = phone.replaceAll(RegExp(r'\D'), '');

    final uri = Uri.parse('https://wa.me/$whatsappPhone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'WhatsApp unavailable',
          'Could not open WhatsApp for this number.',
        );
      }
    } catch (_) {
      Get.snackbar(
        'WhatsApp unavailable',
        'Something went wrong while opening WhatsApp.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // PAGINATION
  // ---------------------------------------------------------------------------

  Widget _paginationFooter() {
    if (controller.isLoadingMore.value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: const Center(child: CircularProgressIndicator(color: _teal)),
      );
    }

    if (controller.loadMoreError.value.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          children: [
            Text(
              controller.loadMoreError.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 12.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
            TextButton(
              onPressed: controller.loadNextPage,
              child: const Text('Retry', style: TextStyle(color: _teal)),
            ),
          ],
        ),
      );
    }

    if (!controller.hasMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Center(
          child: Text(
            '${controller.lends.length} of ${controller.totalRecords.value} records',
            style: TextStyle(
              color: _muted,
              fontSize: 11.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: TextButton.icon(
          onPressed: controller.loadNextPage,
          icon: Icon(Icons.expand_more_rounded, size: 20.sp),
          label: const Text('Load more lending records'),
          style: TextButton.styleFrom(
            foregroundColor: _teal,
            textStyle: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR BANNER
  // ---------------------------------------------------------------------------

  Widget _errorBanner() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFF4D6CB)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: const Color(0xFFD66C48),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(
                  color: const Color(0xFFB45A3B),
                  fontSize: 11.sp,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ),
            TextButton(
              onPressed: controller.fetchLends,
              child: const Text('Retry', style: TextStyle(color: _teal)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _emptyState() {
    return Center(
      child: Obx(
        () => Padding(
          padding: EdgeInsets.symmetric(horizontal: 35.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F5F1),
                  borderRadius: BorderRadius.circular(27.r),
                ),
                child: Icon(
                  Icons.handshake_outlined,
                  color: _teal,
                  size: 42.sp,
                ),
              ),

              SizedBox(height: 22.h),

              Text(
                controller.errorMessage.value.isEmpty
                    ? 'No lending records yet'
                    : 'Unable to load lending records',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'HankenGrotesk',
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                controller.errorMessage.value.isEmpty
                    ? 'Keep track of money you lend to friends and family, all in one place.'
                    : controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 12.sp,
                  height: 1.6,
                  fontFamily: 'HankenGrotesk',
                ),
              ),

              if (controller.errorMessage.value.isNotEmpty) ...[
                SizedBox(height: 18.h),
                OutlinedButton.icon(
                  onPressed: controller.fetchLends,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _teal,
                    side: const BorderSide(color: _teal),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
