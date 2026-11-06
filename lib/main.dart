import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/routes/app_pages.dart';
import 'app/core/services/api_services.dart';
import 'app/core/services/firebase_client_options.dart';
import 'app/core/services/maintenance_remote_config_service.dart';
import 'app/modules/maintenance/controllers/maintenance_controller.dart';
import 'app/modules/maintenance/views/maintenance_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    final accessToken = await ApiService().getToken();
    debugPrint('Access token: $accessToken');
  }

  await _initializeFirebase();
  MaintenanceRemoteConfigService? remoteConfigService;
  try {
    remoteConfigService = MaintenanceRemoteConfigService();
  } catch (error) {
    debugPrint('Remote Config is unavailable: $error');
  }
  final maintenanceController = Get.put(
    MaintenanceController(remoteConfigService),
  );
  await maintenanceController.initialize().timeout(
    const Duration(seconds: 20),
    onTimeout: () {
      debugPrint('Maintenance configuration initialization timed out.');
    },
  );

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
            final maintenance = Get.find<MaintenanceController>();
            return Stack(
              children: [
                SafeArea(
                  top: false,
                  bottom: true,
                  left: false,
                  right: false,
                  child: child ?? const SizedBox.shrink(),
                ),
                Obx(
                  () => maintenance.isMaintenanceMode.value
                      ? const MaintenanceView()
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp().timeout(const Duration(seconds: 15));
    } else {
      await Firebase.initializeApp(
        options: FirebaseClientOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
    }
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }
}
