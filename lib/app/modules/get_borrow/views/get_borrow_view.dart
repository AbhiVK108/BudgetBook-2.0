import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/get_borrow_controller.dart';

class GetBorrowView extends GetView<GetBorrowController> {
  const GetBorrowView({super.key});

  static const Color primaryColor = Color(0xFF079B8D);
  static const Color secondaryColor = Color(0xFF009B83);
  static const Color scaffoldColor = Color(0xFFF5F8F7);
  static const Color labelColor = Color(0xFF4F4F4F);
  static const Color mutedColor = Color(0xFF8B9CB5);
  static const String fontFamily = 'HankenGrotesk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value && controller.borrows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.borrows.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.errorMessage.value),
                TextButton(
                  onPressed: controller.fetchBorrows,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final name = controller.personName;
        final amount = double.tryParse(controller.amount) ?? 0;
        final interest = double.tryParse(controller.interest) ?? 0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 20.w, left: 20.w, right: 20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(27.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  width: 375,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF34D399),
                        Color(0xFF2DD4BF),
                        Color(0xff22D3EE),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 17.h),

                // Person details and edit/delete buttons
                Row(
                  children: [
                    Container(
                      height: 52.w,
                      width: 52.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5264), Color(0xFFFF941D)],
                        ),
                        borderRadius: BorderRadius.circular(17.r),
                        border: Border.all(
                          color: const Color(0xFFFFE4D9),
                          width: 3,
                        ),
                      ),
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w700,
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
                            'RECEIVED FROM',
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 11.sp,
                              fontFamily: fontFamily,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Text(
                                name.isEmpty ? 'Unknown' : name,
                                style: TextStyle(
                                  color: const Color(0xFF182337),
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: fontFamily,
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

                    _iconButton(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF43556D),
                      onTap: _showEditDialog,
                    ),

                    SizedBox(width: 5.w),

                    _iconButton(
                      icon: Icons.delete_outline,
                      color: const Color(0xFFFF3151),
                      onTap: () {
                        _showDeleteDialog();
                      },
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Amount and additional interest
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}',
                        style: TextStyle(
                          color: const Color(0xFF182337),
                          fontSize: 29.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF8),
                        border: Border.all(color: const Color(0xFFAEF3D6)),
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: primaryColor, size: 13.sp),
                          SizedBox(width: 3.w),
                          Text(
                            '₹${interest.toStringAsFixed(interest.truncateToDouble() == interest ? 0 : 2)}',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Note
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 9.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FA),
                    border: Border.all(color: const Color(0xFFE7EDF4)),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Text(
                    controller.description.isEmpty
                        ? 'No description'
                        : controller.description,
                    style: TextStyle(
                      color: Color(0xff0F172A),
                      fontSize: 12.sp,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                Divider(
                  color: const Color(0xFFE7EDF4),
                  height: 10.h,
                  thickness: 0.8,
                ),

                SizedBox(height: 9.h),

                // Dates and interest
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 15.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    border: Border.all(color: const Color(0xFFEAF0F5)),
                    borderRadius: BorderRadius.circular(17.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _infoColumn(
                          'RECEIVED ON',
                          controller.receiveDate,
                        ),
                      ),
                      Expanded(
                        child: _infoColumn('RETURN BY', controller.returnDate),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INTEREST',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: fontFamily,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '₹${interest.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 17.h),

                // Received button
                SizedBox(
                  width: double.infinity,
                  height: 41.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [secondaryColor, primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.snackbar(
                          'paid',
                          'Connect your received API here.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        'Paid',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _showEditDialog() async {
    final nameController = TextEditingController(text: controller.personName);
    final phoneController = TextEditingController(text: controller.phone);
    final amountController = TextEditingController(text: controller.amount);
    final interestController = TextEditingController(text: controller.interest);
    final receiveDateController = TextEditingController(
      text: controller.receiveDate,
    );
    final returnDateController = TextEditingController(
      text: controller.returnDate,
    );
    final descriptionController = TextEditingController(
      text: controller.description,
    );

    try {
      await Get.dialog<void>(
        AlertDialog(
          title: const Text('Update borrow'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(nameController, 'Person name'),
                _editField(phoneController, 'Phone number'),
                _editField(amountController, 'Amount'),
                _editField(interestController, 'Interest rate'),
                _editField(receiveDateController, 'Receive date (YYYY-MM-DD)'),
                _editField(returnDateController, 'Return date (YYYY-MM-DD)'),
                _editField(descriptionController, 'Description'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final updated = await controller.updateBorrow(
                  personName: nameController.text,
                  phone: phoneController.text,
                  amount: amountController.text,
                  interest: interestController.text,
                  receiveDate: receiveDateController.text,
                  returnDate: returnDateController.text,
                  description: descriptionController.text,
                );
                if (updated) Get.back();
              },
              child: const Text('Update'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      amountController.dispose();
      interestController.dispose();
      receiveDateController.dispose();
      returnDateController.dispose();
      descriptionController.dispose();
    }
  }

  Widget _editField(TextEditingController textController, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextField(
        controller: textController,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // Edit and delete icon buttons
  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13.r),
      child: Container(
        width: 38.w,
        height: 42.h,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          border: Border.all(color: const Color(0xFFEDF1F6)),
          borderRadius: BorderRadius.circular(13.r),
        ),
        child: Icon(icon, color: color, size: 19.sp),
      ),
    );
  }

  // Date and interest information
  Widget _infoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: mutedColor,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF182337),
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ],
    );
  }

  // App bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: primaryColor,
      surfaceTintColor: primaryColor,
      toolbarHeight: 76.h,
      leadingWidth: 54.w,
      leading: IconButton(
        onPressed: Get.back,
        icon: Icon(Icons.arrow_back, color: Colors.white, size: 21.sp),
      ),
      titleSpacing: 0,
      title: Obx(
        () => Text(
          'Details for ${controller.personName.isEmpty ? 'borrow' : controller.personName}',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'edit') {
              Get.snackbar('Edit', 'Open the edit screen here');
            } else if (value == 'delete') {
              _showDeleteDialog();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
    );
  }

  // Delete confirmation dialog
  void _showDeleteDialog() {
    Get.defaultDialog(
      title: 'Delete Lend',
      middleText: 'Are you sure you want to delete this record?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFFF3151),
      onConfirm: () {
        Get.back();
        Get.snackbar(
          'Delete',
          'Connect your delete API here.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }
}
