import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/services/maintenance_remote_config_service.dart';

class MaintenanceController extends GetxController with WidgetsBindingObserver {
  MaintenanceController(this._service);

  final MaintenanceRemoteConfigService? _service;

  final RxBool isMaintenanceMode = false.obs;
  final RxString title = 'We\'ll Be Back Soon!'.obs;
  final RxString message = ''.obs;
  final RxString buttonText = 'Try Again'.obs;
  final RxBool isRetrying = false.obs;
  final RxString errorMessage = ''.obs;
  StreamSubscription<dynamic>? _configSubscription;
  bool _refreshing = false;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      final service = _service;
      if (service == null) {
        _readConfiguration();
        return;
      }
      await service.initialize();
      await refreshConfiguration();
      _configSubscription = service.configUpdated.listen((_) async {
        try {
          await service.activateFetched();
          _readConfiguration();
        } catch (error) {
          _readConfiguration();
        }
      });
    } catch (error) {
      _readConfiguration();
      debugPrint('Remote Config initialization failed: $error');
    }
  }

  Future<void> refreshConfiguration() async {
    if (_refreshing) return;
    final service = _service;
    if (service == null) {
      _readConfiguration();
      return;
    }
    _refreshing = true;
    errorMessage.value = '';
    try {
      await service.fetchAndActivate();
      errorMessage.value = '';
    } catch (_) {
      errorMessage.value =
          'Unable to check for updates. Showing the last available configuration.';
    } finally {
      _readConfiguration();
      _refreshing = false;
    }
  }

  Future<void> retry() async {
    if (isRetrying.value) return;
    isRetrying.value = true;
    await refreshConfiguration();
    isRetrying.value = false;
  }

  void _readConfiguration() {
    final service = _service;
    if (service == null) {
      isMaintenanceMode.value = false;
      title.value = 'We\'ll Be Back Soon!';
      message.value =
          "We're currently performing scheduled maintenance to improve your experience. Please check back soon.";
      buttonText.value = 'Try Again';
      return;
    }
    isMaintenanceMode.value = service.maintenanceMode;
    title.value = service.title.isEmpty
        ? 'We\'ll Be Back Soon!'
        : service.title;
    message.value = service.message;
    buttonText.value = service.buttonText.isEmpty
        ? 'Try Again'
        : service.buttonText;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshConfiguration();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _configSubscription?.cancel();
    super.onClose();
  }
}
