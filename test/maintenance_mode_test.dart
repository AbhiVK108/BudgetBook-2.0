import 'package:budget_book_2026/app/core/constants/maintenance_config.dart';
import 'package:budget_book_2026/app/modules/maintenance/controllers/maintenance_controller.dart';
import 'package:budget_book_2026/app/modules/maintenance/views/maintenance_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  test('maintenance defaults use an accessible production-safe mode', () {
    expect(MaintenanceConfig.defaultMode, isFalse);
    expect(MaintenanceConfig.defaultTitle, "We'll Be Back Soon!");
    expect(MaintenanceConfig.defaultButtonText, 'Try Again');
  });

  testWidgets('maintenance view renders configured copy', (tester) async {
    final controller = Get.put(MaintenanceController(null));
    await controller.initialize();
    controller.title.value = 'Scheduled maintenance';
    controller.message.value = 'We will be back shortly.';
    controller.buttonText.value = 'Check again';

    await tester.pumpWidget(const GetMaterialApp(home: MaintenanceView()));
    await tester.pump();

    expect(find.text('Scheduled maintenance'), findsOneWidget);
    expect(find.text('We will be back shortly.'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
  });
}
