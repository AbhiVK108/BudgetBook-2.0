import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/widgets/home_widget.dart';
import '../../../routes/app_pages.dart';
import '../controllers/bank_accounts_controller.dart';
import '../controllers/transfers_controller.dart';
import 'transfers_section.dart';

class BankAccountsView extends GetView<BankAccountsController> {
  const BankAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.cardBgWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 66.h,
        leadingWidth: 48.w,
        leading: IconButton(
          onPressed: () {
            if (Get.key.currentState?.canPop() ?? false) Get.back();
          },
          splashRadius: 22.r,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: HomeStyle.ink,
            size: 21.sp,
          ),
        ),
        titleSpacing: 3.w,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
              'My Accounts',
              style: TextStyle(
                color: HomeStyle.ink,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                fontFamily: 'HankenGrotesk',
              ),
            ),
          ],
        ),
        actions: [
          Obx(
            () => Padding(
              padding: EdgeInsets.only(right: 14.w),
              child: Center(
                child: Material(
                  color: HomeStyle.tealLight,
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    onTap:
                        controller.isLoading.value ||
                            Get.find<TransfersController>().isLoading.value
                        ? null
                        : _refreshAll,
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primaryTeal,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.accounts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          );
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.accounts.isEmpty) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.scaffoldGradient,
            ),
            child: _errorState(),
          );
        }

        return Container(
          decoration: const BoxDecoration(gradient: AppColors.scaffoldGradient),
          child: RefreshIndicator(
            color: AppColors.primaryTeal,
            onRefresh: _refreshAll,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final transfersController = Get.find<TransfersController>();

                if (notification.metrics.extentAfter < 240 &&
                    transfersController.hasMore) {
                  transfersController.loadNextPage();
                }

                return false;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
                children: [
                  _summaryCard(),
                  SizedBox(height: 18.h),
                  _buildAddAccountButtons(),
                  SizedBox(height: 24.h),
                  SectionTitle(
                    title: 'Your accounts',
                    subtitle: 'Manage your bank and cash balances',
                  ),
                  SizedBox(height: 13.h),
                  _buildAccountFilters(),
                  SizedBox(height: 18.h),
                  Row(
                    children: [
                      Text(
                        _selectedFilterLabel,
                        style: TextStyle(
                          color: AppColors.iconTeal,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${controller.filteredAccounts.length} total',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (controller.errorMessage.value.isNotEmpty) ...[
                    _inlineError(),
                    SizedBox(height: 10.h),
                  ],
                  if (controller.filteredAccounts.isEmpty)
                    _filterEmptyState()
                  else
                    ...controller.filteredAccounts.map(
                      (account) => Padding(
                        padding: EdgeInsets.only(bottom: 11.h),
                        child: _accountCard(account),
                      ),
                    ),
                  SizedBox(height: 24.h),
                  const TransfersSection(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      controller.fetchAccounts(),
      Get.find<TransfersController>().fetchTransfers(),
    ]);
  }

  String get _selectedFilterLabel {
    switch (controller.selectedAccountFilter.value) {
      case 'bank':
        return 'Bank accounts';
      case 'cash':
        return 'Cash accounts';
      default:
        return 'All accounts';
    }
  }

  Widget _buildAddAccountButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.openAddAccount(accountType: 'bank'),
            icon: Icon(Icons.account_balance_outlined, size: 19.r),
            label: Text(
              'Add bank',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: BorderSide(
                color: AppColors.primaryTeal.withValues(alpha: 0.55),
              ),
              backgroundColor: AppColors.cardBgWhite,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => controller.openAddAccount(accountType: 'cash'),
            icon: Icon(Icons.account_balance_wallet_outlined, size: 19.r),
            label: Text(
              'Add cash',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountFilters() {
    const filters = [('all', 'All'), ('bank', 'Bank'), ('cash', 'Cash')];

    return Obx(
      () => Row(
        children: filters.map((filter) {
          final selected = controller.selectedAccountFilter.value == filter.$1;

          final count = switch (filter.$1) {
            'bank' =>
              controller.accounts
                  .where((account) => account.type.toLowerCase() == 'bank')
                  .length,
            'cash' =>
              controller.accounts
                  .where((account) => account.type.toLowerCase() == 'cash')
                  .length,
            _ => controller.accounts.length,
          };

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: filter.$1 == 'cash' ? 0 : 8.w),
              child: ChoiceChip(
                label: Center(child: Text('${filter.$2} ($count)')),
                selected: selected,
                onSelected: (_) {
                  controller.selectedAccountFilter.value = filter.$1;
                },
                selectedColor: AppColors.primaryTeal.withValues(alpha: 0.10),
                backgroundColor: AppColors.cardBgWhite,
                labelStyle: TextStyle(
                  color: selected ? AppColors.iconTeal : HomeStyle.muted,
                  fontSize: 12.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'HankenGrotesk',
                ),
                side: BorderSide(
                  color: selected
                      ? AppColors.primaryTeal.withValues(alpha: 0.65)
                      : HomeStyle.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
                showCheckmark: false,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _summaryCard() {
    final accounts = controller.filteredAccounts;

    final total = accounts.fold<double>(
      0,
      (sum, account) => sum + (double.tryParse(account.balance) ?? 0),
    );

    final accountKind = switch (controller.selectedAccountFilter.value) {
      'bank' => 'bank',
      'cash' => 'cash',
      _ => '',
    };

    final countLabel = accountKind.isEmpty
        ? '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}'
        : '${accounts.length} $accountKind ${accounts.length == 1 ? 'account' : 'accounts'}';

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(color: HomeStyle.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: HomeStyle.tealLight,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primaryTeal,
                  size: 19.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'TOTAL ACCOUNT BALANCE',
                  style: TextStyle(
                    color: HomeStyle.muted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: HomeStyle.background,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  countLabel,
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: TextStyle(
              color: HomeStyle.ink,
              fontSize: 27.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Combined balance across your selected accounts',
            style: TextStyle(
              color: HomeStyle.muted,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'HankenGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterEmptyState() {
    final filter = controller.selectedAccountFilter.value;

    final message = filter == 'bank'
        ? 'No bank accounts yet.'
        : filter == 'cash'
        ? 'No cash accounts yet.'
        : 'No accounts yet.';

    final description = filter == 'bank'
        ? 'Add a bank account to keep track of your balance.'
        : filter == 'cash'
        ? 'Add a cash account to track your available money.'
        : 'Start by adding your first bank or cash account.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      decoration: BoxDecoration(
        color: AppColors.cardBgWhite,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: HomeStyle.border),
      ),
      child: Column(
        children: [
          Container(
            width: 54.r,
            height: 54.r,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primaryTeal,
              size: 26.r,
            ),
          ),
          SizedBox(height: 13.h),
          Text(
            message,
            style: TextStyle(
              color: AppColors.iconTeal,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _accountCard(BankAccount account) {
    final isBank = account.type.toLowerCase() == 'bank';
    final isActive = account.status.toLowerCase() == 'active';

    return Material(
      color: AppColors.cardBgWhite,
      borderRadius: BorderRadius.circular(15.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.r),
        onTap: () =>
            Get.toNamed(Routes.accountTransactions, arguments: account),
        child: Container(
          padding: EdgeInsets.all(15.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: HomeStyle.border, width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: Icon(
                      isBank
                          ? Icons.account_balance_rounded
                          : Icons.account_balance_wallet_rounded,
                      color: AppColors.primaryTeal,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 11.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: HomeStyle.ink,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'HankenGrotesk',
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          account.institution ?? _titleCase(account.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: HomeStyle.muted,
                            fontSize: 10.5.sp,
                            fontFamily: 'HankenGrotesk',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.incomeGreen.withValues(alpha: 0.10)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      _titleCase(account.status),
                      style: TextStyle(
                        color: isActive
                            ? AppColors.incomeGreen
                            : HomeStyle.muted,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  IconButton(
                    tooltip: 'Edit ${account.name}',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: 32.r,
                      height: 32.r,
                    ),
                    onPressed: account.uuid == null
                        ? null
                        : () => _editAccount(account),
                    icon: Icon(Icons.edit_outlined, size: 18.r),
                    color: AppColors.primaryTeal,
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 13.h),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.cardBg,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Available balance',
                    style: TextStyle(
                      color: HomeStyle.muted,
                      fontSize: 10.5.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_currencySymbol(account.currency)}${_formatAmount(account.balance)}',
                        style: TextStyle(
                          color: HomeStyle.ink,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'HankenGrotesk',
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
  }

  Future<void> _editAccount(BankAccount account) async {
    await Get.dialog<void>(
      _EditBankAccountDialog(account: account, controller: controller),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42.r, color: Colors.black45),
            SizedBox(height: 12.h),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13.sp),
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: controller.fetchAccounts,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineError() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.expenseRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.expenseRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.expenseRed,
            size: 18.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              controller.errorMessage.value,
              style: TextStyle(color: AppColors.iconRed, fontSize: 11.sp),
            ),
          ),
          TextButton(
            onPressed: controller.fetchAccounts,
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '$currency ';
    }
  }

  String _formatAmount(String amount) {
    final parsed = double.tryParse(amount);
    return parsed?.toStringAsFixed(2) ?? amount;
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}

class _EditBankAccountDialog extends StatefulWidget {
  const _EditBankAccountDialog({
    required this.account,
    required this.controller,
  });

  final BankAccount account;
  final BankAccountsController controller;

  @override
  State<_EditBankAccountDialog> createState() => _EditBankAccountDialogState();
}

class _EditBankAccountDialogState extends State<_EditBankAccountDialog> {
  static const _accountTypes = {
    'bank': 'Bank Account',
    'cash': 'Cash Account',
    'wallet': 'Digital Wallet',
    'credit_card': 'Credit Card',
  };

  late final TextEditingController _nameController;
  late final TextEditingController _institutionController;
  late final TextEditingController _notesController;

  final _formKey = GlobalKey<FormState>();

  late String _selectedType;
  late String _selectedCurrency;
  late bool _allowNegative;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.account.name);
    _institutionController = TextEditingController(
      text: widget.account.institution ?? '',
    );
    _notesController = TextEditingController(text: widget.account.notes ?? '');

    _selectedType = widget.account.type;
    _selectedCurrency = widget.account.currency;
    _allowNegative = widget.account.allowNegative;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountTypes = Map<String, String>.from(_accountTypes)
      ..putIfAbsent(_selectedType, () => _titleCase(_selectedType));

    return AlertDialog(
      backgroundColor: AppColors.cardBgWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text(
        'Edit account',
        style: TextStyle(
          color: HomeStyle.ink,
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          fontFamily: 'HankenGrotesk',
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Account name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter an account name'
                    : null,
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Account type'),
                items: accountTypes.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _institutionController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Institution'),
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: {'INR', 'USD', 'EUR', 'GBP', widget.account.currency}
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCurrency = value);
                  }
                },
              ),
              SizedBox(height: 8.h),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Allow negative balance',
                  style: TextStyle(
                    color: HomeStyle.ink,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                value: _allowNegative,
                activeTrackColor: AppColors.primaryTeal,
                onChanged: (value) {
                  setState(() => _allowNegative = value);
                },
              ),
              TextFormField(
                controller: _notesController,
                maxLength: 180,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Obx(
          () => TextButton(
            onPressed: widget.controller.isUpdating.value
                ? null
                : () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: HomeStyle.muted),
            ),
          ),
        ),
        Obx(
          () => FilledButton(
            onPressed: widget.controller.isUpdating.value ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: widget.controller.isUpdating.value
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save changes'),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = await widget.controller.updateAccount(
      widget.account,
      name: _nameController.text,
      type: _selectedType,
      institution: _institutionController.text,
      currency: _selectedCurrency,
      allowNegative: _allowNegative,
      notes: _notesController.text,
    );

    if (updated && mounted) {
      Get.back();
    }
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;

    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}
