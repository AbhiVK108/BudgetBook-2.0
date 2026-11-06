import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_widget.dart';
import 'package:budget_book_2026/app/modules/lend_and_borrow/controllers/borrow_controller.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class BorrowView extends GetView<BorrowController> {
  const BorrowView({super.key});

  static const Color _accent = Color(0xFF0F8F7D);
  static const Color _ink = Color(0xFF172B36);
  static const Color _muted = Color(0xFF81909A);
  static const Color _page = Color(0xFFF5F8FA);

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
              'Borrow',
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
                        : controller.refreshBorrows,
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
      backgroundColor: _page,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add borrow',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        onPressed: () async {
          await Get.toNamed(Routes.POSTBORROW);
          await controller.refreshBorrows();
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.borrows.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  SizedBox(height: 16.h),
                  _borrowingSummary(),
                  if (controller.errorMessage.value.isNotEmpty &&
                      controller.borrows.isNotEmpty)
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
                                fontFamily: 'HankenGrotesk',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: controller.fetchBorrows,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: controller.borrows.isEmpty
                        ? _emptyState()
                        : RefreshIndicator(
                            onRefresh: controller.refreshBorrows,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                16.w,
                                0,
                                16.w,
                                100.h,
                              ),
                              itemCount: controller.borrows.length + 1,
                              itemBuilder: (_, index) {
                                if (index == controller.borrows.length) {
                                  return _paginationFooter();
                                }

                                final borrow = controller.borrows[index];
                                final name = controller.nameFor(borrow);
                                final amount = controller.amountFor(borrow);
                                final date = controller.dateFor(borrow);
                                final outstanding = controller.dueFor(borrow);
                                final status = controller.statusFor(borrow);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18.r),
                                    onTap: () async {
                                      await Get.toNamed(
                                        Routes.GET_BORROW,
                                        arguments: borrow,
                                      );
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 12.h),
                                      padding: EdgeInsets.all(15.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          18.r,
                                        ),
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
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20.r,
                                            backgroundColor: const Color(
                                              0xFFD4E6E4,
                                            ),
                                            child: Text(
                                              name.isEmpty
                                                  ? '?'
                                                  : name[0].toUpperCase(),
                                              style: TextStyle(
                                                color: _accent,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w700,
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
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: _ink,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'HankenGrotesk',
                                                  ),
                                                ),
                                                SizedBox(height: 3.h),
                                                Text(
                                                  'Principal: ${controller.formatAmount(amount)}',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF697982,
                                                    ),
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: 'HankenGrotesk',
                                                  ),
                                                ),
                                                if (date.isNotEmpty) ...[
                                                  SizedBox(height: 3.h),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .calendar_today_outlined,
                                                        size: 11.sp,
                                                        color: _muted,
                                                      ),
                                                      SizedBox(width: 5.w),
                                                      Expanded(
                                                        child: Text(
                                                          'Borrowed: $date',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color: _muted,
                                                            fontSize: 11.sp,
                                                            fontFamily:
                                                                'HankenGrotesk',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Flexible(
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: 78.w,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    controller.formatAmount(
                                                      outstanding,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: _accent,
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontFamily:
                                                          'HankenGrotesk',
                                                    ),
                                                  ),
                                                  SizedBox(height: 3.h),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8.w,
                                                          vertical: 4.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFEAF8F3,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20.r,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      status.isEmpty
                                                          ? 'Outstanding'
                                                          : status,
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFF168C6A,
                                                        ),
                                                        fontSize: 9.5.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontFamily:
                                                            'HankenGrotesk',
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

  Widget _borrowingSummary() {
    if (controller.isLoadingSummary.value &&
        controller.borrowingSummary.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
        child: const LinearProgressIndicator(color: _accent, minHeight: 2),
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
              Icon(Icons.analytics_outlined, color: _accent, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Borrowing summary',
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
                    color: _accent,
                  ),
                )
              else if (controller.summaryError.value.isNotEmpty)
                IconButton(
                  tooltip: 'Retry summary',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.fetchBorrowingSummary,
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
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 11.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ],
          if (controller.borrowingSummary.isEmpty &&
              controller.summaryError.value.isEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              'No currency totals available.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ],
          for (final summary in controller.borrowingSummary) ...[
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count',
              style: TextStyle(
                color: foreground,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencySummary(BorrowingCurrencySummary summary) {
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
              color: _accent,
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
              Expanded(child: _amountMetric('Repaid', summary.principalRepaid)),
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
                child: _amountMetric('Interest paid', summary.interestPaid),
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
                color: emphasize ? _accent : const Color(0xFF263445),
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
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12.sp,
                fontFamily: 'HankenGrotesk',
              ),
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
            '${controller.borrows.length} of ${controller.totalRecords.value} records',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: controller.loadNextPage,
        child: const Text('Load more borrowing records'),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66.w,
            height: 66.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F2),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Icon(Icons.savings_outlined, color: _accent, size: 30.sp),
          ),
          SizedBox(height: 14.h),
          Text(
            controller.errorMessage.value.isEmpty
                ? 'No borrowing records found.'
                : controller.errorMessage.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          if (controller.errorMessage.value.isNotEmpty) ...[
            SizedBox(height: 10.h),
            TextButton(
              onPressed: controller.fetchBorrows,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
