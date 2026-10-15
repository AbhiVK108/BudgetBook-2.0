
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/get_lend_controller.dart';

class GetLendView extends GetView<GetLendController> {
  const GetLendView({super.key});

  static const Color primaryColor = Color(0xFF009F89);
  static const Color scaffoldColor = Color(0xFFF4F8F7);
  static const Color darkColor = Color(0xFF182337);
  static const Color labelColor = Color(0xFF52627A);
  static const Color mutedColor = Color(0xFF8B9CB5);
  static const Color borderColor = Color(0xFFE8EEF3);
  static const String fontFamily = 'HankenGrotesk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value && controller.lends.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.lends.isEmpty) {
          return _errorState();
        }

        if (controller.lends.isEmpty) {
          return _emptyState();
        }

        final name = controller.personName;
        final amount = controller.amountValue;
        final interest = controller.interestValue;

        final note = controller.description.isNotEmpty
            ? controller.description
            : 'No description';

        return RefreshIndicator(
          color: primaryColor,
          onRefresh: controller.fetchLends,
          child: ListView(
            padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 30.h),
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(27.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF203B36).withValues(alpha: 0.07),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // TOP GRADIENT ACCENT
                    Container(
                      height: 4.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF34D399),
                            Color(0xFF2DD4BF),
                            Color(0xFF22D3EE),
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(27.r),
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20.w,
                        18.h,
                        20.w,
                        20.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PERSON DETAILS AND ACTION BUTTONS
                          Row(
                            children: [
                              Container(
                                height: 52.w,
                                width: 52.w,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5264),
                                      Color(0xFFFF941D),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(17.r),
                                  border: Border.all(
                                    color: const Color(0xFFFFE4D9),
                                    width: 3,
                                  ),
                                ),
                                child: Text(
                                  _recordNumber(),
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GIVEN TO',
                                      style: TextStyle(
                                        color: mutedColor,
                                        fontSize: 11.sp,
                                        fontFamily: fontFamily,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name.isEmpty ? 'Unknown' : name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: darkColor,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: fontFamily,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 5.w),
                                        Icon(
                                          Icons.verified,
                                          size: 14.sp,
                                          color: const Color(0xFFDDEFEA),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _actionButton(
                                icon: Icons.edit_outlined,
                                color: const Color(0xFF43556D),
                                onTap: _editLend,
                              ),
                              SizedBox(width: 5.w),
                              _actionButton(
                                icon: Icons.delete_outline,
                                color: const Color(0xFFFF3151),
                                onTap: _showDeleteDialog,
                              ),
                            ],
                          ),

                          SizedBox(height: 12.h),

                          // AMOUNT AND INTEREST
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatCurrency(amount),
                                    style: TextStyle(
                                      color: darkColor,
                                      fontSize: 29.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      fontFamily: fontFamily,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FFF8),
                                  border: Border.all(
                                    color: const Color(0xFFAEF3D6),
                                  ),
                                  borderRadius: BorderRadius.circular(22.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: primaryColor,
                                      size: 13.sp,
                                    ),
                                    SizedBox(width: 3.w),
                                    Text(
                                      _formatCurrency(interest),
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: fontFamily,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12.h),

                          // NOTE
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 9.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FA),
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(13.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: mutedColor,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 9.w),
                                Text(
                                  'Note:',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 12.sp,
                                    fontFamily: fontFamily,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    '“$note”',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: darkColor,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: fontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 10.h),
                          Divider(
                            color: borderColor,
                            thickness: 0.8,
                            height: 1,
                          ),
                          SizedBox(height: 10.h),

                          // GIVEN DATE, RETURN DATE, INTEREST
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 11.w,
                              vertical: 13.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FBFC),
                              borderRadius: BorderRadius.circular(17.r),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _dateInfo(
                                    'GIVEN ON',
                                    controller.receiveDate,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: _dateInfo(
                                    'RETURN BY',
                                    controller.returnDate,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: _dateInfo(
                                    'INTEREST',
                                    _formatCurrency(interest),
                                    isInterest: true,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // RECEIVED BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 43.h,
                            child: ElevatedButton(
                              onPressed: _showReceivedDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.r),
                                ),
                              ),
                              child: Text(
                                'Received',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: fontFamily,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Get.toNamed(Routes.POST_LEND);
          await controller.fetchLends();
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // APP BAR
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Obx(
        () => Text(
          'Details for ${controller.personName.isEmpty ? 'Lend' : controller.personName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'refresh') controller.fetchLends();
            if (value == 'edit') _editLend();
            if (value == 'delete') _showDeleteDialog();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'refresh',
              child: Text('Refresh'),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Text('Edit lend'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete lend'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateInfo(
    String title,
    String value, {
    bool isInterest = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isInterest ? primaryColor : mutedColor,
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isInterest ? primaryColor : darkColor,
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 36.w,
          height: 38.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE6EBF2)),
          ),
          child: Icon(icon, size: 17.sp, color: color),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 55.sp,
              color: primaryColor,
            ),
            SizedBox(height: 12.h),
            Text(
              'No lend records found.',
              style: TextStyle(
                color: labelColor,
                fontSize: 15.sp,
                fontFamily: fontFamily,
              ),
            ),
            TextButton(
              onPressed: controller.fetchLends,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 45,
              color: Colors.redAccent,
            ),
            SizedBox(height: 12.h),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontFamily: fontFamily,
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: controller.fetchLends,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _recordNumber() {
    final id = controller.selectedLend['id']?.toString();
    if (id == null || id.isEmpty) return '1';
    return id;
  }

  String _formatCurrency(double value) {
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    return '₹$formatted';
  }

  // EDIT
  Future<void> _editLend() async {
    await Get.toNamed(
      Routes.POST_LEND,
      arguments: Map<String, dynamic>.from(controller.selectedLend),
    );
    await controller.fetchLends();
  }

  // DELETE
  Future<void> _showDeleteDialog() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete lend record?'),
        content: const Text(
          'Are you sure you want to delete this lend record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3151),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Connect this to your actual delete API/controller method.
    // Do not display a success message until the API confirms deletion.
    Get.snackbar(
      'Delete',
      'Add your delete API method here to delete this lend record.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // RECEIVED
  Future<void> _showReceivedDialog() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Mark as received?'),
        content: const Text(
          'Confirm that this lend amount has been received back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Connect this to the backend status/update API when available.
    Get.snackbar(
      'Received',
      'Connect the Received action to your API to save this status.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}