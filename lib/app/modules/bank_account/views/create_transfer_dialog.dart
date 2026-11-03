import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/bank_accounts_controller.dart';
import '../controllers/transfers_controller.dart';

class CreateTransferDialog extends StatefulWidget {
  const CreateTransferDialog({
    required this.accounts,
    required this.controller,
    super.key,
  });

  final List<BankAccount> accounts;
  final TransfersController controller;

  @override
  State<CreateTransferDialog> createState() => _CreateTransferDialogState();
}

class _CreateTransferDialogState extends State<CreateTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final List<BankAccount> _eligibleAccounts;
  late String? _sourceAccountUuid;
  late String? _destinationAccountUuid;
  late DateTime _transactionDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    final activeAccounts = widget.accounts.where((account) {
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
    _sourceAccountUuid = _eligibleAccounts.isNotEmpty
        ? _eligibleAccounts.first.uuid
        : null;
    _destinationAccountUuid = _eligibleAccounts.length > 1
        ? _eligibleAccounts[1].uuid
        : null;
    _transactionDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<BankAccount> get _destinationAccounts {
    final source = _accountForUuid(_sourceAccountUuid);
    return _eligibleAccounts.where((account) {
      if (account.uuid == _sourceAccountUuid) return false;
      return source == null || account.currency == source.currency;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New transfer'),
      content: SizedBox(
        width: 420.w,
        child: _eligibleAccounts.length < 2
            ? _notEnoughAccounts()
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                        ).copyWith(
                          prefixText:
                              '${_currencySymbol(_accountForUuid(_sourceAccountUuid)?.currency ?? 'INR')} ',
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value?.trim() ?? '');
                          if (amount == null ||
                              !amount.isFinite ||
                              amount <= 0) {
                            return 'Enter an amount greater than zero';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12.h),
                      DropdownButtonFormField<String>(
                        initialValue: _sourceAccountUuid,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'From account',
                        ),
                        items: _eligibleAccounts
                            .map(
                              (account) => DropdownMenuItem(
                                value: account.uuid!,
                                child: Text(
                                  _accountLabel(account),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (uuid) {
                          setState(() {
                            _sourceAccountUuid = uuid;
                            if (!_destinationAccounts.any(
                              (account) =>
                                  account.uuid == _destinationAccountUuid,
                            )) {
                              final destinations = _destinationAccounts;
                              _destinationAccountUuid = destinations.isEmpty
                                  ? null
                                  : destinations.first.uuid;
                            }
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Select a source account' : null,
                      ),
                      SizedBox(height: 12.h),
                      DropdownButtonFormField<String>(
                        initialValue: _destinationAccountUuid,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'To account',
                        ),
                        items: _destinationAccounts
                            .map(
                              (account) => DropdownMenuItem(
                                value: account.uuid!,
                                child: Text(
                                  _accountLabel(account),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (uuid) =>
                            setState(() => _destinationAccountUuid = uuid),
                        validator: (value) =>
                            value == null ? 'Select a destination account' : null,
                      ),
                      SizedBox(height: 12.h),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Transfer date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(_formatDate(_transactionDate)),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _descriptionController,
                        maxLength: 180,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          counterText: '',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a description'
                            : null,
                      ),
                      Obx(
                        () => widget.controller.createError.value.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Text(
                                  widget.controller.createError.value,
                                  style: TextStyle(
                                    color: AppColors.expenseRed,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        Obx(
          () => TextButton(
            onPressed: widget.controller.isCreating.value
                ? null
                : () => Get.back(),
            child: const Text('Cancel'),
          ),
        ),
        if (_eligibleAccounts.length >= 2)
          Obx(
            () => FilledButton(
              onPressed:
                  widget.controller.isCreating.value ? null : _submit,
              child: widget.controller.isCreating.value
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Transfer'),
            ),
          ),
      ],
    );
  }

  Widget _notEnoughAccounts() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Text(
        'Add at least two active accounts with the same currency to make a transfer.',
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate.isAfter(now) ? now : _transactionDate,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _transactionDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await widget.controller.createTransfer(
      amount: _amountController.text,
      transactionDate: _transactionDate,
      sourceAccountUuid: _sourceAccountUuid!,
      destinationAccountUuid: _destinationAccountUuid!,
      description: _descriptionController.text,
    );
    if (success && mounted) Get.back(result: true);
  }

  BankAccount? _accountForUuid(String? uuid) {
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
        return currency;
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
