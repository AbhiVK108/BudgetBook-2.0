import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/credit_card_summary_controller.dart';

class CreditCardSummaryView extends GetView<CreditCardSummaryController> {
  const CreditCardSummaryView({super.key});
  static const ink = Color(0xFF263445), muted = Color(0xFF72808C);
  static const line = Color(0xFFDDEAE8);

  static const _visaGradient = LinearGradient(
    colors: [Color(0xFF143D8D), Color(0xFF4B78D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const _mastercardGradient = LinearGradient(
    colors: [Color(0xFF7F1D32), Color(0xFFE76A3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const _rupayGradient = LinearGradient(
    colors: [Color(0xFF4B2A87), Color(0xFF8B62C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const _americanExpressGradient = LinearGradient(
    colors: [Color(0xFF006B78), Color(0xFF36B7C4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const _otherCardGradient = LinearGradient(
    colors: [Color(0xFF1A6862), Color(0xFF42A89D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8F8),
    appBar: AppBar(
      backgroundColor: AppColors.primaryTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 18.w,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credit card details',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          Text(
            'Track spending and payment activity',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
      actions: [
        Obx(
          () => IconButton(
            onPressed: controller.isLoading.value
                ? null
                : controller.refreshData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
    ),
    body: Obx(() {
      if (controller.isLoading.value && controller.summary.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        );
      }
      if (controller.errorMessage.value.isNotEmpty &&
          controller.summary.isEmpty) {
        return _errorState();
      }
      return RefreshIndicator(
        color: AppColors.primaryTeal,
        onRefresh: controller.refreshData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
          children: [
            _hero(),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: FilledButton.icon(
                onPressed: _openPurchaseForm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: Text(
                  'Record a purchase',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            _section('Card overview', _cardOverview()),
            SizedBox(height: 16.h),
            _section('Credit utilization', _utilization()),
            SizedBox(height: 16.h),
            _section('Next payment due', _payment()),
            SizedBox(height: 16.h),
            _section('Recent purchases', _purchases()),
          ],
        ),
      );
    }),
  );
  Future<void> _openPurchaseForm() async {
    await controller.fetchExpenseCategories();
    await Get.bottomSheet<void>(
      _PurchaseFormSheet(controller: controller),
      isScrollControlled: true,
      ignoreSafeArea: false,
      isDismissible: true,
      // enableDrag: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _hero() {
    final name = _value(['name', 'card_name']) ?? 'Credit card';
    final last = _value(['last_four', 'last_four_digits']) ?? '••••';
    final network = _value(['network']);
    final issuer = _value(['issuer', 'provider']) ?? 'Credit card issuer';
    return Container(
      height: 178.h,
      padding: EdgeInsets.fromLTRB(18.w, 17.h, 18.w, 15.h),
      decoration: BoxDecoration(
        gradient: _networkGradient(network),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x241A6862),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35.w,
            top: -55.h,
            child: Container(
              width: 155.w,
              height: 155.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 20,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (network != null)
                    Text(
                      network,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                issuer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 10.sp,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.contactless_outlined,
                color: Colors.white.withValues(alpha: 0.82),
                size: 23.sp,
              ),
              SizedBox(height: 6.h),
              Text(
                '••••  ••••  $last',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardOverview() {
    final limit = _num(['credit_limit', 'limit']);
    final status = _value(['status']);
    final billingDay = _value(['billing_day']);
    final dueDays = _value(['due_days_after_statement']);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _detailMetric(
                'Credit limit',
                'INR ${_money(limit)}',
                Icons.account_balance_wallet_outlined,
              ),
            ),
            Expanded(
              child: _detailMetric(
                'Status',
                status ?? 'Active',
                Icons.verified_outlined,
              ),
            ),
          ],
        ),
        if (billingDay != null || dueDays != null) ...[
          SizedBox(height: 14.h),
          const Divider(height: 1, color: line),
          SizedBox(height: 12.h),
          Row(
            children: [
              if (billingDay != null)
                Expanded(
                  child: _detailMetric(
                    'Billing day',
                    'Day $billingDay',
                    Icons.event_outlined,
                  ),
                ),
              if (dueDays != null)
                Expanded(
                  child: _detailMetric(
                    'Payment window',
                    '$dueDays days',
                    Icons.schedule_outlined,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _detailMetric(String label, String value, IconData icon) => Row(
    children: [
      Icon(icon, color: AppColors.primaryTeal, size: 19.sp),
      SizedBox(width: 8.w),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: muted, fontSize: 10.sp),
            ),
            SizedBox(height: 3.h),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _section(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: ink,
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 8.h),
      Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: line),
        ),
        child: child,
      ),
    ],
  );
  Widget _utilization() {
    final limit = _num(['credit_limit', 'limit']);
    final used = _num([
      'used_amount',
      'used_credit',
      'outstanding',
      'current_balance',
    ]);
    final currency = _value(['currency']) ?? 'INR';
    final available = (limit - used).clamp(0.0, double.infinity);
    final ratio = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$currency ${_money(used)} used',
                style: TextStyle(
                  color: ink,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(ratio * 100).toStringAsFixed(0)}% used',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            minHeight: 9.h,
            value: ratio,
            backgroundColor: const Color(0xFFE8F2F1),
            color: AppColors.primaryTeal,
          ),
        ),
        SizedBox(height: 12.h),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Available credit  $currency ${_money(available)}',
            style: TextStyle(color: muted, fontSize: 11.sp),
          ),
        ),
      ],
    );
  }

  Widget _payment() => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(
      Icons.event_available_outlined,
      color: Color(0xFFE27B35),
    ),
    title: Text(
      _value(['next_payment_due_date', 'payment_due_date']) ?? 'Not available',
    ),
    subtitle: Text(
      'Amount due  INR ${_num(['next_payment_amount', 'payment_due', 'minimum_payment']).toStringAsFixed(2)}',
    ),
  );
  Widget _purchases() {
    if (controller.isTransactionsLoading.value &&
        controller.transactions.isEmpty) {
      return const _TransactionState(
        icon: Icons.sync_rounded,
        message: 'Loading your latest transactions…',
        showProgress: true,
      );
    }
    if (controller.transactionsErrorMessage.value.isNotEmpty &&
        controller.transactions.isEmpty) {
      return _TransactionState(
        icon: Icons.cloud_off_outlined,
        message: controller.transactionsErrorMessage.value,
        action: TextButton.icon(
          onPressed: controller.fetchTransactions,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    final items = controller.transactions.take(5).toList();
    if (items.isEmpty) {
      return const _TransactionState(
        icon: Icons.receipt_long_outlined,
        message: 'No transactions recorded for this card yet.',
      );
    }
    return Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primaryTeal,
            ),
            title: Text(
              (item['merchant_name'] ??
                      item['merchant'] ??
                      item['description'] ??
                      'Purchase')
                  .toString(),
            ),
            subtitle: Text(_transactionDate(item)),
            trailing: Text(
              _transactionAmount(item),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _isCredit(item) ? Colors.green[700] : ink,
              ),
            ),
          ),
        if (controller.transactions.length > items.length)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                '+${controller.transactions.length - items.length} more transactions',
                style: const TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _transactionDate(Map<String, dynamic> item) {
    final raw =
        (item['date'] ??
                item['transaction_date'] ??
                item['posted_at'] ??
                item['created_at'])
            ?.toString();
    if (raw == null || raw.trim().isEmpty) return 'Date unavailable';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _transactionAmount(Map<String, dynamic> item) {
    final amount = double.tryParse((item['amount'] ?? 0).toString()) ?? 0;
    final sign = _isCredit(item) ? '+' : '-';
    return '$sign INR ${amount.abs().toStringAsFixed(2)}';
  }

  bool _isCredit(Map<String, dynamic> item) {
    final kind = (item['kind'] ?? item['transaction_type'] ?? item['type'])
        ?.toString()
        .toLowerCase();
    return kind == 'refund' || kind == 'payment' || kind == 'credit';
  }

  Widget _errorState() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: EdgeInsets.fromLTRB(24.w, 90.h, 24.w, 24.h),
    children: [
      Icon(Icons.cloud_off_outlined, color: AppColors.primaryTeal, size: 46.sp),
      SizedBox(height: 14.h),
      Text(
        controller.errorMessage.value,
        textAlign: TextAlign.center,
        style: TextStyle(color: ink, fontSize: 13.sp),
      ),
      SizedBox(height: 14.h),
      Center(
        child: OutlinedButton.icon(
          onPressed: controller.refreshData,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryTeal,
            side: const BorderSide(color: AppColors.primaryTeal),
          ),
        ),
      ),
    ],
  );

  LinearGradient _networkGradient(String? network) {
    final normalized = (network ?? '').toLowerCase().trim();
    if (normalized.contains('visa')) return _visaGradient;
    if (normalized.contains('master')) return _mastercardGradient;
    if (normalized.contains('rupay')) return _rupayGradient;
    if (normalized.contains('american') || normalized.contains('amex')) {
      return _americanExpressGradient;
    }
    return _otherCardGradient;
  }

  String? _value(List<String> keys) {
    final maps = [controller.summary, controller.card];
    for (final map in maps) {
      for (final key in keys) {
        final value = map[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  double _num(List<String> keys) => double.tryParse(_value(keys) ?? '') ?? 0;

  String _money(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$grouped.${parts.last}';
  }
}

class _TransactionState extends StatelessWidget {
  const _TransactionState({
    required this.icon,
    required this.message,
    this.action,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final Widget? action;
  final bool showProgress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        Icon(icon, color: CreditCardSummaryView.muted, size: 26),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: CreditCardSummaryView.muted),
        ),
        if (showProgress) ...[
          const SizedBox(height: 12),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
        action ?? const SizedBox.shrink(),
      ],
    ),
  );
}

class _PurchaseFormSheet extends StatefulWidget {
  const _PurchaseFormSheet({required this.controller});
  final CreditCardSummaryController controller;
  @override
  State<_PurchaseFormSheet> createState() => _PurchaseFormSheetState();
}

class _PurchaseFormSheetState extends State<_PurchaseFormSheet> {
  final key = GlobalKey<FormState>();
  final amount = TextEditingController();
  final description = TextEditingController();
  final reference = TextEditingController();
  final notes = TextEditingController();
  String date = _format(DateTime.now());
  String? category;
  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    reference.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42.w,
                    height: 4.h,
                    color: const Color(0xFFD8E2E1),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Record a purchase',
                  style: TextStyle(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Keep your card balance up to date.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Purchase amount',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) => (double.tryParse(v?.trim() ?? '') ?? 0) <= 0
                      ? 'Enter a valid amount'
                      : null,
                ),
                SizedBox(height: 14.h),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Expense category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: widget.controller.expenseCategories.map((c) {
                    final id = (c['uuid'] ?? c['category_uuid']).toString();
                    return DropdownMenuItem(
                      value: id,
                      child: Text(
                        (c['name'] ?? c['category_name'] ?? 'Category')
                            .toString(),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => category = v),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Transaction date'),
                  subtitle: Text(date),
                  onTap: _pickDate,
                ),
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                TextFormField(
                  controller: reference,
                  decoration: const InputDecoration(
                    labelText: 'Reference (optional)',
                  ),
                ),
                TextFormField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                SizedBox(height: 20.h),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: FilledButton.icon(
                      onPressed: widget.controller.isPostingPurchase.value
                          ? null
                          : _submit,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        widget.controller.isPostingPurchase.value
                            ? 'Saving purchase...'
                            : 'Save purchase',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => date = _format(picked));
  }

  Future<void> _submit() async {
    if (!(key.currentState?.validate() ?? false)) return;
    final posted = await widget.controller.postPurchase(
      amount: amount.text.trim(),
      transactionDate: date,
      categoryUuid: category!,
      description: description.text,
      reference: reference.text,
      notes: notes.text,
    );
    if (posted && mounted) Get.back();
  }
}
