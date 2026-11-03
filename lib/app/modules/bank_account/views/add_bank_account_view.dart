import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AddBankAccountView extends StatefulWidget {
  const AddBankAccountView({
    super.key,
    this.apiService,
    this.initialAccountType,
  });

  final ApiService? apiService;
  final String? initialAccountType;

  @override
  State<AddBankAccountView> createState() => _AddBankAccountViewState();
}

class _AddBankAccountViewState extends State<AddBankAccountView> {
  static const Color _ink = Color(0xFF15253B);
  static const Color _muted = Color(0xFF69778A);
  static const Color _surface = Color(0xFFF5F7F9);
  static const Color _line = Color(0xFFE4EAF0);
  static const Color _blue = Color(0xFF386DCC);
  static const String _font = 'HankenGrotesk';

  final _formKey = GlobalKey<FormState>();
  late final ApiService _apiService;
  final _accountNameController = TextEditingController(
    text: 'Postman Test Bank',
  );
  final _institutionController = TextEditingController(
    text: 'Postman test data',
  );
  final _balanceController = TextEditingController(text: '30000.00');
  final _notesController = TextEditingController(
    text: 'Test account created by Postman collection',
  );
  final _lastFourController = TextEditingController(text: '1234');
  final _purposeController = TextEditingController(text: 'Everyday spending');
  final _minimumDuePercentController = TextEditingController(text: '5.00');
  final _minimumDueAmountController = TextEditingController(text: '0.00');

  String _accountType = 'Bank Account';
  String _currency = 'INR';
  String _network = 'Visa';
  DateTime _openingDate = DateTime(2026, 10, 14);
  bool _allowNegativeBalance = false;
  bool _isCredit = true;
  int _statementDay = 15;
  int _paymentDueDay = 5;
  bool _isSaving = false;
  String? _pendingIdempotencyKey;
  String? _pendingRequestBody;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    if (widget.initialAccountType == 'cash') {
      _setCashDefaults();
    }
    if (widget.initialAccountType == 'credit_card') {
      _setCreditCardDefaults();
    }
  }

  bool get _isCashAccount => _accountType == 'Cash Account';

  void _setCashDefaults() {
    _accountType = 'Cash Account';
    _accountNameController.text = 'Cash Account';
    _institutionController.clear();
    _balanceController.text = '0.00';
    _openingDate = DateTime.now();
  }

  void _setCreditCardDefaults() {
    _accountType = 'Credit Card';
    _accountNameController.clear();
    _institutionController.clear();
    _balanceController.clear();
    _notesController.clear();
    _lastFourController.clear();
    _purposeController.clear();
    _minimumDuePercentController.clear();
    _minimumDueAmountController.clear();
    _network = 'Visa';
    _currency = 'INR';
    _statementDay = 15;
    _paymentDueDay = 5;
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    _notesController.dispose();
    _lastFourController.dispose();
    _purposeController.dispose();
    _minimumDuePercentController.dispose();
    _minimumDueAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F6),
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56.h,
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          _isCreditCard
              ? 'Add Credit Card'
              : _isCashAccount
              ? 'Add Cash Account'
              : 'Add Bank Account',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'reset') _resetForm();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'reset', child: Text('Reset form')),
            ],
          ),
          SizedBox(width: 4.w),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.r)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _isCreditCard
                    ? _creditCardForm()
                    : Form(
                        key: _formKey,
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 20.h),
                          children: [
                            _sectionCard(
                              title: 'Account Identification',
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _fieldLabel(
                                        'Account Name',
                                        required: true,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 13.sp,
                                          color: _blue,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Validated',
                                          style: TextStyle(
                                            color: _blue,
                                            fontFamily: _font,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                _textField(
                                  controller: _accountNameController,
                                  hint: 'e.g. Everyday Checking',
                                  prefixIcon: Icons.account_balance_outlined,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Enter an account name'
                                      : null,
                                ),
                                _helper(
                                  'Required for statement matching and audit trails.',
                                ),
                                SizedBox(height: 13.h),
                                _fieldLabel('Account Type', required: true),
                                _dropdown(
                                  value: _accountType,
                                  icon: Icons.account_balance_outlined,
                                  items: const [
                                    'Bank Account',
                                    'Cash Account',
                                    'Digital Wallet',
                                    'Credit Card',
                                  ],
                                  onChanged: (value) => setState(() {
                                    final wasCashAccount = _isCashAccount;
                                    _accountType = value;
                                    if (_isCashAccount && !wasCashAccount) {
                                      _accountNameController.text =
                                          'Cash Account';
                                      _institutionController.clear();
                                      _balanceController.text = '0.00';
                                      _openingDate = DateTime.now();
                                      _isCredit = true;
                                    }
                                  }),
                                ),
                                _helper(
                                  _isCashAccount
                                      ? 'Track cash kept in your wallet or at home.'
                                      : 'Standard retail or commercial bank ledger.',
                                ),
                                SizedBox(height: 13.h),
                                if (!_isCashAccount) ...[
                                  _fieldLabel('Institution Name'),
                                  _textField(
                                    controller: _institutionController,
                                    hint: 'Bank or institution',
                                    prefixIcon: Icons.domain_outlined,
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 12.h),
                            _sectionCard(
                              title: 'Valuation & Currency',
                              trailing: _isCashAccount
                                  ? null
                                  : _creditSelector(),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _fieldLabel('Reporting Currency'),
                                    ),
                                    Text(
                                      'ISO 4217',
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 9.sp,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                                _dropdown(
                                  value: _currency,
                                  icon: Icons.currency_exchange_outlined,
                                  items: const [
                                    'INR',
                                    'USD',
                                    'EUR',
                                    'GBP',
                                    'AED',
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _currency = value),
                                  itemLabel: (value) => switch (value) {
                                    'INR' => 'INR  (Indian Rupee)',
                                    'USD' => 'USD  (US Dollar)',
                                    'EUR' => 'EUR  (Euro)',
                                    'GBP' => 'GBP  (Pound Sterling)',
                                    _ => 'AED  (UAE Dirham)',
                                  },
                                ),
                                SizedBox(height: 13.h),
                                _fieldLabel('Opening Balance', required: true),
                                _textField(
                                  controller: _balanceController,
                                  hint: '0.00',
                                  prefixText: _currency == 'INR'
                                      ? '₹ '
                                      : '$_currency ',
                                  suffix: IconButton(
                                    tooltip: 'Clear amount',
                                    onPressed: _balanceController.clear,
                                    icon: Icon(
                                      Icons.cancel,
                                      color: const Color(0xFFDCE4EF),
                                      size: 19.sp,
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                  validator: (value) {
                                    final amount = double.tryParse(
                                      value?.trim() ?? '',
                                    );
                                    if (amount == null || amount < 0) {
                                      return 'Enter a valid opening balance';
                                    }
                                    return null;
                                  },
                                ),
                                _helper(
                                  'Numeric ledger balance captured as the opening entry.',
                                ),
                                SizedBox(height: 13.h),
                                if (!_isCashAccount) ...[
                                  _fieldLabel(
                                    'Opening Balance Date',
                                    required: true,
                                  ),
                                  InkWell(
                                    onTap: _pickOpeningDate,
                                    borderRadius: BorderRadius.circular(9.r),
                                    child: InputDecorator(
                                      decoration: _decoration(
                                        prefixIcon:
                                            Icons.calendar_today_outlined,
                                        suffixIcon:
                                            Icons.edit_calendar_outlined,
                                      ),
                                      child: Text(
                                        _formatDate(_openingDate),
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: _ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 12.h),
                            _sectionCard(
                              title: 'Policies & Context',
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Allow negative balance',
                                                  style: _bodyStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                _allowNegativeBalance
                                                    ? 'ON'
                                                    : 'OFF',
                                                style: TextStyle(
                                                  color: _blue,
                                                  fontFamily: _font,
                                                  fontSize: 9.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Permit the account balance to slip below zero for credit limits or formal overdraft structures.',
                                            style: TextStyle(
                                              color: _muted,
                                              fontFamily: _font,
                                              fontSize: 10.sp,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    SizedBox(
                                      height: 30.h,
                                      child: Switch.adaptive(
                                        value: _allowNegativeBalance,
                                        activeTrackColor: AppColors.primaryTeal,
                                        onChanged: (value) => setState(
                                          () => _allowNegativeBalance = value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _fieldLabel('Ledger Notes'),
                                    Text(
                                      '${_notesController.text.length}/180',
                                      style: TextStyle(
                                        color: _muted,
                                        fontFamily: _font,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                TextFormField(
                                  controller: _notesController,
                                  maxLength: 180,
                                  maxLines: 3,
                                  onChanged: (_) => setState(() {}),
                                  style: _bodyStyle(),
                                  decoration: _decoration(
                                    hint: 'Add a note for this ledger',
                                  ).copyWith(counterText: ''),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          _bottomActions(),
        ],
      ),
    );
  }

  bool get _isCreditCard => _accountType == 'Credit Card';

  Widget _creditCardForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        children: [
          _sectionCard(
            title: 'Credit Card Identification',
            subtitle: 'Use a clear label for matching statements.',
            icon: Icons.credit_card_outlined,
            children: [
              _fieldLabel('Card Nickname / Display Name', required: true),
              _textField(
                controller: _accountNameController,
                hint: 'e.g. Rewards Primary',
                prefixIcon: Icons.credit_card_outlined,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a card nickname'
                    : null,
              ),
              _helper('Shown across cards, transactions, and reports.'),
              SizedBox(height: 13.h),
              _fieldLabel('Issuer', required: true),
              _textField(
                controller: _institutionController,
                hint: 'e.g. HDFC Bank',
                prefixIcon: Icons.account_balance_outlined,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the card provider'
                    : null,
              ),
              SizedBox(height: 13.h),
              _fieldLabel('Network', required: true),
              _dropdown(
                value: _network,
                icon: Icons.account_tree_outlined,
                items: const [
                  'Visa',
                  'Mastercard',
                  'RuPay',
                  'American Express',
                ],
                onChanged: (value) => setState(() => _network = value),
              ),
              SizedBox(height: 13.h),
              _fieldLabel('Last 4 Digits', required: true),
              _textField(
                controller: _lastFourController,
                hint: '1234',
                prefixIcon: Icons.password_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                validator: (value) =>
                    RegExp(r'^\d{4}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter exactly 4 digits',
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _sectionCard(
            title: 'Credit Terms & Limits',
            subtitle: 'Keep the available credit and ledger behavior explicit.',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              _fieldLabel('Approved Credit Limit', required: true),
              _textField(
                controller: _balanceController,
                hint: '0.00',
                prefixText: _currency == 'INR' ? '₹ ' : '$_currency ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  return amount == null || amount <= 0
                      ? 'Enter a valid credit limit'
                      : null;
                },
              ),
              _helper(
                'This becomes the card limit used for utilization tracking.',
              ),
              SizedBox(height: 13.h),
              _fieldLabel('Reporting Currency', required: true),
              _dropdown(
                value: _currency,
                icon: Icons.currency_exchange_outlined,
                items: const ['INR', 'USD', 'EUR', 'GBP', 'AED'],
                onChanged: (value) => setState(() => _currency = value),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _sectionCard(
            title: 'Billing Cycle & Due Dates',
            subtitle: 'Used to calculate reminders and upcoming payments.',
            icon: Icons.calendar_month_outlined,
            children: [
              _fieldLabel('Statement Date', required: true),
              _dayDropdown(
                _statementDay,
                (value) => setState(() => _statementDay = value),
              ),
              SizedBox(height: 13.h),
              _fieldLabel('Payment Due Date', required: true),
              _dayDropdown(
                _paymentDueDay,
                (value) => setState(() => _paymentDueDay = value),
              ),
              _helper('Choose the recurring day of each month.'),
              SizedBox(height: 13.h),
              _fieldLabel('Minimum Due Percentage', required: true),
              _textField(
                controller: _minimumDuePercentController,
                hint: '5.00',
                suffix: const Text('%'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    double.tryParse(value?.trim() ?? '') == null
                    ? 'Enter a valid percentage'
                    : null,
              ),
              SizedBox(height: 13.h),
              _fieldLabel('Minimum Due Amount', required: true),
              _textField(
                controller: _minimumDueAmountController,
                hint: '0.00',
                prefixText: _currency == 'INR' ? 'â‚¹ ' : '$_currency ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    double.tryParse(value?.trim() ?? '') == null
                    ? 'Enter a valid amount'
                    : null,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _sectionCard(
            title: 'Audit Notes & Purpose',
            subtitle: 'Add context for future reconciliation.',
            icon: Icons.fact_check_outlined,
            children: [
              _fieldLabel('Primary Purpose', required: true),
              _textField(
                controller: _purposeController,
                hint: 'e.g. Travel and subscriptions',
                prefixIcon: Icons.label_outline,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the card purpose'
                    : null,
              ),
              SizedBox(height: 13.h),
              _fieldLabel('Audit Notes'),
              TextFormField(
                controller: _notesController,
                maxLength: 180,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                style: _bodyStyle(),
                decoration: _decoration(
                  hint: 'Add reconciliation notes',
                ).copyWith(counterText: ''),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayDropdown(int value, ValueChanged<int> onChanged) {
    return _dropdown(
      value: value.toString(),
      icon: Icons.event_outlined,
      items: [for (var day = 1; day <= 28; day++) day.toString()],
      onChanged: (selected) => onChanged(int.parse(selected)),
      itemLabel: (day) => '${day}th of every month',
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    Widget? trailing,
    String? subtitle,
    IconData? icon,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE8EDF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon ?? Icons.circle,
                size: icon == null ? 7.sp : 17.sp,
                color: _blue,
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _ink,
                    fontFamily: _font,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: 3.h),
            Text(
              subtitle,
              style: TextStyle(
                color: _muted,
                fontFamily: _font,
                fontSize: 9.sp,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Text.rich(
        TextSpan(
          text: label,
          children: required
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Color(0xFFE05B53)),
                  ),
                ]
              : null,
        ),
        style: TextStyle(
          color: _ink,
          fontFamily: _font,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    String? prefixText,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
    TextStyle? style,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
      style: style ?? _bodyStyle(fontWeight: FontWeight.w600),
      decoration: _decoration(
        hint: hint,
        prefixIcon: prefixIcon,
        suffix: suffix,
        prefixText: prefixText,
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String Function(String)? itemLabel,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
      decoration: _decoration(prefixIcon: icon),
      style: _bodyStyle(fontWeight: FontWeight.w600),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                itemLabel?.call(item) ?? item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (nextValue) {
        if (nextValue != null) onChanged(nextValue);
      },
    );
  }

  InputDecoration _decoration({
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    Widget? suffix,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF8996A7),
        fontFamily: _font,
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 15.sp, color: const Color(0xFF65738A)),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: const Color(0xFF1C5FBF),
        fontFamily: _font,
        fontSize: 17.sp,
        fontWeight: FontWeight.w700,
      ),
      suffixIcon:
          suffix ??
          (suffixIcon == null
              ? null
              : Icon(suffixIcon, size: 15.sp, color: const Color(0xFF65738A))),
      filled: true,
      fillColor: _surface,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 11.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: const BorderSide(color: Color(0xFFE05B53)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.r),
        borderSide: const BorderSide(color: Color(0xFFE05B53)),
      ),
    );
  }

  Widget _helper(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _muted, size: 11.sp),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _muted,
                fontFamily: _font,
                fontSize: 9.sp,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _creditSelector() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _balanceTypeOption('CR', true),
          _balanceTypeOption('DR', false),
        ],
      ),
    );
  }

  Widget _balanceTypeOption(String label, bool credit) {
    final selected = _isCredit == credit;
    return InkWell(
      onTap: () => setState(() => _isCredit = credit),
      borderRadius: BorderRadius.circular(5.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _blue : _muted,
            fontFamily: _font,
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _bottomActions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 9.h, 16.w, 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F6),
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveForm,
                  icon: _isSaving
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Saving account...'
                        : _isCreditCard
                        ? 'Save Credit Card'
                        : _isCashAccount
                        ? 'Save Cash Account'
                        : 'Save Bank Account',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: Get.back,
                style: TextButton.styleFrom(
                  foregroundColor: _muted,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                ),
                child: Text(
                  'Cancel and Discard',
                  style: TextStyle(fontFamily: _font, fontSize: 10.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _bodyStyle({FontWeight fontWeight = FontWeight.w500}) => TextStyle(
    color: _ink,
    fontFamily: _font,
    fontSize: 11.sp,
    fontWeight: fontWeight,
  );

  Future<void> _pickOpeningDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _openingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primaryTeal),
        ),
        child: child!,
      ),
    );
    if (selectedDate != null) setState(() => _openingDate = selectedDate);
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedBalance = double.tryParse(_balanceController.text.trim()) ?? 0;
    final openingBalance = _isCreditCard
        ? '0.00'
        : (!_isCashAccount && !_isCredit ? -parsedBalance : parsedBalance)
              .toStringAsFixed(2);
    final accountType = switch (_accountType) {
      'Bank Account' => 'bank',
      'Cash Account' => 'cash',
      'Digital Wallet' => 'wallet',
      'Credit Card' => 'credit_card',
      _ => 'bank',
    };

    setState(() => _isSaving = true);
    try {
      final requestBody = _isCreditCard
          ? <String, dynamic>{
              'name': _accountNameController.text.trim(),
              'currency': _currency,
              'notes': _notesController.text.trim(),
              'issuer': _institutionController.text.trim(),
              'network': _network,
              'last_four': _lastFourController.text.trim(),
              'credit_limit': _balanceController.text.trim(),
              'billing_day': _statementDay,
              'due_days_after_statement':
                  (_paymentDueDay - _statementDay + 30) % 30,
              'minimum_due_percent': _minimumDuePercentController.text.trim(),
              'minimum_due_amount': _minimumDueAmountController.text.trim(),
              'purpose': _purposeController.text.trim(),
            }
          : <String, dynamic>{
              'name': _accountNameController.text.trim(),
              'type': accountType,
              'currency': _currency,
              'opening_balance': openingBalance,
              'allow_negative': _allowNegativeBalance,
              'notes': _notesController.text.trim(),
            };
      if (!_isCashAccount && !_isCreditCard) {
        requestBody['institution'] = _institutionController.text.trim();
        requestBody['opening_balance_date'] = _formatApiDate(_openingDate);
      }
      final endpoint = _isCreditCard
          ? ApiService.creditCardsUrl
          : ApiService.accountsUrl;
      final encodedRequestBody = jsonEncode(requestBody);
      if (_pendingIdempotencyKey == null ||
          _pendingRequestBody != encodedRequestBody) {
        _pendingIdempotencyKey = ApiService.createIdempotencyKey();
        _pendingRequestBody = encodedRequestBody;
      }
      if (kDebugMode) {
        debugPrint(
          '[${_isCreditCard ? 'CreditCard' : 'BankAccount'}] POST $endpoint',
        );
        debugPrint(
          '[${_isCreditCard ? 'CreditCard' : 'BankAccount'}] Request body: ${const JsonEncoder.withIndent('  ').convert(requestBody)}',
        );
      }

      final response = _isCreditCard
          ? await _apiService.postCreditCard(
              requestBody,
              idempotencyKey: _pendingIdempotencyKey!,
            )
          : await _apiService.postWithIdempotency(
              endpoint,
              requestBody,
              idempotencyKey: _pendingIdempotencyKey!,
            );
      if (kDebugMode) {
        debugPrint(
          '[${_isCreditCard ? 'CreditCard' : 'BankAccount'}] HTTP ${response.statusCode}',
        );
        debugPrint(
          '[${_isCreditCard ? 'CreditCard' : 'BankAccount'}] Response body: ${response.body}',
        );
      }

      Map<String, dynamic> payload = {};
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
      }

      final data = payload['data'];
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['success'] == true &&
          data is Map) {
        final createdAccount = Map<String, dynamic>.from(data);
        _pendingIdempotencyKey = null;
        _pendingRequestBody = null;
        Get.back(result: createdAccount);
        Get.snackbar(
          _isCreditCard ? 'Credit card created' : 'Account created',
          payload['message']?.toString() ??
              (_isCreditCard
                  ? 'Credit card saved.'
                  : (_isCashAccount
                        ? 'Cash account saved.'
                        : 'Bank account saved.')),
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (response.statusCode == 400 || response.statusCode == 422) {
        _pendingIdempotencyKey = null;
        _pendingRequestBody = null;
      }

      final message =
          payload['message']?.toString() ??
          'The account could not be saved. Please try again.';
      final details = _formatBackendErrors(payload['errors']);
      Get.snackbar(
        _isCreditCard
            ? 'Unable to create credit card'
            : 'Unable to create account',
        details.isEmpty ? message : '$message\n$details',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[${_isCreditCard ? 'CreditCard' : 'BankAccount'}] Request failed: ${error.runtimeType}: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      Get.snackbar(
        'Connection error',
        kDebugMode
            ? 'Request failed: ${error.runtimeType}. See debug console for details.'
            : 'Unable to save this account. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatBackendErrors(dynamic errors) {
    if (errors is Map) {
      return errors.entries
          .map((entry) {
            final value = entry.value;
            final detail = value is List ? value.join(', ') : value.toString();
            return '${entry.key}: $detail';
          })
          .join('\n');
    }
    if (errors is List) {
      return errors
          .map((error) {
            if (error is Map) {
              final field = error['field']?.toString();
              final message = error['message']?.toString();
              if (field != null && message != null) return '$field: $message';
            }
            return error.toString();
          })
          .join('\n');
    }
    return '';
  }

  void _resetForm() {
    setState(() {
      if (widget.initialAccountType == 'credit_card') {
        _setCreditCardDefaults();
      } else if (widget.initialAccountType == 'cash') {
        _setCashDefaults();
      } else {
        _accountNameController.clear();
        _institutionController.clear();
        _balanceController.text = '0.00';
        _notesController.clear();
        _accountType = 'Bank Account';
        _currency = 'INR';
        _openingDate = DateTime.now();
        _allowNegativeBalance = false;
        _isCredit = true;
      }
    });
  }
}
