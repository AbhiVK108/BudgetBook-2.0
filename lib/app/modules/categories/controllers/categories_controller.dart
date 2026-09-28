import 'package:get/get.dart';

class CategoriesController extends GetxController {
  final isIncome = true.obs;

  void toggle(bool income) {
    isIncome.value = income;
  }
}