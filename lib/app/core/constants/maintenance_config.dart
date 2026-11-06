class MaintenanceConfig {
  MaintenanceConfig._();

  static const String modeKey = 'maintenance_mode';
  static const String titleKey = 'maintenance_title';
  static const String messageKey = 'maintenance_message';
  static const String buttonTextKey = 'maintenance_button_text';

  static const bool defaultMode = false;
  static const String defaultTitle = "We'll Be Back Soon!";
  static const String defaultMessage =
      "We're currently performing scheduled maintenance "
      'to improve your experience. Please check back soon.';
  static const String defaultButtonText = 'Try Again';

  static const Map<String, Object> defaults = <String, Object>{
    modeKey: defaultMode,
    titleKey: defaultTitle,
    messageKey: defaultMessage,
    buttonTextKey: defaultButtonText,
  };
}
