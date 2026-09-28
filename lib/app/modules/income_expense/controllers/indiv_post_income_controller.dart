import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IndivPostIncomeController extends GetxController {
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final selectedDate = "Oct 24, 2023".obs;

  void pickDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      selectedDate.value = "${picked.day}-${picked.month}-${picked.year}";
    }
  }
}
