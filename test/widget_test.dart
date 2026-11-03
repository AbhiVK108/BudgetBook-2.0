import 'package:budget_book_2026/app/modules/bank_account/views/add_bank_account_view.dart';
import 'package:budget_book_2026/app/modules/login/controllers/login_controller.dart';
import 'package:budget_book_2026/app/modules/login/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('login screen offers phone OTP sign-in', (
    WidgetTester tester,
  ) async {
    Get.put(LoginController());
    await tester.pumpWidget(const GetMaterialApp(home: LoginView()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Phone verification'), findsOneWidget);
    expect(find.text('Send verification code'), findsOneWidget);
    expect(find.text('Use username and password'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  });

  testWidgets('bank account form renders and validates required fields', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const GetMaterialApp(home: AddBankAccountView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Bank Account'), findsOneWidget);
    expect(find.text('Account Identification'), findsOneWidget);
    expect(find.text('Valuation & Currency'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Policies & Context'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Policies & Context'), findsOneWidget);
    expect(find.text('Save Bank Account'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byType(TextFormField).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Save Bank Account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an account name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
