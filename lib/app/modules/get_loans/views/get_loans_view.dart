
import 'package:budget_book_2026/app/modules/get_loans/controllers/get_loans_controller.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class GetLoansView extends GetView<GetLoansController> {
  const GetLoansView({super.key});

  static const Color primary = Color(0xFF009688);
  static const Color dark = Color(0xFF111827);
  static const Color label = Color(0xFF526071);
  static const Color border = Color(0xFFE9EEF2);
  static const Color background = Color(0xFFF4F6F6);

  String _money(String key) {
    final value = controller.number(key);
    return '₹${_indianNumber(value)}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () => Get.toNamed(Routes.POSTLOAN),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Loan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(22.r),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Loans',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.fetchLoan,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                    onSelected: (value) {
                      if (value == 'refresh') {
                        controller.fetchLoan();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'refresh',
                        child: Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ERROR MESSAGE
            Obx(() {
              if (controller.loadError.value.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.loadError.value,
                        style: const TextStyle(
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.fetchLoan,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.loan.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                if (controller.loan.isEmpty) {
                  return _emptyState(
                    controller.loadError.value.isEmpty
                        ? 'No loan details available.'
                        : controller.loadError.value,
                  );
                }

                final loanStatus =
                    controller.value('loanStatus', fallback: '1');
                final isActive = loanStatus == '1';

                final total = controller.number('totalAmount');
                final paid = controller.number('paidAmount');
                final due = controller.number('dueAmount');

                // This detail page represents one selected loan.
                final isCompleted =
                    loanStatus == '2' ||
                    loanStatus.toLowerCase() == 'completed';

                return RefreshIndicator(
                  onRefresh: controller.fetchLoan,
                  color: primary,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      14.w,
                      18.h,
                      14.w,
                      110.h,
                    ),
                    children: [
                      // SUMMARY CARDS
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              'Total',
                              total,
                              const Color(0xFF05A77A),
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: _summaryCard(
                              'Pay',
                              paid,
                              const Color(0xFFFF1010),
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: _summaryCard(
                              'Due',
                              due,
                              const Color(0xFFFF9855),
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: _summaryCard(
                              'Completed',
                              isCompleted ? total : 0,
                              const Color(0xFF08BF8C),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 22.h),

                      // LOAN DETAILS CARD
                      Container(
                        padding: EdgeInsets.all(17.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(27.r),
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF233746)
                                  .withValues(alpha: 0.045),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LENDER AND STATUS
                            Row(
                              children: [
                                Container(
                                  width: 57.w,
                                  height: 57.w,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9FBF6),
                                    borderRadius:
                                        BorderRadius.circular(19.r),
                                    border: Border.all(
                                      color: const Color(0xFFD3F7EF),
                                    ),
                                  ),
                                  child: Text(
                                    controller.loanId ?? '01',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF167D72),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        controller.value(
                                          'nameOfLender',
                                          fallback: 'Loan',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: dark,
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Personal Loan Account',
                                        style: TextStyle(
                                          color: label,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _statusBadge(isActive),
                              ],
                            ),

                            SizedBox(height: 18.h),
                            const Divider(color: border),
                            SizedBox(height: 14.h),

                            // PRINCIPAL AND PAYABLE
                            Container(
                              padding: EdgeInsets.all(15.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FBFC),
                                borderRadius: BorderRadius.circular(19.r),
                                border: Border.all(color: border),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LOAN PRINCIPAL',
                                    style: TextStyle(
                                      color: label,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _money('sanctionedAmount'),
                                      style: TextStyle(
                                        color: dark,
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 15.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _miniAmount(
                                          'TOTAL PAYABLE',
                                          _money('totalAmount'),
                                          const Color(0xFFE74465),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: _miniAmount(
                                          'AMOUNT DUE',
                                          _money('dueAmount'),
                                          const Color(0xFFE74465),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 12.h),

                            // INTEREST AND INSTALLMENT
                            Row(
                              children: [
                                Expanded(
                                  child: _metric(
                                    'INTEREST RATE',
                                    '${controller.value('rateOfInterest')}%',
                                    subtitle:
                                        'Interest ${_money('totalInterestAmount')}',
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: _metric(
                                    'INSTALLMENT',
                                    _money('instalmentAmount'),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12.h),

                            // EMI DATES AND PAYMENT PROGRESS
                            Container(
                              padding: EdgeInsets.all(13.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCFDFE),
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(
                                  color: const Color(0xFFDDE5EC),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 9,
                                        color: primary,
                                      ),
                                      SizedBox(width: 7.w),
                                      Expanded(
                                        child: Text(
                                          'Start: ${controller.value('startEMI')}',
                                          style: TextStyle(
                                            color: label,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 9.h),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 9,
                                        color: Color(0xFFE74465),
                                      ),
                                      SizedBox(width: 7.w),
                                      Expanded(
                                        child: Text(
                                          'End: ${controller.value('endEMI')}',
                                          style: TextStyle(
                                            color: label,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 14.h),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(20.r),
                                    child: LinearProgressIndicator(
                                      value: total > 0
                                          ? (paid / total)
                                              .clamp(0.0, 1.0)
                                          : 0,
                                      minHeight: 8.h,
                                      backgroundColor:
                                          const Color(0xFFE7ECF2),
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                        Color(0xFF18B6A2),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${total > 0 ? (paid / total * 100).clamp(0, 100).toStringAsFixed(0) : '0'}% paid',
                                      style: TextStyle(
                                        color: label,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 14.h),
                            const Divider(color: border),
                            SizedBox(height: 8.h),

                            // DISBURSAL AND CHARGES
                            Row(
                              children: [
                                Expanded(
                                  child: _smallInfo(
                                    'Disbursal',
                                    _money('disbursalAmount'),
                                  ),
                                ),
                                Expanded(
                                  child: _smallInfo(
                                    'Charges',
                                    _money('chargesCutting'),
                                    alignEnd: true,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Text(
                                  'Terms: ',
                                  style: TextStyle(
                                    color: label,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9FAF6),
                                    borderRadius:
                                        BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    '${controller.value('loanTerms')} Cycles',
                                    style: TextStyle(
                                      color: const Color(0xFF167D72),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 17.h),
                            const Divider(color: border),
                            SizedBox(height: 10.h),

                            // EDIT AND DELETE
                            Row(
                              children: [
                                const Spacer(),
                                OutlinedButton.icon(
                                  onPressed:
                                      controller.isSaving.value
                                          ? null
                                          : _showEditDialog,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Edit'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF147E73),
                                    side: const BorderSide(
                                      color: Color(0xFFB5F0E4),
                                    ),
                                    backgroundColor:
                                        const Color(0xFFF1FCF9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(15.r),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 9.w),
                                OutlinedButton.icon(
                                  onPressed:
                                      controller.isDeleting.value
                                          ? null
                                          : _confirmDelete,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFFE74465),
                                    side: const BorderSide(
                                      color: Color(0xFFF8CDD5),
                                    ),
                                    backgroundColor:
                                        const Color(0xFFFFF3F5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(15.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SUMMARY CARD =================

  Widget _summaryCard(
    String title,
    double amount,
    Color color,
  ) {
    return Container(
      constraints: BoxConstraints(minHeight: 88.h),
      padding: EdgeInsets.symmetric(
        horizontal: 3.w,
        vertical: 13.h,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(17.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 9.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹${_indianNumber(amount)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATUS =================

  Widget _statusBadge(bool isActive) {
    final color = isActive
        ? const Color(0xFF159B76)
        : const Color(0xFFBE123C);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 9.w,
        vertical: 7.h,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFEDFBF5)
            : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: isActive
              ? const Color(0xFFB8EED8)
              : const Color(0xFFF8CDD5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8.sp, color: color),
          SizedBox(width: 5.w),
          Text(
            isActive ? 'Active' : 'Closed',
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================= MINI AMOUNT =================

  Widget _miniAmount(
    String title,
    String amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ================= METRIC =================

  Widget _metric(
    String title,
    String value, {
    String? subtitle,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: 83.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dark,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 5.h),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primary,
                fontSize: 10.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= SMALL INFO =================

  Widget _smallInfo(
    String title,
    String value, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: label,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            color: dark,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================= EMPTY STATE =================

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(25.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 55.sp,
              color: primary,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: label,
                fontSize: 15.sp,
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              onPressed: controller.fetchLoan,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= EDIT LOAN =================

  Future<void> _showEditDialog() async {
    final lender = TextEditingController(
      text: controller.value('nameOfLender', fallback: ''),
    );
    final sanctioned = TextEditingController(
      text: controller.value('sanctionedAmount', fallback: ''),
    );
    final disbursal = TextEditingController(
      text: controller.value('disbursalAmount', fallback: ''),
    );
    final charges = TextEditingController(
      text: controller.value('chargesCutting', fallback: '0'),
    );
    final terms = TextEditingController(
      text: controller.value('loanTerms', fallback: ''),
    );
    final interest = TextEditingController(
      text: controller.value('rateOfInterest', fallback: '0'),
    );
    final disbursementDate = TextEditingController(
      text: controller.value('dateOfDisbursement', fallback: ''),
    );
    final startEmi = TextEditingController(
      text: controller.value('startEMI', fallback: ''),
    );
    final endEmi = TextEditingController(
      text: controller.value('endEMI', fallback: ''),
    );

    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Edit Loan'),
          content: SizedBox(
            width: 420.w,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _editField(lender, 'Name of lender'),
                  _editField(sanctioned, 'Sanctioned amount', numeric: true),
                  _editField(disbursal, 'Disbursal amount', numeric: true),
                  _editField(charges, 'Charges cutting', numeric: true),
                  _editField(terms, 'Loan terms', numeric: true),
                  _editField(interest, 'Rate of interest', numeric: true),
                  _editField(disbursementDate, 'Disbursement date (YYYY-MM-DD)'),
                  _editField(startEmi, 'Start EMI (YYYY-MM-DD)'),
                  _editField(endEmi, 'End EMI (YYYY-MM-DD)'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Update'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (result != true) return;

      final sanctionedValue =
          double.tryParse(sanctioned.text.trim());
      final disbursalValue =
          double.tryParse(disbursal.text.trim());
      final chargesValue =
          double.tryParse(charges.text.trim());
      final termValue = int.tryParse(terms.text.trim());
      final rateValue =
          double.tryParse(interest.text.trim());

      final dates = [
        disbursementDate.text.trim(),
        startEmi.text.trim(),
        endEmi.text.trim(),
      ];

      if (lender.text.trim().isEmpty ||
          sanctionedValue == null ||
          !sanctionedValue.isFinite ||
          sanctionedValue <= 0 ||
          disbursalValue == null ||
          !disbursalValue.isFinite ||
          disbursalValue <= 0 ||
          chargesValue == null ||
          !chargesValue.isFinite ||
          chargesValue < 0 ||
          termValue == null ||
          termValue <= 0 ||
          rateValue == null ||
          !rateValue.isFinite ||
          rateValue < 0 ||
          dates.any((date) => DateTime.tryParse(date) == null)) {
        controller.showMessage(
          'Invalid Details',
          'Check the amounts, terms and dates.',
        );
        return;
      }

      // These calculated values are examples. Adjust them to
      // the calculation rules required by your backend.
      final interestAmount =
          sanctionedValue * rateValue / 100 * termValue;
      final totalAmount = sanctionedValue + interestAmount;
      final paidAmount = controller.number('paidAmount');

      await controller.updateLoan({
        'nameOfLender': lender.text.trim(),
        'sanctionedAmount': sanctionedValue.toStringAsFixed(2),
        'dateOfDisbursement': dates[0],
        'disbursalAmount': disbursalValue.toStringAsFixed(2),
        'chargesCutting': chargesValue.toStringAsFixed(2),
        'loanTerms': termValue.toString(),
        'rateOfInterest': rateValue.toStringAsFixed(2),
        'totalInterestAmount': interestAmount.toStringAsFixed(2),
        'instalmentAmount':
            (totalAmount / termValue).toStringAsFixed(2),
        'startEMI': dates[1],
        'endEMI': dates[2],
        'totalAmount': totalAmount.toStringAsFixed(2),
        'paidAmount': paidAmount.toStringAsFixed(2),
        'dueAmount': (totalAmount - paidAmount)
            .clamp(0, double.infinity)
            .toStringAsFixed(2),
        'loanStatus': controller.value('loanStatus', fallback: '1'),
      });
    } finally {
      lender.dispose();
      sanctioned.dispose();
      disbursal.dispose();
      charges.dispose();
      terms.dispose();
      interest.dispose();
      disbursementDate.dispose();
      startEmi.dispose();
      endEmi.dispose();
    }
  }

  Widget _editField(
    TextEditingController textController,
    String title, {
    bool numeric = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextField(
        controller: textController,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  // ================= DELETE LOAN =================

  Future<void> _confirmDelete() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Loan?'),
        content: const Text(
          'Are you sure you want to delete this loan record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await controller.deleteLoan();

    if (deleted) {
      Get.back();
    }
  }
}
