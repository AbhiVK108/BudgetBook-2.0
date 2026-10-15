
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/get_reminder_controller.dart';

class GetReminderView extends GetView<GetReminderController> {
  const GetReminderView({super.key});

  static const Color primaryColor = Color(0xFF079B8D);
  static const Color scaffoldColor = Color(0xFFF6F6F6);
  static const String fontFamily = 'HankenGrotesk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (controller.reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 55.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No reminders found',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: controller.fetchReminders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: controller.fetchReminders,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              itemCount: controller.reminders.length,
              itemBuilder: (context, index) {
                final reminder = controller.reminders[index];

                final description =
                    reminder['description']?.toString() ??
                    'No description';

                final reminderDate =
                    reminder['reminderDate']?.toString() ??
                    reminder['reminder_date']?.toString() ??
                    'No date';

                final avatarText = description.trim().isNotEmpty
                    ? description.trim()[0].toUpperCase()
                    : 'R';

                return Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x331BBCAC),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22.r,
                        backgroundColor: const Color(0xFFD4E6E4),
                        child: Text(
                          avatarText,
                          style: TextStyle(
                            color: const Color(0xFF0F8F7D),
                            fontWeight: FontWeight.w600,
                            fontFamily: fontFamily,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: fontFamily,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 7.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 16.sp,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: Text(
                                    reminderDate,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontFamily: fontFamily,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.notifications_active_outlined,
                        color: primaryColor,
                        size: 22.sp,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: primaryColor,
      surfaceTintColor: primaryColor,
      toolbarHeight: 66.h,
      leadingWidth: 54.w,
      leading: IconButton(
        onPressed: Get.back,
        splashRadius: 21.r,
        icon: Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 21.sp,
        ),
      ),
      titleSpacing: 0,
      title: Text(
        'Reminder',
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: controller.onMenuPressed,
          splashRadius: 21.r,
          icon: Icon(
            Icons.more_vert,
            color: Colors.white,
            size: 23.sp,
          ),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
}
