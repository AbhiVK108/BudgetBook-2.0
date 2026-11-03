import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/account_transactions_controller.dart';

class AccountTransactionsView extends GetView<AccountTransactionsController> {
  const AccountTransactionsView({super.key});

  static const Color _text = Color(0xFF202624);
  static const Color _muted = Color(0xFF737B76);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Account transactions',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.transactions.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          );
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.transactions.isEmpty) {
          return _errorState();
        }

        return RefreshIndicator(
          color: AppColors.primaryTeal,
          onRefresh: controller.fetchTransactions,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 240 &&
                  controller.hasMore) {
                controller.loadNextPage();
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              itemCount: controller.transactions.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return _accountSummary();
                if (index <= controller.transactions.length) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _transactionCard(
                      controller.transactions[index - 1],
                    ),
                  );
                }
                return _paginationFooter();
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _accountSummary() {
    final account = controller.account;
    return Container(
      margin: EdgeInsets.only(bottom: 22.h),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: AppColors.bannerGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            '${_titleCase(account.type)}${account.institution == null ? '' : ' · ${account.institution}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
          SizedBox(height: 15.h),
          Text(
            'AVAILABLE BALANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${_currencySymbol(account.currency)}${_formatAmount(account.balance)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Obx(
            () => Text(
              '${controller.total.value} ${controller.total.value == 1 ? 'transaction' : 'transactions'}',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionCard(AccountTransaction transaction) {
    final accountUuid = controller.account.uuid ?? '';
    final credit = transaction.isCreditFor(accountUuid);
    final amount = double.tryParse(transaction.amount);
    final amountLabel = amount == null
        ? '${transaction.amount} ${transaction.currency}'
        : '${credit ? '+' : '-'}${_currencySymbol(transaction.currency)}'
              '${amount.abs().toStringAsFixed(2)}';
    final detail = transaction.counterparty ??
        transaction.categoryName ??
        _otherAccountName(transaction, accountUuid);
    final isReversed = transaction.isReversed ||
        transaction.status.toLowerCase() == 'reversed';

    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: const Color(0xFFE9EEEB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: (credit ? AppColors.incomeGreen : AppColors.expenseRed)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(
              _transactionIcon(transaction.type, credit),
              color: credit ? AppColors.incomeGreen : AppColors.expenseRed,
              size: 21.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description?.isNotEmpty == true
                      ? transaction.description!
                      : _titleCase(transaction.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  [
                    _titleCase(transaction.type),
                    if (detail != null && detail.isNotEmpty) detail,
                    if (transaction.transactionDate != null)
                      _formatDate(transaction.transactionDate!),
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _muted, fontSize: 11.sp),
                ),
                SizedBox(height: 6.h),
                _statusBadge(isReversed ? 'Reversed' : transaction.status),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountLabel,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: credit ? AppColors.incomeGreen : AppColors.expenseRed,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (transaction.reference != null) ...[
                SizedBox(height: 4.h),
                Text(
                  transaction.reference!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _muted, fontSize: 10.sp),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final reversed = status.toLowerCase() == 'reversed';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: reversed
            ? AppColors.expenseRed.withValues(alpha: 0.1)
            : AppColors.cardBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        _titleCase(status),
        style: TextStyle(
          color: reversed ? AppColors.expenseRed : _muted,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _paginationFooter() {
    if (controller.isLoadingMore.value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );
    }
    if (controller.loadMoreError.value.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          children: [
            Text(
              controller.loadMoreError.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12.sp),
            ),
            TextButton(
              onPressed: controller.loadNextPage,
              child: const Text('Try loading more'),
            ),
          ],
        ),
      );
    }
    if (controller.transactions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 54.h),
        child: Center(
          child: Text(
            'No transactions for this account yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14.sp),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42.r, color: _muted),
            SizedBox(height: 12.h),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 14.sp),
            ),
            SizedBox(height: 14.h),
            FilledButton.icon(
              onPressed: controller.fetchTransactions,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  String? _otherAccountName(
    AccountTransaction transaction,
    String accountUuid,
  ) {
    if (transaction.sourceAccountUuid == accountUuid) {
      return transaction.destinationAccountName;
    }
    if (transaction.destinationAccountUuid == accountUuid) {
      return transaction.sourceAccountName;
    }
    return null;
  }

  IconData _transactionIcon(String type, bool credit) {
    switch (type.toLowerCase()) {
      case 'opening_balance':
        return Icons.account_balance_wallet_outlined;
      case 'transfer':
      case 'transfer_in':
      case 'transfer_out':
        return Icons.swap_horiz_rounded;
      default:
        return credit
            ? Icons.south_west_rounded
            : Icons.north_east_rounded;
    }
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

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _titleCase(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
