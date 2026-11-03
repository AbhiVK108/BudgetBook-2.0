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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBgWhite,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'OVERVIEW',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: AppColors.primaryTeal,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Lending',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                color: HomeStyle.ink,
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
                () => Material(
                  color: const Color(0xFFE8F5F2),
                  borderRadius: BorderRadius.circular(13.r),
                  child: InkWell(
                    onTap: controller.isLoading.value
                        ? null
                        : controller.refreshLending,
                    borderRadius: BorderRadius.circular(13.r),
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(
                          color: AppColors.primaryTeal.withValues(alpha: 0.13),
                        ),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 21.sp,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F8F7F),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add lend',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        onPressed: () async {
          await Get.toNamed(Routes.POST_LEND);
          await controller.refreshLending();
        },
      ),
      backgroundColor: const Color(0xFFF5F8FA),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.lends.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  SizedBox(height: 16.h),
                  _lendingSummary(),
                  if (controller.errorMessage.value.isNotEmpty &&
                      controller.lends.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.errorMessage.value,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: controller.fetchLends,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: controller.lends.isEmpty
                        ? _emptyState()
                        : RefreshIndicator(
                            onRefresh: controller.refreshLending,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              itemCount: controller.lends.length + 1,
                              itemBuilder: (_, index) {
                                if (index == controller.lends.length) {
                                  return _paginationFooter();
                                }
                                final lend = controller.lends[index];
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

                                final phone = rawPhone.replaceAll(
                                  RegExp(r'[^0-9+]'),
                                  '',
                                );
                                final hasPhone =
                                    phone
                                        .replaceAll(RegExp(r'\D'), '')
                                        .length >=
                                    10;

                                return GestureDetector(
                                  onTap: () async {
                                    await Get.toNamed(
                                      Routes.GET_LEND,
                                      arguments: lend,
                                    );
                                    await controller.refreshLending();
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 12.h),
                                    padding: EdgeInsets.all(15.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18.r),
                                      border: Border.all(
                                        color: const Color(0xFFE8EFF0),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x080D3038),
                                          blurRadius: 16,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22.r,
                                              backgroundColor: const Color(
                                                0xFFD4E6E4,
                                              ),
                                              child: Text(
                                                name.isEmpty
                                                    ? '?'
                                                    : name[0].toUpperCase(),
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF0F8F7D,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'HankenGrotesk',
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily:
                                                          'HankenGrotesk',
                                                    ),
                                                  ),
                                                  SizedBox(height: 2.h),
                                                  Text(
                                                    'Principal: ${controller.formatAmount(amount)}',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: Colors.grey[600],
                                                      fontFamily:
                                                          'HankenGrotesk',
                                                    ),
                                                  ),
                                                  if (date.isNotEmpty) ...[
                                                    SizedBox(height: 2.h),
                                                    Text(
                                                      'Lent: $date',
                                                      style: TextStyle(
                                                        fontSize: 11.sp,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ],
                                                  if (hasPhone) ...[
                                                    SizedBox(height: 3.h),
                                                    Text(
                                                      rawPhone,
                                                      style: TextStyle(
                                                        fontSize: 11.sp,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  controller.formatAmount(
                                                    outstanding,
                                                  ),
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF0F8F7D,
                                                    ),
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  status.isEmpty
                                                      ? 'Outstanding'
                                                      : status,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 10.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        if (hasPhone) ...[
                                          SizedBox(height: 12.h),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () async {
                                                    final uri = Uri(
                                                      scheme: 'tel',
                                                      path: phone.replaceAll(
                                                        '+',
                                                        '',
                                                      ),
                                                    );

                                                    if (await canLaunchUrl(
                                                      uri,
                                                    )) {
                                                      await launchUrl(uri);
                                                    } else {
                                                      Get.snackbar(
                                                        'Unable to call',
                                                        'Could not open the phone dialer.',
                                                      );
                                                    }
                                                  },
                                                  icon: Icon(
                                                    Icons.call_outlined,
                                                    size: 17.sp,
                                                  ),
                                                  label: const Text('Call'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        const Color(0xFF0F8F7D),
                                                    side: const BorderSide(
                                                      color: Color(0xFFBCEBE4),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 9.h,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            9.r,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10.w),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () async {
                                                    // WhatsApp international format:
                                                    // remove +, spaces, and other non-digit characters.
                                                    final whatsappPhone = phone
                                                        .replaceAll(
                                                          RegExp(r'\D'),
                                                          '',
                                                        );

                                                    final uri = Uri.parse(
                                                      'https://wa.me/$whatsappPhone',
                                                    );

                                                    if (await canLaunchUrl(
                                                      uri,
                                                    )) {
                                                      await launchUrl(
                                                        uri,
                                                        mode: LaunchMode
                                                            .externalApplication,
                                                      );
                                                    } else {
                                                      Get.snackbar(
                                                        'WhatsApp unavailable',
                                                        'Could not open WhatsApp for this number.',
                                                      );
                                                    }
                                                  },
                                                  icon: Icon(
                                                    Icons.chat_outlined,
                                                    size: 17.sp,
                                                  ),
                                                  label: const Text('WhatsApp'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        const Color(0xFF168C50),
                                                    side: const BorderSide(
                                                      color: Color(0xFFBCE5C9),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 9.h,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            9.r,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _lendingSummary() {
    if (controller.isLoadingSummary.value &&
        controller.lendingSummary.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
        child: const LinearProgressIndicator(
          color: Color(0xFF0F8F7D),
          minHeight: 2,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(color: const Color(0xFFE6EEEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090D3038),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: const Color(0xFF0F8F7D),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Lending summary',
                style: TextStyle(
                  color: const Color(0xFF263445),
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
              const Spacer(),
              if (controller.isLoadingSummary.value)
                SizedBox(
                  width: 15.w,
                  height: 15.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0F8F7D),
                  ),
                )
              else if (controller.summaryError.value.isNotEmpty)
                IconButton(
                  tooltip: 'Retry summary',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.fetchLendingSummary,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.red.shade600,
                    size: 20.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _countMetric(
                  'Active records',
                  controller.activeRecordCount.value,
                  const Color(0xFF168C6A),
                  const Color(0xFFEAF8F1),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _countMetric(
                  'Overdue',
                  controller.overdueRecordCount.value,
                  const Color(0xFFE17836),
                  const Color(0xFFFFF3E8),
                ),
              ),
            ],
          ),
          if (controller.summaryError.value.isNotEmpty) ...[
            SizedBox(height: 9.h),
            Text(
              controller.summaryError.value,
              style: TextStyle(color: Colors.red.shade700, fontSize: 11.sp),
            ),
          ],
          if (controller.lendingSummary.isEmpty &&
              controller.summaryError.value.isEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              'No currency totals available.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
            ),
          ],
          for (final summary in controller.lendingSummary) ...[
            SizedBox(height: 12.h),
            _currencySummary(summary),
          ],
        ],
      ),
    );
  }

  Widget _countMetric(
    String label,
    int count,
    Color foreground,
    Color background,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: foreground.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            '$count',
            style: TextStyle(
              color: foreground,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencySummary(LendingCurrencySummary summary) {
    return Container(
      padding: EdgeInsets.only(top: 10.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE8EFEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.currency,
            style: TextStyle(
              color: const Color(0xFF0F8F7D),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
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
      padding: EdgeInsets.only(right: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 3.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount.toStringAsFixed(2),
              style: TextStyle(
                color: emphasize
                    ? const Color(0xFF0F8F7D)
                    : const Color(0xFF263445),
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

  Widget _paginationFooter() {
    if (controller.isLoadingMore.value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.loadMoreError.value.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          children: [
            Text(
              controller.loadMoreError.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 12.sp),
            ),
            TextButton(
              onPressed: controller.loadNextPage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (!controller.hasMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Text(
            '${controller.lends.length} of ${controller.totalRecords.value} records',
            style: TextStyle(color: Colors.grey[600], fontSize: 11.sp),
          ),
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: controller.loadNextPage,
        child: const Text('Load more lending records'),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.errorMessage.value.isEmpty
                  ? 'No lending records found.'
                  : controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
            if (controller.errorMessage.isNotEmpty) ...[
              SizedBox(height: 10.h),
              TextButton(
                onPressed: controller.fetchLends,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
