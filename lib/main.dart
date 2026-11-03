import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/core/services/api_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    final accessToken = await ApiService().getToken();
    debugPrint('Access token: $accessToken');
  }

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          title: 'Application',
          debugShowCheckedModeBanner: false,
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,

          /// Applies bottom SafeArea to every screen.
          builder: (context, child) {
            return SafeArea(
              top: false,
              bottom: true,
              left: false,
              right: false,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    ),
  );
}
