import 'package:budget_book_2026/app/modules/get_chitfunds/controllers/chit_summary_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChitSummaryView extends GetView<ChitSummaryController> {
  const ChitSummaryView({super.key});

  static const Color _primary = Color(0xFF079B8D);
  static const Color _background = Color(0xFFF6F8F8);
  static const Color _border = Color(0xFFDDECE9);
  static const Color _ink = Color(0xFF263445);
  static const Color _muted = Color(0xFF75828F);

  @override
  Widget build(BuildContext context) {
    final title = _firstValue(controller.chit, ['name', 'chit_name']);
    final organizer = _firstValue(controller.chit, [
      'organizer_name',
      'organizer',
    ]);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Chit summary',
          style: TextStyle(
            fontSize: 19.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Refresh chit summary',
              onPressed: controller.isLoading.value
                  ? null
                  : controller.refreshSummary,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18.r)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final fields = _displayFields(controller.summary);
          return RefreshIndicator(
            color: _primary,
            onRefresh: controller.refreshSummary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
              children: [
                _hero(title: title, organizer: organizer),
                SizedBox(height: 18.h),
                if (controller.isLoading.value && controller.summary.isEmpty)
                  _loadingState()
                else if (controller.loadError.value.isNotEmpty)
                  _errorState(controller.loadError.value)
                else ...[
                  if (fields.isEmpty)
                    _emptyState()
                  else ...[
                    Text(
                      'At a glance',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _summaryGrid(fields),
                  ],
                  SizedBox(height: 22.h),
                  _payoutsSection(),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _hero({required String title, required String organizer}) {
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
              Icons.savings_outlined,
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
                  title.isEmpty ? 'Chit fund' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                if (organizer.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    organizer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 11.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid(List<_SummaryField> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10.w) / 2;
        return Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: [
            for (final field in fields)
              SizedBox(
                width: cardWidth,
                child: Container(
                  constraints: BoxConstraints(minHeight: 94.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF184B44).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                      SizedBox(height: 9.h),
                      Text(
                        field.value,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'HankenGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _payoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Payout history',
                style: TextStyle(
                  color: _ink,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'HankenGrotesk',
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F7F4),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '${controller.payouts.length} records',
                style: TextStyle(
                  color: _primary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (controller.isLoadingPayouts.value && controller.payouts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: _primary),
            ),
          )
        else if (controller.payoutsError.value.isNotEmpty)
          _payoutError(controller.payoutsError.value)
        else if (controller.payouts.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Column(
              children: [
                Icon(Icons.payments_outlined, color: _primary, size: 32),
                SizedBox(height: 8),
                Text('No payouts have been recorded for this chit yet.'),
              ],
            ),
          )
        else
          for (final payout in controller.payouts) _payoutCard(payout),
      ],
    );
  }

  Widget _payoutCard(Map<String, dynamic> payout) {
    final gross = _firstValue(payout, ['gross_amount', 'amount', 'net_amount']);
    final deductions = _firstValue(payout, ['deductions', 'deduction_amount']);
    final status = _firstValue(payout, ['status', 'payout_status']);
    final expected = _firstValue(payout, [
      'expected_date',
      'payout_date',
      'created_at',
    ]);
    final received = _firstValue(payout, ['received_date', 'settled_date']);
    final reference = _firstValue(payout, ['reference', 'payout_reference']);
    final normalizedStatus = status.isEmpty ? 'Pending' : status;
    final isPaid = RegExp(
      r'received|paid|completed|settled',
      caseSensitive: false,
    ).hasMatch(normalizedStatus);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFFE7F7F0)
                      : const Color(0xFFFFF4DD),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isPaid
                      ? Icons.check_circle_outline_rounded
                      : Icons.schedule_rounded,
                  color: isPaid
                      ? const Color(0xFF2E9B65)
                      : const Color(0xFFB78020),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gross.isEmpty ? 'Payout' : '₹${_indianAmount(gross)}',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (reference.isNotEmpty)
                      Text(
                        reference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _muted, fontSize: 10.sp),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFFE7F7F0)
                      : const Color(0xFFFFF4DD),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  normalizedStatus.toUpperCase(),
                  style: TextStyle(
                    color: isPaid
                        ? const Color(0xFF2E9B65)
                        : const Color(0xFFB78020),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (deductions.isNotEmpty ||
              expected.isNotEmpty ||
              received.isNotEmpty) ...[
            SizedBox(height: 12.h),
            const Divider(height: 1, color: _border),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 16.w,
              runSpacing: 7.h,
              children: [
                if (expected.isNotEmpty)
                  _payoutMeta(
                    Icons.event_outlined,
                    'Expected',
                    _formatValue('expected_date', expected),
                  ),
                if (received.isNotEmpty)
                  _payoutMeta(
                    Icons.task_alt_rounded,
                    'Received',
                    _formatValue('received_date', received),
                  ),
                if (deductions.isNotEmpty)
                  _payoutMeta(
                    Icons.remove_circle_outline,
                    'Deductions',
                    '₹${_indianAmount(deductions)}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _payoutMeta(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: _muted),
        SizedBox(width: 5.w),
        Text(
          '$label: ',
          style: TextStyle(color: _muted, fontSize: 10.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: _ink,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _payoutError(String message) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6F4),
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: const Color(0xFFF4D8D2)),
    ),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _ink),
        ),
        TextButton(
          onPressed: controller.fetchPayouts,
          child: const Text('Retry payouts'),
        ),
      ],
    ),
  );

  String _indianAmount(String value) {
    final amount = double.tryParse(value);
    return amount == null ? value : _indianNumber(amount);
  }

  Widget _loadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 50.h),
      child: const Center(child: CircularProgressIndicator(color: _primary)),
    );
  }

  Widget _errorState(String message) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F4),
        border: Border.all(color: const Color(0xFFF4D8D2)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, color: _primary, size: 32.sp),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 12.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 8.h),
          OutlinedButton(
            onPressed: controller.refreshSummary,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 30.h),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, color: _primary, size: 34.sp),
          SizedBox(height: 8.h),
          Text(
            'No summary details available yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  List<_SummaryField> _displayFields(Map<String, dynamic> values) {
    final fields = <_SummaryField>[];
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null || value is Map || value is List) continue;
      final stringValue = value.toString().trim();
      if (stringValue.isEmpty ||
          const {'uuid', 'id', 'chit_uuid'}.contains(entry.key.toLowerCase())) {
        continue;
      }
      fields.add(
        _SummaryField(
          label: _humanize(entry.key),
          value: _formatValue(entry.key, value),
        ),
      );
    }
    return fields;
  }

  String _formatValue(String key, dynamic value) {
    if (value is bool) return value ? 'Yes' : 'No';
    final text = value.toString().trim();
    final amount = double.tryParse(text);
    final isAmountField = RegExp(
      r'amount|value|contribut|paid|balance|payout|prize|saving',
      caseSensitive: false,
    ).hasMatch(key);
    if (isAmountField && amount != null && amount.isFinite) {
      return '₹${_indianNumber(amount)}';
    }
    final parsedDate = DateTime.tryParse(text);
    if (parsedDate != null &&
        (key.toLowerCase().contains('date') ||
            RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text))) {
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
      return '${parsedDate.day} ${months[parsedDate.month - 1]} '
          '${parsedDate.year}';
    }
    return _humanize(text);
  }

  String _indianNumber(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    if (integer.length <= 3) return '$integer.${parts[1]}';
    final lastThree = integer.substring(integer.length - 3);
    var remaining = integer.substring(0, integer.length - 3);
    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) groups.insert(0, remaining);
    return '${groups.join(',')},$lastThree.${parts[1]}';
  }

  String _firstValue(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  String _humanize(String value) => value
      .replaceAll(RegExp(r'([a-z0-9])([A-Z])'), r'$1 $2')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');
}

class _SummaryField {
  const _SummaryField({required this.label, required this.value});

  final String label;
  final String value;
}
