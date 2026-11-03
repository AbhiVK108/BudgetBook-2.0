import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_pages.dart';
import '../controllers/credit_card_summary_controller.dart';
import '../controllers/credit_cards_controller.dart';
import 'credit_card_summary_view.dart';

class CreditCardsView extends StatefulWidget {
  const CreditCardsView({super.key});

  @override
  State<CreditCardsView> createState() => _CreditCardsViewState();
}

class _CreditCardsViewState extends State<CreditCardsView>
    with SingleTickerProviderStateMixin {
  late final TabController _categoryTabController;

  CreditCardsController get controller => Get.find<CreditCardsController>();

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _categoryTabController.dispose();
    super.dispose();
  }

  static const _pageBackground = Color(0xFFF4F8F8);
  static const _ink = Color(0xFF1D2B35);
  static const _muted = Color(0xFF71808E);
  static const _line = Color(0xFFDDEAE8);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 18.w,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Credit cards', style: _appBarTitle()),
            Text('Your cards, all in one place', style: _appBarSubtitle()),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export credit-card report as PDF',
            onPressed: controller.isReportLoading.value
                ? null
                : controller.exportCreditCardsReportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          Obx(
            () => IconButton(
              tooltip: 'Refresh credit cards',
              onPressed: controller.isLoading.value
                  ? null
                  : controller.fetchCreditCards,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          SizedBox(width: 6.w),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 5,
        onPressed: _openAddCard,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add card', style: _bodyStyle(fontWeight: FontWeight.w700)),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.cards.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          );
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.cards.isEmpty) {
          return _messageState(
            icon: Icons.cloud_off_outlined,
            message: controller.errorMessage.value,
            action: controller.fetchCreditCards,
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryTeal,
          onRefresh: controller.fetchCreditCards,
          child: controller.cards.isEmpty
              ? _messageState(
                  icon: Icons.credit_card_outlined,
                  message: 'No credit cards yet.',
                  action: _openAddCard,
                  actionLabel: 'Add credit card',
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 112.h),
                  children: [
                    _portfolioHeader(),
                    SizedBox(height: 24.h),
                    _categoryTabs(),
                    SizedBox(height: 24.h),
                  ],
                ),
        );
      }),
    );
  }

  Widget _categoryTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2F1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: TabBar(
            controller: _categoryTabController,
            labelColor: Colors.white,
            unselectedLabelColor: _muted,
            labelStyle: _smallStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: _smallStyle(fontWeight: FontWeight.w600),
            indicator: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(10.r),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Obx(
                  () => _statementTabLabel('Cards', controller.cards.length),
                ),
              ),
              Tab(
                child: Obx(
                  () => _statementTabLabel(
                    'Overdues',
                    controller.overdueStatements.length,
                    overdue: true,
                  ),
                ),
              ),
              Tab(
                child: Obx(
                  () => _statementTabLabel(
                    'Upcoming \npayments',
                    controller.upcomingStatements.length,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        AnimatedBuilder(
          animation: _categoryTabController,
          builder: (context, child) {
            switch (_categoryTabController.index) {
              case 1:
                return _overdueStatementsPanel();
              case 2:
                return _upcomingStatementsPanel();
              default:
                return _cardsPanel();
            }
          },
        ),
      ],
    );
  }

  Widget _cardsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Your cards', style: _sectionTitle()),
            const Spacer(),
            Text(
              '${controller.cards.length} ${controller.cards.length == 1 ? 'card' : 'cards'}',
              style: _smallStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        for (var index = 0; index < controller.cards.length; index++) ...[
          _card(controller.cards[index]),
          if (index != controller.cards.length - 1) SizedBox(height: 14.h),
        ],
      ],
    );
  }

  Widget _statementTabLabel(String label, int count, {bool overdue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (count > 0) ...[
          SizedBox(width: 5.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: overdue ? const Color(0xFFFFE3DD) : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '$count',
              style: _smallStyle(
                color: overdue
                    ? const Color(0xFFD65D45)
                    : AppColors.primaryTeal,
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _upcomingStatementsPanel() {
    final statements = controller.upcomingStatements;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Upcoming payments', style: _sectionTitle()),
            const Spacer(),
            Obx(
              () => IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Refresh upcoming payments',
                onPressed: controller.isStatementsLoading.value
                    ? null
                    : controller.fetchUpcomingStatements,
                icon: Icon(Icons.refresh_rounded, size: 18.sp),
              ),
            ),
          ],
        ),
        Obx(() {
          if (controller.isStatementsLoading.value && statements.isEmpty) {
            return _statementLoadingCard();
          }
          if (controller.statementsErrorMessage.value.isNotEmpty &&
              statements.isEmpty) {
            return _statementMessageCard(
              controller.statementsErrorMessage.value,
              controller.fetchUpcomingStatements,
            );
          }
          if (statements.isEmpty) return _statementEmptyCard();
          final visible = statements.take(3).toList();
          return Column(
            children: [
              for (var index = 0; index < visible.length; index++) ...[
                _statementCard(visible[index]),
                if (index != visible.length - 1) SizedBox(height: 10.h),
              ],
              if (statements.length > 3)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    '+ ${statements.length - 3} more upcoming payments',
                    style: _smallStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _overdueStatementsPanel() {
    final statements = controller.overdueStatements;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Overdue payments', style: _sectionTitle()),
            const Spacer(),
            Obx(
              () => IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Refresh overdue payments',
                onPressed: controller.isOverdueStatementsLoading.value
                    ? null
                    : controller.fetchOverdueStatements,
                icon: Icon(Icons.refresh_rounded, size: 18.sp),
              ),
            ),
          ],
        ),
        Obx(() {
          if (controller.isOverdueStatementsLoading.value &&
              statements.isEmpty) {
            return _statementMessageCard(
              'Checking for overdue payments...',
              null,
              showLoader: true,
              danger: true,
            );
          }
          if (controller.overdueStatementsErrorMessage.value.isNotEmpty &&
              statements.isEmpty) {
            return _statementMessageCard(
              controller.overdueStatementsErrorMessage.value,
              controller.fetchOverdueStatements,
              danger: true,
            );
          }
          if (statements.isEmpty) {
            return _statementMessageCard(
              'You are all caught up. No overdue payments.',
              null,
              icon: Icons.verified_outlined,
            );
          }
          final visible = statements.take(3).toList();
          return Column(
            children: [
              for (var index = 0; index < visible.length; index++) ...[
                _statementCard(visible[index], overdue: true),
                if (index != visible.length - 1) SizedBox(height: 10.h),
              ],
              if (statements.length > 3)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    '+ ${statements.length - 3} more overdue payments',
                    style: _smallStyle(
                      color: const Color(0xFFD65D45),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _statementCard(
    Map<String, dynamic> statement, {
    bool overdue = false,
  }) {
    final cardName =
        _value(statement, ['card_name', 'credit_card_name', 'name', 'card']) ??
        'Credit card';
    final lastFour = _value(statement, ['last_four', 'last_four_digits']);
    final dueDate = _value(statement, [
      'payment_due_date',
      'due_date',
      'payment_date',
      'due_on',
    ]);
    final amount = _number(
      _value(statement, [
        'total_amount',
        'statement_amount',
        'amount',
        'total_due',
        'payment_due',
      ]),
    );
    final minimumDue = _number(
      _value(statement, ['minimum_due', 'minimum_amount_due', 'min_due']),
    );
    final currency = _value(statement, ['currency']) ?? 'INR';
    final days = _daysUntil(dueDate);
    final urgent = overdue || (days != null && days <= 3);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: urgent ? const Color(0xFFFFD9D1) : _line),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: (urgent
                  ? const Color(0xFFFFF0ED)
                  : const Color(0xFFE8F6F3)),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(
              urgent ? Icons.priority_high_rounded : Icons.event_note_outlined,
              color: urgent ? const Color(0xFFD65D45) : AppColors.primaryTeal,
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardName + (lastFour == null ? '' : ' •••• $lastFour'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4.h),
                Text(
                  overdue
                      ? _overdueLabel(dueDate, statement)
                      : _dueLabel(dueDate, days),
                  style: _smallStyle(
                    color: urgent ? const Color(0xFFD65D45) : _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (minimumDue > 0) ...[
                  SizedBox(height: 3.h),
                  Text(
                    'Min. due $currency ${_money(minimumDue)}',
                    style: _smallStyle(fontSize: 10.sp),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '$currency\n${_money(amount)}',
            textAlign: TextAlign.right,
            style: _bodyStyle(
              color: AppColors.primaryTeal,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statementLoadingCard() => _statementMessageCard(
    'Checking your upcoming payment dates...',
    null,
    showLoader: true,
  );

  Widget _statementEmptyCard() =>
      _statementMessageCard('You have no upcoming credit card payments.', null);

  Widget _statementMessageCard(
    String message,
    Future<void> Function()? action, {
    bool showLoader = false,
    bool danger = false,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: danger ? const Color(0xFFFFD9D1) : _line),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.primaryTeal, size: 20.sp),
            SizedBox(width: 10.w),
          ],
          if (showLoader) ...[
            SizedBox(
              width: 18.sp,
              height: 18.sp,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryTeal,
              ),
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(child: Text(message, style: _smallStyle())),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _overdueLabel(String? value, Map<String, dynamic> statement) {
    final days = _number(_value(statement, ['days_overdue', 'overdue_days']));
    if (days > 0) {
      return '${days.round()} ${days == 1 ? 'day' : 'days'} overdue';
    }
    if (value == null) return 'Payment date unavailable';
    final date = DateTime.tryParse(value);
    if (date == null) return 'Overdue since $value';
    return 'Overdue since ${date.day}/${date.month}/${date.year}';
  }

  int? _daysUntil(String? value) {
    if (value == null) return null;
    final date = DateTime.tryParse(value);
    if (date == null) return null;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return date.difference(start).inDays;
  }

  String _dueLabel(String? value, int? days) {
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days != null && days > 1 && days < 8) return 'Due in $days days';
    if (value == null) return 'Payment date unavailable';
    final date = DateTime.tryParse(value);
    if (date == null) return 'Due $value';
    return 'Due ${date.day}/${date.month}/${date.year}';
  }

  Future<void> _openAddCard() async {
    final result = await Get.toNamed(
      Routes.ADD_BANK_ACCOUNT,
      arguments: {'accountType': 'credit_card'},
    );
    if (result != null) await controller.fetchCreditCards();
  }

  Widget _portfolioHeader() {
    final totals = controller.reportTotals.isNotEmpty
        ? controller.reportTotals.first
        : const <String, dynamic>{};
    final totalLimit = _number(totals['credit_limit']);
    final currency = totals['currency']?.toString() ?? _currencyForCards();
    final cardCount = controller.reportCardCount.value > 0
        ? controller.reportCardCount.value
        : controller.cards.length;

    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 17.h),
      decoration: BoxDecoration(
        gradient: AppColors.bannerGradient,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261A9E91),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
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
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 11.w),
              Text(
                'Credit overview',
                style: _lightStyle(alpha: 0.82, fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text('Total credit limit', style: _lightStyle(alpha: 0.78)),
          SizedBox(height: 3.h),
          Text(
            '$currency ${_money(totalLimit)}',
            style: _lightStyle(fontSize: 26.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 15.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 16.sp,
                ),
                SizedBox(width: 7.w),
                Text(
                  '$cardCount active ${cardCount == 1 ? 'card' : 'cards'}',
                  style: _lightStyle(alpha: 0.9, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSummary(Map<String, dynamic> card) async {
    final uuid = _uuid(card);
    if (uuid == null) return;
    await Get.to(
      () => const CreditCardSummaryView(),
      binding: BindingsBuilder(() {
        Get.put(CreditCardSummaryController(cardUuid: uuid, card: card));
      }),
    );
  }

  String? _uuid(Map<String, dynamic> card) =>
      _value(card, ['uuid', 'credit_card_uuid', 'id']);

  Widget _card(Map<String, dynamic> card) {
    final name = _value(card, ['name', 'card_name']) ?? 'Credit card';
    final issuer = _value(card, ['issuer', 'provider', 'institution']);
    final network = _value(card, ['network']);
    final lastFour = _value(card, ['last_four', 'last_four_digits']);
    final limit = _value(card, ['credit_limit', 'limit']);
    final currency = _value(card, ['currency']) ?? 'INR';
    final status = _value(card, ['status']);
    final billingDay = _value(card, ['billing_day']);
    final dueDays = _value(card, ['due_days_after_statement']);

    return InkWell(
      onTap: _uuid(card) == null ? null : () => _openSummary(card),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: _line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101A6862),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _visualCard(
              name: name,
              issuer: issuer,
              network: network,
              lastFour: lastFour,
              gradient: _networkGradient(network),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 15.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          'Credit limit',
                          limit == null
                              ? '--'
                              : '$currency ${_money(_number(limit))}',
                          emphasized: true,
                        ),
                      ),
                      if (status != null) _status(status),
                    ],
                  ),
                  if (billingDay != null || dueDays != null) ...[
                    SizedBox(height: 13.h),
                    const Divider(height: 1, color: _line),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        if (billingDay != null)
                          Expanded(
                            child: _detail(
                              Icons.event_outlined,
                              'Bills on day $billingDay',
                            ),
                          ),
                        if (dueDays != null)
                          Expanded(
                            child: _detail(
                              Icons.schedule_outlined,
                              '$dueDays days to pay',
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visualCard({
    required String name,
    String? issuer,
    String? network,
    String? lastFour,
    required LinearGradient gradient,
  }) {
    return Container(
      height: 150.h,
      padding: EdgeInsets.fromLTRB(17.w, 15.h, 17.w, 14.h),
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned(
            right: -28.w,
            top: -45.h,
            child: Container(
              width: 150.w,
              height: 150.w,
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
                      style: _lightStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (network != null)
                    Text(
                      network,
                      style: _lightStyle(
                        alpha: 0.86,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                issuer ?? 'Credit card issuer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _lightStyle(alpha: 0.72, fontSize: 10.sp),
              ),
              const Spacer(),
              Icon(
                Icons.contactless_outlined,
                color: Colors.white.withValues(alpha: 0.82),
                size: 22.sp,
              ),
              SizedBox(height: 6.h),
              Text(
                lastFour == null ? '••••  ••••  ••••' : '••••  ••••  $lastFour',
                style: _lightStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  Widget _metric(String label, String value, {bool emphasized = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: _labelStyle()),
        SizedBox(height: 4.h),
        Text(
          value,
          style: _bodyStyle(
            color: emphasized ? AppColors.primaryTeal : _ink,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 15.sp),
        SizedBox(width: 5.w),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: _smallStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _status(String value) {
    final inactive = {
      'inactive',
      'cancelled',
      'closed',
    }.contains(value.toLowerCase());
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: inactive ? const Color(0xFFF1F3F4) : const Color(0xFFE9F7F4),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        value,
        style: _smallStyle(
          color: inactive ? _muted : AppColors.iconTeal,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String message,
    required Future<void> Function() action,
    String actionLabel = 'Retry',
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24.w, 80.h, 24.w, 24.h),
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 44.sp),
        SizedBox(height: 14.h),
        Text(
          message,
          textAlign: TextAlign.center,
          style: _bodyStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 14.h),
        Center(
          child: OutlinedButton(
            onPressed: action,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: const BorderSide(color: AppColors.primaryTeal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }

  TextStyle _appBarTitle() => _bodyStyle(
    color: Colors.white,
    fontSize: 19.sp,
    fontWeight: FontWeight.w700,
  );

  TextStyle _appBarSubtitle() => _bodyStyle(
    color: Colors.white.withValues(alpha: 0.72),
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
  );

  TextStyle _sectionTitle() =>
      _bodyStyle(color: _ink, fontSize: 17.sp, fontWeight: FontWeight.w700);

  TextStyle _labelStyle() =>
      _smallStyle(fontSize: 9.sp, fontWeight: FontWeight.w700);

  TextStyle _smallStyle({
    Color color = _muted,
    double? fontSize,
    FontWeight? fontWeight,
  }) => _bodyStyle(
    color: color,
    fontSize: fontSize ?? 11.sp,
    fontWeight: fontWeight ?? FontWeight.w500,
  );

  TextStyle _bodyStyle({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => TextStyle(
    color: color ?? _ink,
    fontFamily: 'HankenGrotesk',
    fontSize: fontSize ?? 13.sp,
    fontWeight: fontWeight ?? FontWeight.w500,
    letterSpacing: letterSpacing,
  );

  TextStyle _lightStyle({
    double alpha = 1,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => _bodyStyle(
    color: Colors.white.withValues(alpha: alpha),
    fontSize: fontSize ?? 11.sp,
    fontWeight: fontWeight ?? FontWeight.w500,
    letterSpacing: letterSpacing,
  );

  String? _value(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  double _number(String? value) => double.tryParse(value ?? '') ?? 0;

  String _currencyForCards() {
    for (final card in controller.cards) {
      final currency = _value(card, ['currency']);
      if (currency != null) return currency;
    }
    return 'INR';
  }

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
