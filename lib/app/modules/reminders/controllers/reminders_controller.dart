import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RemindersController extends GetxController {
  final TextEditingController descriptionController =
      TextEditingController();

  /// Change this to DateTime(2023, 10, 24) when you need
  /// the exact date displayed in the reference design.
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  String get formattedSelectedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final date = selectedDate.value;
    final month = months[date.month - 1];

    return '$month ${date.day}, ${date.year}';
  }

  Future<void> selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select transaction date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF079B8D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF333333),
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Color(0xFF079B8D),
              headerForegroundColor: Colors.white,
            ),
            textTheme: Theme.of(context).textTheme.apply(
                  fontFamily: 'HankenGrotesk',
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      selectedDate.value = pickedDate;
    }
  }

  void saveEntry() {
    FocusManager.instance.primaryFocus?.unfocus();

    final String description = descriptionController.text.trim();

    /// Add API call or local database save logic here.
    debugPrint('Reminder date: $formattedSelectedDate');
    debugPrint('Description: $description');

    Get.snackbar(
      'Entry Saved',
      'Your reminder entry has been saved successfully.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF079B8D),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
      ),
    );
  }

  void onMenuPressed() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Clear Entry',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              descriptionController.clear();
              selectedDate.value = DateTime.now();
              Get.back();
            },
          ),
        ),
      ),
    );
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}