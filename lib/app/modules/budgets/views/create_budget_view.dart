import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/create_budget_controller.dart';

class CreateBudgetView extends GetView<CreateBudgetController> {
  const CreateBudgetView({super.key});
  static const ink = Color(0xFF233445);
  static const muted = Color(0xFF74818D);
  static const surface = Color(0xFFF7F9FA);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F4F5),
    appBar: AppBar(
      backgroundColor: AppColors.primaryTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Create a money plan',
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
      ),
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      actions: [
        IconButton(
          tooltip: 'Cancel draft',
          onPressed: Get.back,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 18.h),
      child: Column(
        children: [
          _modeSwitch(),
          SizedBox(height: 14.h),
          _section('Budget Identity', [
            _label('BUDGET NAME'),
            _input(controller.nameController, 'Monthly Groceries'),
            SizedBox(height: 10.h),
            _label('EXPENSE CATEGORY'),
            _infoTile(
              Icons.shopping_basket_outlined,
              'Food & Groceries',
              'Daily essentials, kitchen stock & pantry',
              trailing: 'Essential  ›',
            ),
          ]),
          SizedBox(height: 12.h),
          _section('Financial Cap & Cadence', [
            _label('MONTHLY SPENDING CAP', trailing: 'Recommended: ₹30,000'),
            _input(
              controller.limitController,
              '30,000.00',
              prefix: '₹ ',
              keyboard: TextInputType.number,
            ),
            SizedBox(height: 10.h),
            _label('BILLING PERIOD CYCLE'),
            _infoTile(
              Icons.calendar_month_outlined,
              'Monthly (Calendar Month)',
              'Resets automatically on 1st of every month',
              trailing: '🔒',
            ),
          ]),
          SizedBox(height: 12.h),
          _section('Active Window & Alerts', [
            Row(
              children: [
                Expanded(child: _dateTile('START DATE', '01 Nov 2026')),
                SizedBox(width: 8.w),
                Expanded(child: _dateTile('END DATE', '30 Nov 2026')),
              ],
            ),
            SizedBox(height: 10.h),
            _label('NOTIFICATION THRESHOLD', trailing: '80% reached alert'),
            Obx(
              () => Wrap(
                spacing: 8.w,
                children: [50, 75, 90, 100]
                    .map(
                      (value) => _threshold(
                        value,
                        controller.selectedThresholds.contains(value),
                      ),
                    )
                    .toList(),
              ),
            ),
            SizedBox(height: 8.h),
            _hint(
              'Push notification dispatched immediately when expenses hit cap.',
            ),
          ]),
          SizedBox(height: 12.h),
          _section('Planning Memo & Notes', [
            _input(
              controller.notesController,
              'Add a note about this budget',
              maxLines: 3,
            ),
          ]),
          SizedBox(height: 12.h),
          _section('Financial Parameter', [
            _label('DESCRIPTION', trailing: 'Minimum 120 characters'),
            SizedBox(height: 6.h),
            _input(
              controller.financialParameterController,
              'Describe the financial rules, limits, and savings goals for this budget',
              maxLines: 5,
            ),
          ]),
          SizedBox(height: 22.h),
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.createBudget,
                icon: controller.isSaving.value
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline, size: 17),
                label: Text(
                  controller.isSaving.value ? 'Creating...' : 'Create Budget',
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: Get.back,
            child: const Text(
              'Cancel & Discard Draft',
              style: TextStyle(color: muted),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _modeSwitch() => Container(
    padding: EdgeInsets.all(4.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9.r),
    ),
    child: Row(
      children: [
        Expanded(child: _mode('▣  Budget', true)),
        Expanded(child: _mode('♧  Savings goal', false)),
      ],
    ),
  );

  Widget _mode(String text, bool selected) => Container(
    padding: EdgeInsets.symmetric(vertical: 9.h),
    decoration: BoxDecoration(
      color: selected ? AppColors.primaryTeal : Colors.transparent,
      borderRadius: BorderRadius.circular(7.r),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 10.sp,
        color: selected ? Colors.white : ink,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _section(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: ink,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10.h),
        ...children,
      ],
    ),
  );

  Widget _label(String value, {String? trailing}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 8.sp,
          color: muted,
          fontWeight: FontWeight.w500,
          letterSpacing: .2,
        ),
      ),
      if (trailing != null)
        Text(
          trailing,
          style: TextStyle(
            fontSize: 8.sp,
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
    ],
  );

  Widget _input(
    TextEditingController textController,
    String hint, {
    String? prefix,
    TextInputType? keyboard,
    int maxLines = 1,
  }) => TextField(
    controller: textController,
    keyboardType: keyboard,
    maxLines: maxLines,
    style: TextStyle(fontSize: 11.sp, color: ink),
    decoration: InputDecoration(
      hintText: hint,
      prefixText: prefix,
      hintStyle: TextStyle(fontSize: 11.sp, color: muted),
      filled: true,
      fillColor: surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
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
        borderSide: const BorderSide(color: AppColors.primaryTeal),
      ),
    ),
  );

  Widget _infoTile(
    IconData icon,
    String title,
    String subtitle, {
    String? trailing,
  }) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(9.r),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(7.w),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 8.sp, color: muted),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(fontSize: 8.sp, color: muted),
          ),
      ],
    ),
  );

  Widget _dateTile(String label, String date) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(label),
      SizedBox(height: 5.h),
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 12,
              color: AppColors.primaryTeal,
            ),
            SizedBox(width: 5.w),
            Text(
              date,
              style: TextStyle(
                fontSize: 9.sp,
                color: ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _threshold(int value, bool selected) => GestureDetector(
    onTap: () {
      if (selected) {
        controller.selectedThresholds.remove(value);
      } else {
        controller.selectedThresholds.add(value);
        controller.selectedThresholds.sort();
      }
    },
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryTeal : surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        '$value%',
        style: TextStyle(
          fontSize: 9.sp,
          color: selected ? Colors.white : muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
  Widget _hint(String text) => Row(
    children: [
      const Icon(Icons.notifications_none_rounded, size: 14, color: muted),
      SizedBox(width: 5.w),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 8.sp, color: muted),
        ),
      ),
    ],
  );
}
