import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_pages.dart';
import '../../home/widgets/home_widget.dart';
import '../controllers/account_transactions_controller.dart';
import '../controllers/bank_accounts_controller.dart';
import '../controllers/transfers_controller.dart';

class TransfersSection extends GetView<TransfersController> {
  const TransfersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final transfers = controller.transfers;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Transfers',
            subtitle: '${controller.total.value} total',
            action: 'New transfer',
            onAction: controller.isCreating.value ? null : _createTransfer,
          ),
          SizedBox(height: 12.h),
          if (controller.isLoading.value && transfers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              ),
            )
          else if (controller.errorMessage.value.isNotEmpty &&
              transfers.isEmpty)
            _errorState(controller.errorMessage.value)
          else if (transfers.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'No transfers yet.',
                  style: TextStyle(
                    color: HomeStyle.muted,
                    fontSize: 10.5.sp,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ),
            )
          else ...[
            ...transfers.map(
              (transfer) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _transferCard(transfer),
              ),
            ),
            if (controller.isLoadingMore.value)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ),
                ),
              )
            else if (controller.loadMoreError.value.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    Text(
                      controller.loadMoreError.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HomeStyle.muted,
                        fontSize: 10.5.sp,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                    TextButton(
                      onPressed: controller.loadNextPage,
                      child: const Text('Try loading more'),
                    ),
                  ],
                ),
              )
            else if (controller.hasMore)
              Center(
                child: TextButton(
                  onPressed: controller.loadNextPage,
                  child: const Text('Load more transfers'),
                ),
              ),
          ],
        ],
      );
    });
  }

  Future<void> _createTransfer() async {
    final accountsController = Get.find<BankAccountsController>();
    final created = await Get.toNamed(
      Routes.CREATE_TRANSFER,
      arguments: accountsController.accounts.toList(),
    );
    if (created != true) return;

    await Future.wait([
      accountsController.fetchAccounts(),
      controller.fetchTransfers(),
    ]);
    Get.snackbar(
      'Transfer created',
      'Your transfer was recorded successfully.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Widget _errorState(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.expenseRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HomeStyle.ink,
              fontSize: 12.sp,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          TextButton(
            onPressed: controller.fetchTransfers,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _transferCard(AccountTransaction transfer) {
    final isReversed =
        transfer.isReversed || transfer.status.toLowerCase() == 'reversed';
    final amount = double.tryParse(transfer.amount);
    final amountLabel = amount == null
        ? '${transfer.amount} ${transfer.currency}'
        : '${_currencySymbol(transfer.currency)}${amount.abs().toStringAsFixed(2)}';
    final date = transfer.transactionDate == null
        ? null
        : _formatDate(transfer.transactionDate!);

    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: HomeStyle.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.iconTeal,
              size: 22.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.description?.isNotEmpty == true
                      ? transfer.description!
                      : 'Account transfer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HomeStyle.ink,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  '${transfer.sourceAccountName ?? 'Unknown account'}  →  '
                  '${transfer.destinationAccountName ?? 'Unknown account'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HomeStyle.muted,
                    fontSize: 10.5.sp,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
                if (date != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    date,
                    style: TextStyle(
                      color: HomeStyle.muted,
                      fontSize: 10.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ],
                SizedBox(height: 6.h),
                _statusBadge(isReversed ? 'Reversed' : transfer.status),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              amountLabel,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: HomeStyle.ink,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
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
          color: reversed ? AppColors.expenseRed : HomeStyle.muted,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
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
