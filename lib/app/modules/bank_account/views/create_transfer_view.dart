import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/widgets/home_widget.dart';
import '../controllers/bank_accounts_controller.dart';
import '../controllers/transfers_controller.dart';

class CreateTransferView extends StatefulWidget {
  const CreateTransferView({super.key});

  @override
  State<CreateTransferView> createState() => _CreateTransferViewState();
}

class _CreateTransferViewState extends State<CreateTransferView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accountsController = Get.find<BankAccountsController>();
  final _transfersController = Get.find<TransfersController>();

  List<BankAccount> _eligibleAccounts = [];
  String? _sourceAccountUuid;
  String? _destinationAccountUuid;
  DateTime _transactionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final initialAccounts = Get.arguments is List<BankAccount>
        ? Get.arguments as List<BankAccount>
        : _accountsController.accounts.toList();
    _setEligibleAccounts(initialAccounts);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _accountsController.fetchAccounts();
      if (!mounted) return;
      setState(
        () => _setEligibleAccounts(_accountsController.accounts.toList()),
      );
    });
  }

  void _setEligibleAccounts(List<BankAccount> accounts) {
    final activeAccounts = accounts.where((account) {
      final uuid = account.uuid?.trim();
      return uuid != null &&
          uuid.isNotEmpty &&
          account.status.toLowerCase() == 'active';
    }).toList();

    final currencyCounts = <String, int>{};
    for (final account in activeAccounts) {
      currencyCounts.update(
        account.currency,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    _eligibleAccounts = activeAccounts
        .where((account) => currencyCounts[account.currency]! > 1)
        .toList();

    _sourceAccountUuid = _eligibleAccounts.isEmpty
        ? null
        : _eligibleAccounts.first.uuid;
    _destinationAccountUuid = _eligibleAccounts.length > 1
        ? _eligibleAccounts[1].uuid
        : null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<BankAccount> get _destinationAccounts {
    final source = _account(_sourceAccountUuid);
    return _eligibleAccounts.where((account) {
      if (account.uuid == _sourceAccountUuid) return false;
      return source == null || account.currency == source.currency;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final canTransfer = _eligibleAccounts.length >= 2;

    return Scaffold(
      backgroundColor: HomeStyle.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBgWhite,
        foregroundColor: HomeStyle.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64.h,
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 17.sp,
            color: HomeStyle.ink,
          ),
        ),
        titleSpacing: 2.w,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ACCOUNTS',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.35,
                color: AppColors.primaryTeal,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'New transfer',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
                color: HomeStyle.ink,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.scaffoldGradient),
        child: canTransfer ? _buildForm() : _notEnoughAccounts(),
      ),
      bottomNavigationBar: canTransfer
          ? SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
                decoration: BoxDecoration(
                  color: AppColors.cardBgWhite,
                  border: Border(top: BorderSide(color: HomeStyle.border)),
                ),
                child: Obx(() {
                  final busy = _transfersController.isCreating.value;
                  return SizedBox(
                    height: 51.h,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primaryTeal
                            .withOpacity(0.45),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      icon: busy
                          ? SizedBox(
                              width: 19.w,
                              height: 19.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.swap_horiz_rounded, size: 20.sp),
                      label: Text(
                        busy ? 'Processing transfer…' : 'Transfer money',
                        style: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            )
          : null,
    );
  }

  Widget _buildForm() {
    final source = _account(_sourceAccountUuid);
    final currency = source?.currency ?? 'INR';

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
      children: [
        Container(
          padding: EdgeInsets.all(15.r),
          decoration: BoxDecoration(
            color: HomeStyle.tealLight,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primaryTeal.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.primaryTeal,
                  size: 23.sp,
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Move money between accounts',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        color: HomeStyle.ink,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Choose accounts in the same currency.',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        color: HomeStyle.muted,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        const SectionTitle(
          title: 'Transfer details',
          subtitle: 'Enter the amount and where it should go',
          icon: Icons.account_balance_wallet_outlined,
        ),
        SizedBox(height: 13.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.cardBgWhite,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: HomeStyle.border),
            boxShadow: [
              BoxShadow(
                color: HomeStyle.ink.withOpacity(0.025),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('TRANSFER AMOUNT', style: _eyebrowStyle),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w800,
                    color: HomeStyle.ink,
                  ),
                  decoration: _fieldDecoration(
                    hint: '0.00',
                    prefix: _currencySymbol(currency),
                  ),
                  validator: _validateAmount,
                ),
                SizedBox(height: 19.h),
                Text('FROM ACCOUNT', style: _eyebrowStyle),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  initialValue: _sourceAccountUuid,
                  isExpanded: true,
                  style: _fieldTextStyle,
                  decoration: _fieldDecoration(
                    hint: 'Select source account',
                    prefixIcon: Icons.account_balance_outlined,
                  ),
                  items: _eligibleAccounts.map(_accountItem).toList(),
                  onChanged: _changeSource,
                  validator: (value) =>
                      value == null ? 'Select a source account' : null,
                ),
                SizedBox(height: 14.h),
                Center(
                  child: Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: HomeStyle.tealLight,
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    child: Icon(
                      Icons.south_rounded,
                      size: 18.sp,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text('TO ACCOUNT', style: _eyebrowStyle),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  initialValue: _destinationAccountUuid,
                  isExpanded: true,
                  style: _fieldTextStyle,
                  decoration: _fieldDecoration(
                    hint: 'Select destination account',
                    prefixIcon: Icons.account_balance_wallet_outlined,
                  ),
                  items: _destinationAccounts.map(_accountItem).toList(),
                  onChanged: (uuid) =>
                      setState(() => _destinationAccountUuid = uuid),
                  validator: (value) =>
                      value == null ? 'Select a destination account' : null,
                ),
                SizedBox(height: 16.h),
                Text('TRANSFER DATE', style: _eyebrowStyle),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(13.r),
                  child: InputDecorator(
                    decoration: _fieldDecoration(
                      hint: 'Choose date',
                      prefixIcon: Icons.calendar_month_outlined,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(_transactionDate),
                            style: _fieldTextStyle,
                          ),
                        ),
                        Icon(
                          Icons.edit_calendar_outlined,
                          size: 18.sp,
                          color: HomeStyle.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text('DESCRIPTION', style: _eyebrowStyle),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 180,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: _fieldTextStyle,
                  decoration: _fieldDecoration(
                    hint: 'e.g. Monthly savings transfer',
                    prefixIcon: Icons.notes_rounded,
                  ).copyWith(counterText: ''),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a description'
                      : null,
                ),
                Obx(
                  () => _transfersController.createError.value.isEmpty
                      ? const SizedBox.shrink()
                      : Container(
                          margin: EdgeInsets.only(top: 12.h),
                          padding: EdgeInsets.all(11.r),
                          decoration: BoxDecoration(
                            color: HomeStyle.redLight,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.expenseRed,
                                size: 17.sp,
                              ),
                              SizedBox(width: 7.w),
                              Expanded(
                                child: Text(
                                  _transfersController.createError.value,
                                  style: TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    color: AppColors.expenseRed,
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
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
        SizedBox(height: 12.h),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14.sp,
              color: HomeStyle.muted,
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                'A transfer moves money between your own accounts.',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  color: HomeStyle.muted,
                  fontSize: 10.5.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  DropdownMenuItem<String> _accountItem(BankAccount account) {
    return DropdownMenuItem<String>(
      value: account.uuid,
      child: Text(
        _accountLabel(account),
        overflow: TextOverflow.ellipsis,
        style: _fieldTextStyle,
      ),
    );
  }

  void _changeSource(String? uuid) {
    setState(() {
      _sourceAccountUuid = uuid;
      if (!_destinationAccounts.any(
        (account) => account.uuid == _destinationAccountUuid,
      )) {
        _destinationAccountUuid = _destinationAccounts.isEmpty
            ? null
            : _destinationAccounts.first.uuid;
      }
    });
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite || amount <= 0) {
      return 'Enter an amount greater than zero';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate.isAfter(now) ? now : _transactionDate,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryTeal,
              surface: AppColors.cardBgWhite,
            ),
            textTheme: Theme.of(
              context,
            ).textTheme.apply(fontFamily: 'HankenGrotesk'),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _transactionDate = picked);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final sourceUuid = _sourceAccountUuid;
    final destinationUuid = _destinationAccountUuid;
    if (sourceUuid == null || destinationUuid == null) return;
    if (sourceUuid == destinationUuid) {
      Get.snackbar(
        'Choose different accounts',
        'Source and destination accounts must be different.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final success = await _transfersController.createTransfer(
      amount: _amountController.text.trim(),
      transactionDate: _transactionDate,
      sourceAccountUuid: sourceUuid,
      destinationAccountUuid: destinationUuid,
      description: _descriptionController.text.trim(),
    );

    if (!success || !mounted) return;
    await _accountsController.fetchAccounts();
    await _transfersController.fetchTransfers();
    if (mounted) Get.back(result: true);
  }

  Widget _notEnoughAccounts() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.cardBgWhite,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: HomeStyle.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: HomeStyle.tealLight,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primaryTeal,
                  size: 25.sp,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Not enough eligible accounts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  color: HomeStyle.ink,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                'Add at least two active accounts with the same currency to make a transfer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  color: HomeStyle.muted,
                  fontSize: 12.sp,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BankAccount? _account(String? uuid) {
    if (uuid == null) return null;
    for (final account in _eligibleAccounts) {
      if (account.uuid == uuid) return account;
    }
    return null;
  }

  String _accountLabel(BankAccount account) {
    final type = account.type.replaceAll('_', ' ');
    return '${account.name} · $type · ${account.currency}';
  }

  static String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  TextStyle get _fieldTextStyle => TextStyle(
    fontFamily: 'HankenGrotesk',
    color: HomeStyle.ink,
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
  );

  TextStyle get _eyebrowStyle => TextStyle(
    fontFamily: 'HankenGrotesk',
    color: HomeStyle.muted,
    fontSize: 9.5.sp,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.85,
  );

  InputDecoration _fieldDecoration({
    required String hint,
    String? prefix,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix == null ? null : '$prefix ',
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: HomeStyle.muted, size: 19.sp),
      hintStyle: TextStyle(
        fontFamily: 'HankenGrotesk',
        color: HomeStyle.muted.withOpacity(0.75),
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: HomeStyle.background,
      contentPadding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13.r),
        borderSide: BorderSide(color: HomeStyle.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13.r),
        borderSide: BorderSide(color: HomeStyle.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13.r),
        borderSide: BorderSide(color: AppColors.primaryTeal, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13.r),
        borderSide: BorderSide(color: AppColors.expenseRed.withOpacity(0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13.r),
        borderSide: BorderSide(color: AppColors.expenseRed, width: 1.4),
      ),
    );
  }
}
