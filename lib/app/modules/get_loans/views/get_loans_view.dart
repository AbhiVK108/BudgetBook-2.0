import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/get_loans/controllers/get_loans_controller.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class GetLoansView extends GetView<GetLoansController> {
  const GetLoansView({super.key});

  static const Color primary = AppColors.primaryTeal;
  static const Color dark = Color(0xFF263445);
  static const Color label = Color(0xFF75828F);
  static const Color border = Color(0xFFDDECE9);
  static const Color background = Color(0xFFF6F8F8);
  static const Set<String> _renderedLoanFields = {
    'name',
    'loan_name',
    'nameOfLender',
    'name_of_lender',
    'lender_name',
    'lender',
    'loan_type',
    'loanType',
    'loanStatus',
    'loan_status',
    'status',
    'principalAmount',
    'principal_amount',
    'sanctionedAmount',
    'sanctioned_amount',
    'totalAmount',
    'total_amount',
    'total_payable',
    'dueAmount',
    'due_amount',
    'total_outstanding',
    'paidAmount',
    'paid_amount',
    'total_repaid',
    'rateOfInterest',
    'annual_interest_rate',
    'totalInterestAmount',
    'total_interest_amount',
    'total_interest',
    'instalmentAmount',
    'installment_amount',
    'emi_amount',
    'startEMI',
    'first_due_date',
    'endEMI',
    'last_due_date',
    'disbursalAmount',
    'disbursal_amount',
    'principal_outstanding',
    'outstanding_principal',
    'chargesCutting',
    'charges_cutting',
    'loanTerms',
    'tenure_months',
    'dateOfDisbursement',
    'date_of_disbursement',
    'disbursement_date',
    'lender_reference',
    'lenderReference',
    'repayment_account_name',
    'repayment_account_uuid',
    'notes',
    'description',
  };

  String _money(String key) {
    final value = double.tryParse(controller.value(key, fallback: ''));
    if (value == null || !value.isFinite) return '—';
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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8.w, 4.h, 12.w, 4.h),
              decoration: const BoxDecoration(
                gradient: AppColors.bannerGradient,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    tooltip: 'Back',
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Loan details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'HankenGrotesk',
                      ),
                    ),
                  ),
                  Obx(
                    () => IconButton(
                      tooltip: 'Refresh loan details',
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.refreshDetails,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                    ),
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
                        style: const TextStyle(color: Color(0xFF9A3412)),
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
                if (controller.isLoading.value && controller.loan.isEmpty) {
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

                final loanStatus = controller.value('loanStatus', fallback: '');
                final isActive = _isActiveStatus(loanStatus);
                final loanName = controller.valueFor([
                  'name',
                  'loan_name',
                ], fallback: 'Loan details');
                final lender = controller.value('nameOfLender', fallback: '');
                final loanType = controller.valueFor([
                  'loan_type',
                  'loanType',
                ], fallback: '');

                return RefreshIndicator(
                  onRefresh: controller.refreshDetails,
                  color: primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 100.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _loanHero(
                          loanName: loanName,
                          lender: lender,
                          loanType: loanType,
                          status: loanStatus,
                        ),

                        if (controller.focusInstallment != null) ...[
                          SizedBox(height: 16.h),
                          _focusedInstallmentCard(),
                        ],

                        if (controller.loanUuid?.isNotEmpty == true &&
                            isActive) ...[
                          SizedBox(height: 14.h),
                          _loanActionsSection(),
                        ],

                        SizedBox(height: 18.h),

                        Container(
                          padding: EdgeInsets.all(18.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(color: border),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C263445),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeading(
                                'Financial overview',
                                'Track your loan balance and repayment progress',
                              ),
                              SizedBox(height: 16.h),
                              const Divider(color: border),
                              SizedBox(height: 14.h),

                              Container(
                                padding: EdgeInsets.all(13.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FBFA),
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(color: border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LOAN PRINCIPAL',
                                      style: TextStyle(
                                        color: label,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _money('principalAmount'),
                                        style: TextStyle(
                                          color: dark,
                                          fontSize: 25.sp,
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
                                            const Color(0xFFB7791F),
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: _miniAmount(
                                            'AMOUNT DUE',
                                            _money('dueAmount'),
                                            const Color(0xFFE06B71),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    _miniAmount(
                                      'AMOUNT PAID',
                                      _money('paidAmount'),
                                      const Color(0xFF159B76),
                                    ),
                                    if (controller.valueFor([
                                      'principal_outstanding',
                                      'outstanding_principal',
                                    ]).isNotEmpty) ...[
                                      SizedBox(height: 12.h),
                                      _miniAmount(
                                        'PRINCIPAL OUTSTANDING',
                                        _money(
                                          controller.valueFor([
                                            'principal_outstanding',
                                            'outstanding_principal',
                                          ]),
                                        ),
                                        primary,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: _metric(
                                      'INTEREST RATE',
                                      '${controller.value('rateOfInterest', fallback: 'Not provided')}% p.a.',
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

                              SizedBox(height: 10.h),
                              _metric(
                                'SANCTIONED AMOUNT',
                                _money('sanctionedAmount'),
                              ),

                              SizedBox(height: 10.h),

                              _sectionHeading(
                                'Repayment timeline',
                                'Your installment dates and payment progress',
                              ),
                              SizedBox(height: 10.h),
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FBFA),
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(color: border),
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
                                          color: Color(0xFFE06B71),
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
                                    if (_paymentProgress() != null) ...[
                                      SizedBox(height: 14.h),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: _paymentProgress(),
                                          minHeight: 8.h,
                                          backgroundColor: const Color(
                                            0xFFE7ECF2,
                                          ),
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                primary,
                                              ),
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          _paymentProgressLabel(),
                                          style: TextStyle(
                                            color: label,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              SizedBox(height: 12.h),
                              const Divider(color: border),
                              SizedBox(height: 8.h),

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

                              SizedBox(height: 18.h),
                              _sectionHeading(
                                'Loan information',
                                'Terms and account details',
                              ),
                              SizedBox(height: 10.h),
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
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      _loanTermLabel(),
                                      style: TextStyle(
                                        color: const Color(0xFF167D72),
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12.h),
                              _detailLine(
                                'Loan type',
                                controller.valueFor([
                                  'loan_type',
                                  'loanType',
                                ], fallback: 'Not provided'),
                              ),
                              _detailLine(
                                'Lender reference',
                                _safeDisplayText(
                                  controller.valueFor([
                                    'lender_reference',
                                    'lenderReference',
                                  ], fallback: 'Not provided'),
                                ),
                              ),
                              _detailLine(
                                'Repayment account',
                                controller.valueFor([
                                  'repayment_account_name',
                                  'repayment_account_uuid',
                                ], fallback: 'Not provided'),
                              ),
                              _detailLine(
                                'Notes',
                                _safeDisplayText(
                                  controller.valueFor([
                                    'notes',
                                    'description',
                                  ], fallback: 'Not provided'),
                                ),
                              ),
                              _detailLine(
                                'Disbursement date',
                                controller.value(
                                  'dateOfDisbursement',
                                  fallback: 'Not provided',
                                ),
                              ),

                              ..._additionalLoanFields(),

                              SizedBox(height: 17.h),
                              const Divider(color: border),
                              SizedBox(height: 12.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: controller.isSaving.value
                                          ? null
                                          : _showEditDialog,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Edit loan'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF147E73,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFB5F0E4),
                                        ),
                                        backgroundColor: const Color(
                                          0xFFF1FCF9,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        minimumSize: Size(0, 46.h),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: controller.isDeleting.value
                                          ? null
                                          : _confirmDelete,
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                      label: const Text('Delete'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFE74465,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFF8CDD5),
                                        ),
                                        backgroundColor: const Color(
                                          0xFFFFF3F5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        minimumSize: Size(0, 46.h),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (controller.loanUuid?.isNotEmpty == true) ...[
                          SizedBox(height: 18.h),
                          _scheduleSection(),
                          SizedBox(height: 14.h),
                          _paymentsSection(),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loanHero({
    required String loanName,
    required String lender,
    required String loanType,
    required String status,
  }) {
    final progress = _paymentProgress();
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF203B36).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4.h,
            decoration: const BoxDecoration(gradient: AppColors.bannerGradient),
          ),
          Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5F3),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: primary,
                        size: 23.sp,
                      ),
                    ),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOAN ACCOUNT',
                            style: TextStyle(
                              color: label,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            loanName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: dark,
                              fontSize: 16.sp,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'HankenGrotesk',
                            ),
                          ),
                          if (lender.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              lender,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: label, fontSize: 12.sp),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    _statusBadge(status),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F8F7),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OUTSTANDING BALANCE',
                        style: TextStyle(
                          color: label,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _money('dueAmount'),
                          style: TextStyle(
                            color: dark,
                            fontSize: 28.sp,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'HankenGrotesk',
                          ),
                        ),
                      ),
                      if (progress != null) ...[
                        SizedBox(height: 12.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7.h,
                            backgroundColor: const Color(0xFFDCE9E6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              primary,
                            ),
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_money('paidAmount')} repaid',
                                style: TextStyle(color: label, fontSize: 10.sp),
                              ),
                            ),
                            Text(
                              _paymentProgressLabel(),
                              style: TextStyle(
                                color: primary,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _heroMetric(
                        'Principal',
                        _money('principalAmount'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _heroMetric(
                        'Monthly EMI',
                        _money('instalmentAmount'),
                      ),
                    ),
                  ],
                ),
                if (loanType.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: primary,
                        size: 15.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          loanType,
                          style: TextStyle(
                            color: label,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  Widget _heroMetric(String title, String value) {
    return Container(
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.r),
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
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: dark,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loanActionsSection() {
    final hasUnpaidInstallment = _hasUnpaidInstallment();
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Loan actions', 'Payments and records for this loan'),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: Obx(() {
              final loading = controller.isLoadingSchedule.value;
              final scheduleFailed = controller.scheduleError.value.isNotEmpty;
              return ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : scheduleFailed
                    ? controller.fetchSchedule
                    : hasUnpaidInstallment
                    ? _recordPayment
                    : null,
                icon: Icon(
                  scheduleFailed
                      ? Icons.refresh_rounded
                      : Icons.payments_outlined,
                ),
                label: Text(
                  loading
                      ? 'Loading installments...'
                      : scheduleFailed
                      ? 'Retry installment setup'
                      : 'Record EMI Payment',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE7ECEF),
                  disabledForegroundColor: label,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  textStyle: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
          if (!hasUnpaidInstallment &&
              !controller.isLoadingSchedule.value &&
              controller.scheduleError.value.isEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              'No unpaid installment is available for a payment.',
              style: TextStyle(color: label, fontSize: 11.sp),
            ),
          ],
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Get.toNamed(
                  Routes.LOAN_PREPAYMENT,
                  arguments: {'loan': controller.loan},
                );
                if (result == true) await controller.refreshDetails();
              },
              icon: const Icon(Icons.price_change_outlined),
              label: const Text('Principal Prepayment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(color: primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                textStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Get.toNamed(
                  Routes.LOAN_DISBURSEMENT,
                  arguments: {'loan': controller.loan},
                );
                if (result == true) await controller.refreshDetails();
              },
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Record Disbursement'),
              style: OutlinedButton.styleFrom(
                foregroundColor: dark,
                side: const BorderSide(color: border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                textStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 4.w,
            runSpacing: 0,
            children: [
              TextButton.icon(
                onPressed: () =>
                    _scrollToSection(controller.scheduleSectionKey),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('View Repayment Schedule'),
              ),
              TextButton.icon(
                onPressed: () =>
                    _scrollToSection(controller.paymentHistorySectionKey),
                icon: const Icon(Icons.history_rounded),
                label: const Text('View Payment History'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _scrollToSection(GlobalKey key) {
    final sectionContext = key.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: dark,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'HankenGrotesk',
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          subtitle,
          style: TextStyle(color: label, fontSize: 11.sp),
        ),
      ],
    );
  }

  Future<void> _recordPayment({Map<String, dynamic>? installment}) async {
    final loan = Map<String, dynamic>.from(controller.loan)
      ..['installments'] = controller.schedule.toList();
    final result = await Get.toNamed(
      Routes.LOAN_PAYMENT,
      arguments: {
        'loan': loan,
        if (installment != null)
          'installment_uuid':
              (installment['uuid'] ?? installment['installment_uuid'])
                  ?.toString(),
      },
    );
    if (result == true) await controller.refreshDetails();
  }

  Widget _paymentsSection() {
    return Obx(() {
      final paymentCount = controller.totalPayments.value > 0
          ? controller.totalPayments.value
          : controller.payments.length;
      return Container(
        key: controller.paymentHistorySectionKey,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101BBCAC),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payment history',
                    style: TextStyle(
                      color: dark,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (paymentCount > 0)
                  Text(
                    '$paymentCount ${paymentCount == 1 ? 'payment' : 'payments'}',
                    style: TextStyle(color: label, fontSize: 12.sp),
                  ),
                IconButton(
                  tooltip: 'Refresh payment history',
                  onPressed: controller.isLoadingPayments.value
                      ? null
                      : controller.fetchPayments,
                  icon: const Icon(Icons.refresh, color: primary),
                ),
              ],
            ),
            if (controller.isLoadingPayments.value &&
                controller.payments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(color: primary),
                ),
              )
            else if (controller.paymentError.value.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      controller.paymentError.value,
                      style: const TextStyle(color: Color(0xFF9A3412)),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.fetchPayments,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else if (controller.payments.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Center(
                  child: Text(
                    'No payments recorded yet.',
                    style: TextStyle(color: label, fontSize: 13.sp),
                  ),
                ),
              )
            else ...[
              if (controller.isLoadingPayments.value)
                const LinearProgressIndicator(color: primary),
              ...controller.payments.map(_paymentItem),
              if (controller.paymentLoadMoreError.value.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.paymentLoadMoreError.value,
                        style: const TextStyle(color: Color(0xFF9A3412)),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.loadMorePayments,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else if (controller.hasMorePayments)
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: TextButton.icon(
                      onPressed: controller.isLoadingMorePayments.value
                          ? null
                          : controller.loadMorePayments,
                      icon: controller.isLoadingMorePayments.value
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primary,
                              ),
                            )
                          : const Icon(Icons.expand_more),
                      label: Text(
                        controller.isLoadingMorePayments.value
                            ? 'Loading...'
                            : 'Load more payments',
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _paymentItem(Map<String, dynamic> payment) {
    final amount = controller.paymentValue(payment, [
      'amount_paid',
      'amount',
      'payment_amount',
      'paid_amount',
      'amount_received',
    ], fallback: '');
    final date = controller.paymentValue(payment, [
      'payment_date',
      'paid_at',
      'transaction_date',
      'date',
      'created_at',
    ], fallback: 'Date not available');
    final account =
        payment['payment_account'] ??
        payment['repayment_account'] ??
        payment['account'];
    final accountName = controller.paymentValue(payment, [
      'payment_account_name',
      'repayment_account_name',
      'account_name',
    ], fallback: account is Map ? account['name']?.toString() ?? '' : '');
    final reference = controller.paymentValue(payment, [
      'reference',
      'payment_reference',
      'transaction_id',
    ], fallback: '');
    final formattedAmount = _moneyValue(double.tryParse(amount));

    return Container(
      margin: EdgeInsets.only(top: 9.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE9FBF6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: primary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dark,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (accountName.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    accountName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: label, fontSize: 11.sp),
                  ),
                ],
                if (reference.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: label, fontSize: 10.sp),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            formattedAmount,
            style: TextStyle(
              color: const Color(0xFF159B76),
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleSection() {
    return Obx(() {
      return Container(
        key: controller.scheduleSectionKey,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101BBCAC),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Repayment schedule',
                    style: TextStyle(
                      color: dark,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh repayment schedule',
                  onPressed: controller.isLoadingSchedule.value
                      ? null
                      : controller.fetchSchedule,
                  icon: const Icon(Icons.refresh, color: primary),
                ),
              ],
            ),
            if (controller.isLoadingSchedule.value &&
                controller.schedule.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(color: primary),
                ),
              )
            else if (controller.scheduleError.value.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      controller.scheduleError.value,
                      style: const TextStyle(color: Color(0xFF9A3412)),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.fetchSchedule,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else if (controller.schedule.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Center(
                  child: Text(
                    'No repayment schedule available.',
                    style: TextStyle(color: label, fontSize: 13.sp),
                  ),
                ),
              )
            else
              ...controller.schedule.map(_scheduleItem),
          ],
        ),
      );
    });
  }

  Widget _focusedInstallmentCard() {
    final installment = controller.focusInstallment!;
    final isOverdue = controller.focusInstallmentType == 'overdue';
    final dueDate = controller.scheduleValue(installment, [
      'due_date',
      'installment_due_date',
      'payment_date',
    ], fallback: 'Due date unavailable');
    final amount = controller.scheduleOptionalNumber(installment, [
      'amount_due',
      'remaining_amount',
      'installment_amount',
      'emi_amount',
      'due_amount',
      'amount',
    ]);
    final daysOverdue = controller.scheduleValue(installment, [
      'days_overdue',
      'overdue_days',
    ], fallback: '');
    final detail = isOverdue
        ? daysOverdue.isNotEmpty
              ? 'Overdue by $daysOverdue '
                    '${daysOverdue == '1' ? 'day' : 'days'} · $dueDate'
              : '${_relativeDueDate(dueDate)} · $dueDate'
        : '${_relativeDueDate(dueDate)} · $dueDate';
    final accent = isOverdue
        ? const Color(0xFFB54735)
        : const Color(0xFF167D72);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFFFFF6F4) : const Color(0xFFF0FAF8),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isOverdue ? const Color(0xFFF2D0CB) : border),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isOverdue
                  ? Icons.warning_amber_rounded
                  : Icons.event_available_rounded,
              color: accent,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue ? 'Overdue instalment' : 'Upcoming instalment',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: label, fontSize: 10.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            _moneyValue(amount),
            style: TextStyle(
              color: dark,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeDueDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final dueDate = DateTime(parsed.year, parsed.month, parsed.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysUntilDue = dueDate.difference(today).inDays;
    if (daysUntilDue < 0) {
      final days = daysUntilDue.abs();
      return 'Overdue by $days ${days == 1 ? 'day' : 'days'}';
    }
    if (daysUntilDue == 0) return 'Due today';
    if (daysUntilDue == 1) return 'Due tomorrow';
    return 'Due in $daysUntilDue days';
  }

  Widget _scheduleItem(Map<String, dynamic> item) {
    final index = controller.schedule.indexOf(item) + 1;
    final installment = controller.scheduleValue(item, [
      'installment_number',
      'installment_no',
      'sequence',
      'number',
    ], fallback: '$index');
    final dueDate = controller.scheduleValue(item, [
      'due_date',
      'installment_date',
      'payment_date',
      'date',
    ], fallback: 'Date not available');
    final status = controller.scheduleValue(item, [
      'status',
      'payment_status',
    ], fallback: 'Upcoming');
    final installmentUuid =
        (item['uuid'] ?? item['installment_uuid'])?.toString().trim() ?? '';
    final amount = controller.scheduleOptionalNumber(item, [
      'installment_amount',
      'emi_amount',
      'total_amount',
      'amount',
      'due_amount',
    ]);
    final statusLower = status.toLowerCase();
    final isUnpaid =
        statusLower != 'paid' &&
        statusLower != 'completed' &&
        statusLower != 'settled';
    final statusColor = statusLower.contains('paid')
        ? const Color(0xFF159B76)
        : statusLower.contains('overdue') || statusLower.contains('late')
        ? const Color(0xFFE74465)
        : const Color(0xFFB7791F);
    final principal = controller.scheduleOptionalNumber(item, [
      'principal_amount',
      'principal',
    ]);
    final interest = controller.scheduleOptionalNumber(item, [
      'interest_amount',
      'interest',
    ]);
    final breakdown = [
      if (principal != null) 'Principal ${_moneyValue(principal)}',
      if (interest != null) 'Interest ${_moneyValue(interest)}',
    ].join(' · ');

    return Container(
      margin: EdgeInsets.only(top: 9.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9FBF6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  installment,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF167D72),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dueDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dark,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (breakdown.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        breakdown,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: label, fontSize: 10.sp),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _moneyValue(amount),
                    style: TextStyle(
                      color: dark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isUnpaid && installmentUuid.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _recordPayment(installment: item),
                icon: const Icon(Icons.payments_outlined, size: 17),
                label: const Text('Pay this installment'),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  textStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasUnpaidInstallment() {
    return controller.schedule.any((installment) {
      final uuid = (installment['uuid'] ?? installment['installment_uuid'])
          ?.toString()
          .trim();
      final status = (installment['status'] ?? installment['payment_status'])
          ?.toString()
          .trim()
          .toLowerCase();
      return uuid != null &&
          uuid.isNotEmpty &&
          status != 'paid' &&
          status != 'completed' &&
          status != 'settled';
    });
  }

  String _moneyValue(double? value) =>
      value == null ? '—' : '₹${_indianNumber(value)}';

  // ================= STATUS =================

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final isActive = _isActiveStatus(status);
    final isClosed =
        normalized == '0' ||
        normalized == '2' ||
        normalized == 'closed' ||
        normalized == 'completed';
    final color = isActive
        ? const Color(0xFF159B76)
        : isClosed
        ? const Color(0xFFBE123C)
        : label;
    final badgeText = isActive
        ? 'Active'
        : isClosed
        ? 'Closed'
        : status.isEmpty
        ? 'Status unavailable'
        : status;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFEDFBF5)
            : isClosed
            ? const Color(0xFFFFF1F2)
            : const Color(0xFFF1F4F6),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: isActive
              ? const Color(0xFFB8EED8)
              : isClosed
              ? const Color(0xFFF8CDD5)
              : border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8.sp, color: color),
          SizedBox(width: 5.w),
          Text(
            badgeText,
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

  bool _isActiveStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == '1' || normalized == 'active';
  }

  // ================= MINI AMOUNT =================

  Widget _miniAmount(String title, String amount, Color color) {
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

  Widget _metric(String title, String value, {String? subtitle}) {
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
            style: TextStyle(color: label, fontSize: 10.sp),
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
              style: TextStyle(color: primary, fontSize: 10.sp),
            ),
          ],
        ],
      ),
    );
  }

  // ================= SMALL INFO =================

  Widget _smallInfo(String title, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: label, fontSize: 12.sp),
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

  Widget _detailLine(String title, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 9.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132.w,
            child: Text(
              title,
              style: TextStyle(color: label, fontSize: 12.sp),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: dark,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _additionalLoanFields() {
    // The API may include nested objects, arrays and internal metadata. These
    // are not useful when shown as raw JSON on a customer-facing loan screen.
    // Keep only readable, user-facing scalar values here; schedules and
    // payment history already have their own dedicated sections.
    final fields = controller.loan.entries.where((entry) {
      final key = entry.key.toString();
      final normalizedKey = key.toLowerCase();
      final value = entry.value;

      if (_renderedLoanFields.contains(key)) return false;
      if (value == null || value is Map || value is List) return false;
      if (value is String && value.trim().isEmpty) return false;
      if (_isInternalLoanField(normalizedKey)) return false;
      return true;
    }).toList();

    if (fields.isEmpty) return const [];

    return [
      Padding(
        padding: EdgeInsets.only(top: 15.h, bottom: 2.h),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Other loan information',
            style: TextStyle(
              color: dark,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      ...fields.map((entry) {
        return _detailLine(
          _prettyFieldName(entry.key.toString()),
          _friendlyLoanValue(entry.value),
        );
      }),
    ];
  }

  bool _isInternalLoanField(String key) {
    const internalExactKeys = {
      'id',
      'uuid',
      'loan_uuid',
      'user_uuid',
      'customer_uuid',
      'created_at',
      'updated_at',
      'deleted_at',
      'createdat',
      'updatedat',
      'deletedat',
      'meta',
      '_meta',
      'raw_response',
      'response',
      'headers',
      'errors',
      'timestamp',
    };
    if (internalExactKeys.contains(key)) return true;
    return key.endsWith('_uuid') ||
        key.endsWith('_id') ||
        key.contains('raw_json') ||
        key.contains('debug') ||
        key.contains('metadata');
  }

  String _friendlyLoanValue(dynamic value) {
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num) return value.toString();
    return _safeDisplayText(value?.toString() ?? '');
  }

  String _safeDisplayText(String value) {
    final text = value.trim();
    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'n/a') {
      return 'Not provided';
    }
    // Avoid leaking a serialized API object into a customer-facing label.
    if ((text.startsWith('{') && text.endsWith('}')) ||
        (text.startsWith('[') && text.endsWith(']'))) {
      return 'Additional details available';
    }
    return text;
  }

  String _loanTermLabel() {
    final raw = controller.value('loanTerms', fallback: '').trim();
    final months = double.tryParse(raw);
    if (months != null && months.isFinite && months > 0) {
      return '${months == months.roundToDouble() ? months.toInt() : months} months';
    }
    return _safeDisplayText(raw);
  }

  String _prettyFieldName(String field) {
    final spaced = field
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();
    if (spaced.isEmpty) return field;
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  double? _paymentProgress() {
    final total = double.tryParse(
      controller.value('totalAmount', fallback: ''),
    );
    final paid = double.tryParse(controller.value('paidAmount', fallback: ''));
    if (total == null || paid == null || total <= 0) return null;
    return (paid / total).clamp(0.0, 1.0);
  }

  String _paymentProgressLabel() {
    final progress = _paymentProgress();
    if (progress == null) return 'Payment progress not provided';
    return '${(progress * 100).toStringAsFixed(0)}% paid';
  }

  // ================= EMPTY STATE =================

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(25.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined, size: 55.sp, color: primary),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: label, fontSize: 15.sp),
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
                  _editField(
                    disbursementDate,
                    'Disbursement date (YYYY-MM-DD)',
                  ),
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

      final sanctionedValue = double.tryParse(sanctioned.text.trim());
      final disbursalValue = double.tryParse(disbursal.text.trim());
      final chargesValue = double.tryParse(charges.text.trim());
      final termValue = int.tryParse(terms.text.trim());
      final rateValue = double.tryParse(interest.text.trim());

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
      await controller.updateLoan({
        'nameOfLender': lender.text.trim(),
        'sanctionedAmount': sanctionedValue.toStringAsFixed(2),
        'dateOfDisbursement': dates[0],
        'disbursalAmount': disbursalValue.toStringAsFixed(2),
        'chargesCutting': chargesValue.toStringAsFixed(2),
        'loanTerms': termValue.toString(),
        'rateOfInterest': rateValue.toStringAsFixed(2),
        'startEMI': dates[1],
        'endEMI': dates[2],
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
