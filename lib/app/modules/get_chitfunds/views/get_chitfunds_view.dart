import 'package:budget_book_2026/app/modules/get_chitfunds/controllers/get_chitfunds_controller.dart';
import 'package:budget_book_2026/app/modules/get_chitfunds/controllers/chit_summary_controller.dart';
import 'package:budget_book_2026/app/modules/get_chitfunds/views/chit_summary_view.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class GetChitfundsView extends GetView<GetChitfundsController> {
  const GetChitfundsView({super.key});

  static const Color _primary = Color(0xFF079B8D);
  static const Color _background = Color(0xFFF6F8F8);
  static const Color _border = Color(0xFFDDECE9);
  static const Color _ink = Color(0xFF263445);
  static const Color _muted = Color(0xFF75828F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Chit Funds',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh chit funds',
            onPressed: controller.refreshChits,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18.r)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add chit fund'),
        onPressed: _openCreateChit,
      ),
      body: SafeArea(
        top: false,
        child: Obx(
          () => RefreshIndicator(
            color: _primary,
            onRefresh: controller.refreshChits,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter < 200 &&
                    controller.hasMore) {
                  controller.loadNextPage();
                }
                return false;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 104.h),
                children: [
                  _introPanel(),
                  SizedBox(height: 22.h),
                  _sectionHeader(),
                  SizedBox(height: 12.h),
                  if (controller.isLoading.value && controller.chits.isEmpty)
                    _loadingState()
                  else if (controller.chits.isEmpty)
                    _emptyState()
                  else ...[
                    for (final chit in controller.chits) _chitCard(chit),
                    if (controller.loadError.value.isNotEmpty)
                      _inlineError(
                        controller.loadError.value,
                        controller.refreshChits,
                      ),
                    if (controller.loadMoreError.value.isNotEmpty)
                      _inlineError(
                        controller.loadMoreError.value,
                        controller.loadNextPage,
                      )
                    else if (controller.hasMore)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: TextButton(
                            onPressed: controller.loadNextPage,
                            child: Text(
                              controller.isLoadingMore.value
                                  ? 'Loading…'
                                  : 'Load more',
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _introPanel() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF079B8D), Color(0xFF087F75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(
              Icons.groups_2_outlined,
              color: Colors.white,
              size: 25.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your chit funds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Keep contributions and schedules in one place.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 11.sp,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.totalRecords.value.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                Text(
                  controller.totalRecords.value == 1 ? 'fund' : 'funds',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10.sp,
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

  Widget _sectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Your memberships',
            style: TextStyle(
              color: _ink,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
        Obx(
          () => Text(
            controller.chits.isEmpty
                ? ''
                : '${controller.chits.length} of ${controller.totalRecords.value}',
            style: TextStyle(
              color: _muted,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
      ],
    );
  }

  Widget _chitCard(Map<String, dynamic> chit) {
    final title = controller.valueFor(chit, ['name', 'chit_name']);
    final organizer = controller.valueFor(chit, [
      'organizer_name',
      'organizer',
    ]);
    final status = controller.valueFor(chit, ['status', 'chit_status']);
    final type = controller.valueFor(chit, ['chit_type', 'type']);
    final value = controller.amountFor(chit, [
      'chit_value',
      'total_value',
      'amount',
    ]);
    final installment = controller.amountFor(chit, [
      'installment_amount',
      'monthly_contribution',
      'contribution_amount',
    ]);
    final count = controller.valueFor(chit, [
      'installment_count',
      'duration_months',
      'tenure_months',
    ]);
    final members = controller.valueFor(chit, [
      'member_count',
      'members_count',
      'total_members',
    ]);
    final startDate = controller.valueFor(chit, ['start_date']);
    final firstDueDate = controller.valueFor(chit, [
      'first_due_date',
      'next_due_date',
    ]);

    final uuid = controller.valueFor(chit, [
      'uuid',
      'chit_uuid',
      'id',
      'chit_id',
    ]);

    return InkWell(
      onTap: uuid.isEmpty ? null : () => _openChitSummary(chit, uuid),
      borderRadius: BorderRadius.circular(17.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(17.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF184B44).withValues(alpha: 0.045),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21.r,
                  backgroundColor: const Color(0xFFE9F7F4),
                  child: Icon(
                    Icons.savings_outlined,
                    color: _primary,
                    size: 21.sp,
                  ),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Chit fund' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                      if (organizer.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'Organizer: $organizer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11.sp,
                            fontFamily: 'HankenGrotesk',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (status.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  _statusBadge(status),
                ],
                SizedBox(width: 2.w),
                Icon(Icons.chevron_right_rounded, color: _muted, size: 20.sp),
              ],
            ),
            SizedBox(height: 13.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFA),
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _metric(
                      'Chit value',
                      _money(value),
                      emphasized: true,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(child: _metric('Contribution', _money(installment))),
                ],
              ),
            ),
            if (count.isNotEmpty ||
                members.isNotEmpty ||
                type.isNotEmpty ||
                startDate.isNotEmpty ||
                firstDueDate.isNotEmpty) ...[
              SizedBox(height: 11.h),
              Wrap(
                spacing: 13.w,
                runSpacing: 8.h,
                children: [
                  if (count.isNotEmpty)
                    _detail(
                      Icons.calendar_month_outlined,
                      '$count instalments',
                    ),
                  if (members.isNotEmpty)
                    _detail(Icons.people_outline_rounded, '$members members'),
                  if (type.isNotEmpty)
                    _detail(Icons.category_outlined, _humanize(type)),
                  if (startDate.isNotEmpty)
                    _detail(Icons.event_outlined, 'Starts ${_date(startDate)}'),
                  if (firstDueDate.isNotEmpty)
                    _detail(
                      Icons.event_available_outlined,
                      'First due ${_date(firstDueDate)}',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final isComplete = normalized == 'completed' || normalized == 'complete';
    final isInactive = normalized == 'inactive' || normalized == 'cancelled';
    final foreground = isComplete
        ? const Color(0xFF24805D)
        : isInactive
        ? _muted
        : _primary;
    final background = isComplete
        ? const Color(0xFFEAF7F0)
        : isInactive
        ? const Color(0xFFF2F4F7)
        : const Color(0xFFE9F7F4);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        _humanize(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'HankenGrotesk',
        ),
      ),
    );
  }

  Widget _metric(String label, String value, {bool emphasized = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _muted,
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        SizedBox(height: 4.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: emphasized ? _primary : _ink,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ),
      ],
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _primary, size: 14.sp),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            color: _muted,
            fontSize: 10.sp,
            fontFamily: 'HankenGrotesk',
          ),
        ),
      ],
    );
  }

  Widget _loadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 44.h),
      child: const Center(child: CircularProgressIndicator(color: _primary)),
    );
  }

  Widget _emptyState() {
    final hasError = controller.loadError.value.isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 30.h),
      child: Column(
        children: [
          Icon(
            hasError ? Icons.cloud_off_outlined : Icons.savings_outlined,
            color: _primary,
            size: 38.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            hasError ? controller.loadError.value : 'No chit funds yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            hasError
                ? 'Check your connection and try again.'
                : 'Add a chit fund to keep its contribution schedule handy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 11.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          if (hasError) ...[
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: controller.refreshChits,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inlineError(String message, VoidCallback onRetry) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.fromLTRB(12.w, 6.h, 6.w, 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F4),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFF4D8D2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFF9B4C3B),
                fontSize: 11.sp,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Future<void> _openCreateChit() async {
    final result = await Get.toNamed(Routes.POSTCHITFUND);
    if (result == true) await controller.refreshChits();
  }

  Future<void> _openChitSummary(Map<String, dynamic> chit, String uuid) async {
    await Get.to<void>(
      () => const ChitSummaryView(),
      binding: BindingsBuilder(
        () => Get.lazyPut<ChitSummaryController>(
          () => ChitSummaryController(
            chitUuid: uuid,
            chit: Map<String, dynamic>.from(chit),
            apiService: controller.apiService,
          ),
        ),
      ),
    );
  }

  String _money(double? value) {
    if (value == null) return '—';
    return '₹${value.toStringAsFixed(2)}';
  }

  String _date(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
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
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _humanize(String value) =>
      value.replaceAll('_', ' ').replaceAll('-', ' ');
}
