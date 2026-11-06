import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../constants/maintenance_config.dart';

class MaintenanceRemoteConfigService {
  MaintenanceRemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  static const Duration fetchTimeout = Duration(seconds: 15);

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(minutes: 15),
      ),
    );
    await _remoteConfig.setDefaults(MaintenanceConfig.defaults);
  }

  Future<bool> fetchAndActivate() async {
    return _remoteConfig.fetchAndActivate().timeout(fetchTimeout);
  }

  Future<bool> activateFetched() async {
    return _remoteConfig.activate();
  }

  bool get maintenanceMode => _remoteConfig.getBool(MaintenanceConfig.modeKey);

  String get title => _remoteConfig.getString(MaintenanceConfig.titleKey);

  String get message => _remoteConfig.getString(MaintenanceConfig.messageKey);

  String get buttonText =>
      _remoteConfig.getString(MaintenanceConfig.buttonTextKey);

  Stream<RemoteConfigUpdate> get configUpdated => _remoteConfig.onConfigUpdated;
}
