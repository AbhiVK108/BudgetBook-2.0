import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/postloan_controller.dart';

class PostloanView extends GetView<PostloanController> {
  PostloanView({super.key});

  static const Color primary = Color(0xFF079B8D);
  static const Color dark = Color(0xFF374151);
  static const Color hint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFDCE4EC);
  static const Color background = Color(0xFFF5F6F6);

  // Form controllers
  static final lenderName = TextEditingController();
  static final sanctionedAmount = TextEditingController();
  static final disbursalAmount = TextEditingController();
  static final charges = TextEditingController();
  static final duration = TextEditingController();
  static final monthlyInterest = TextEditingController();

  static final Rx<DateTime?> disbursementDate = Rx<DateTime?>(null);
  static final Rx<DateTime?> startEmiDate = Rx<DateTime?>(null);
  static final Rx<DateTime?> endEmiDate = Rx<DateTime?>(null);

  double get sanctioned => double.tryParse(sanctionedAmount.text) ?? 0;
  double get disbursed => double.tryParse(disbursalAmount.text) ?? 0;
  double get chargeAmount => double.tryParse(charges.text) ?? 0;
  double get monthlyRate => double.tryParse(monthlyInterest.text) ?? 0;
  int get months => int.tryParse(duration.text) ?? 0;

  double get totalInterest => monthlyRate * months;
  double get emi => months > 0 ? (disbursed + totalInterest) / months : 0;
  double get totalAmount => disbursed + totalInterest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 20.h),
                child: Column(
                  children: [
                    // STEP 1
                    _section(
                      title: 'LENDER & DISBURSEMENT',
                      icon: Icons.contact_page_outlined,
                      step: 'Step 1 of 3',
                      children: [
                        _label('Name of Lender'),
                        SizedBox(height: 8.h),
                        _input(
                          controller: lenderName,
                          hint: 'e.g. HDFC Bank, SBI, or Private Lender',
                          icon: Icons.account_balance_outlined,
                        ),
                        SizedBox(height: 18.h),

                        Row(
                          children: [
                            Expanded(child: _label('Sanctioned Amount')),
                            SizedBox(width: 12.w),
                            Expanded(child: _label('Disbursal Amount')),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: _input(
                                controller: sanctionedAmount,
                                hint: '0.00',
                                icon: Icons.currency_rupee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) => _updateCalculations(),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _input(
                                controller: disbursalAmount,
                                hint: '0.00',
                                icon: Icons.currency_rupee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) => _updateCalculations(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18.h),

                        Row(
                          children: [
                            Expanded(child: _label('Disbursement Date')),
                            SizedBox(width: 12.w),
                            Expanded(child: _label('Charges Cutting')),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => _dateField(
                                  date: disbursementDate.value,
                                  onTap: () =>
                                      _pickDate(context, disbursementDate),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _input(
                                controller: charges,
                                hint: '0.00',
                                icon: Icons.currency_rupee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) => _updateCalculations(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // STEP 2
                    _section(
                      title: 'TERMS & INTEREST STRUCTURE',
                      icon: Icons.percent,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _label('Loan Terms (Duration)')),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFFFFB),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                'Months / Tenure',
                                style: TextStyle(
                                  color: const Color(0xFF26796F),
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        _input(
                          controller: duration,
                          hint: 'e.g. 12 Months / 1 Year',
                          icon: Icons.schedule,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateCalculations(),
                        ),
                        SizedBox(height: 22.h),

                        Row(
                          children: [
                            Expanded(child: _label('Monthly Interest (₹)')),
                            Obx(
                              () => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9FBF3),
                                  borderRadius: BorderRadius.circular(18.r),
                                  border: Border.all(
                                    color: const Color(0xFFB9EED8),
                                  ),
                                ),
                                child: Text(
                                  'Percentage: ${_interestPercent.toStringAsFixed(2)} %',
                                  style: TextStyle(
                                    color: const Color(0xFF166653),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        _input(
                          controller: monthlyInterest,
                          hint: 'Enter monthly interest value',
                          icon: Icons.currency_rupee,
                          suffixText: '/month',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => _updateCalculations(),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14.sp, color: hint),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'Enter interest in Rupees (₹). Auto-computes equivalent APR.',
                                style: TextStyle(color: hint, fontSize: 11.sp),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // STEP 3
                    _section(
                      title: 'EMI & TIMELINE SCHEDULE',
                      icon: Icons.event_available_outlined,
                      children: [
                        _label('Total Interest Amount'),
                        SizedBox(height: 8.h),
                        Obx(
                          () => _readOnlyAmount(
                            '₹ ${_totalInterest.value.toStringAsFixed(2)}',
                          ),
                        ),
                        SizedBox(height: 18.h),

                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5FCFA),
                            border: Border.all(color: const Color(0xFFC9F5EA)),
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INSTALMENT AMOUNT (PER EMI)',
                                style: TextStyle(
                                  color: const Color(0xFF245B56),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Obx(
                                () => Text(
                                  '₹ ${_emi.value.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 23.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 22.h),

                        Row(
                          children: [
                            Expanded(child: _label('Repayment Timeline')),
                            Text(
                              'Monthly Cycle',
                              style: TextStyle(
                                color: hint,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Start EMI',
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'End EMI',
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => _dateField(
                                  date: startEmiDate.value,
                                  onTap: () => _pickDate(context, startEmiDate),
                                  compact: true,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Obx(
                                () => _dateField(
                                  date: endEmiDate.value,
                                  onTap: () => _pickDate(context, endEmiDate),
                                  compact: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        Obx(
                          () => Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(18.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF11172A),
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'TOTAL AMOUNT',
                                    style: TextStyle(
                                      color: const Color(0xFFD1D5E1),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹',
                                  style: TextStyle(
                                    color: const Color(0xFF2DD4BF),
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 20.w),
                                Text(
                                  _totalAmount.value.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 28.h),

                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 60.h,
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : _saveLoan,
                          icon: controller.isLoading.value
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            controller.isLoading.value
                                ? 'Saving...'
                                : 'Save Loan',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                          ),
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
    );
  }

  final RxDouble _interestPercent = 0.0.obs;
  final RxDouble _totalInterest = 0.0.obs;
  final RxDouble _emi = 0.0.obs;
  final RxDouble _totalAmount = 0.0.obs;

  void _updateCalculations() {
    final amount = double.tryParse(disbursalAmount.text) ?? 0;
    final interest = double.tryParse(monthlyInterest.text) ?? 0;
    final term = int.tryParse(duration.text) ?? 0;

    _interestPercent.value = amount > 0 ? (interest / amount) * 100 : 0;
    _totalInterest.value = interest * term;
    _emi.value = term > 0 ? (amount + _totalInterest.value) / term : 0;
    _totalAmount.value = amount + _totalInterest.value;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _saveLoan() async {
    if (lenderName.text.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter the lender name');
      return;
    }

    if (!sanctioned.isFinite ||
        !disbursed.isFinite ||
        sanctioned <= 0 ||
        disbursed <= 0) {
      Get.snackbar('Required', 'Enter valid loan amounts');
      return;
    }

    if (!chargeAmount.isFinite || chargeAmount < 0) {
      Get.snackbar('Invalid Charges', 'Enter valid charges.');
      return;
    }

    if (months <= 0) {
      Get.snackbar('Required', 'Enter the loan duration in months');
      return;
    }

    if (!monthlyRate.isFinite || monthlyRate < 0) {
      Get.snackbar('Invalid Interest', 'Enter a valid monthly interest.');
      return;
    }

    final disbursement = disbursementDate.value;
    final startEmi = startEmiDate.value;
    final endEmi = endEmiDate.value;
    if (disbursement == null || startEmi == null || endEmi == null) {
      Get.snackbar(
        'Required',
        'Select the disbursement date and EMI start and end dates.',
      );
      return;
    }
    if (endEmi.isBefore(startEmi)) {
      Get.snackbar('Invalid Date', 'End EMI cannot be before Start EMI.');
      return;
    }

    final body = <String, String>{
      'nameOfLender': lenderName.text.trim(),
      'sanctionedAmount': sanctioned.toStringAsFixed(2),
      'dateOfDisbursement': _formatDate(disbursement),
      'disbursalAmount': disbursed.toStringAsFixed(2),
      'chargesCutting': chargeAmount.toStringAsFixed(2),
      'loanTerms': months.toString(),
      'rateOfInterest': monthlyRate.toStringAsFixed(2),
      'totalInterestAmount': totalInterest.toStringAsFixed(2),
      'instalmentAmount': emi.toStringAsFixed(2),
      'startEMI': _formatDate(startEmi),
      'endEMI': _formatDate(endEmi),
      'totalAmount': totalAmount.toStringAsFixed(2),
    };

    final saved = await controller.postLoan(body);
    if (!saved) return;

    lenderName.clear();
    sanctionedAmount.clear();
    disbursalAmount.clear();
    charges.clear();
    duration.clear();
    monthlyInterest.clear();
    disbursementDate.value = null;
    startEmiDate.value = null;
    endEmiDate.value = null;
    _updateCalculations();
  }

  Widget _appBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18.r),
          bottomRight: Radius.circular(18.r),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 27.sp),
          ),
          SizedBox(width: 25.w),
          Text(
            'Loan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'HankenGrotesk',
            ),
          ),
          const Spacer(),
          Icon(Icons.more_vert, color: Colors.white, size: 27.sp),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    String? step,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFC9F1EA)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.12),
            offset: Offset(0, 5.h),
            blurRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 21.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: dark,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (step != null)
                Text(
                  step,
                  style: TextStyle(color: hint, fontSize: 11.sp),
                ),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(height: 1, color: const Color(0xFFEDF0F2)),
          SizedBox(height: 18.h),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        color: const Color(0xFF4B5563),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: _decoration(hint: hint, icon: icon, suffixText: suffixText),
    );
  }

  InputDecoration _decoration({
    required String hint,
    IconData? icon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF94A3B8),
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: hintColor, size: 21.sp),
      suffixText: suffixText,
      suffixStyle: TextStyle(color: hintColor, fontSize: 12.sp),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 17.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  static const Color hintColor = Color(0xFF94A3B8);

  Widget _dateField({
    required DateTime? date,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final text = date == null
        ? 'MM/DD/YYYY'
        : '${date.month.toString().padLeft(2, '0')}/'
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.year}';

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _decoration(hint: '').copyWith(
          prefixIcon: null,
          suffixIcon: Icon(
            Icons.calendar_month_outlined,
            color: primary,
            size: compact ? 19.sp : 21.sp,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: dark,
            fontSize: compact ? 11.sp : 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, Rx<DateTime?> target) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: target.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      target.value = picked;
    }
  }

  Widget _readOnlyAmount(String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: hint,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
