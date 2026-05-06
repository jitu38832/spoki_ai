import 'package:flutter/material.dart';
import 'package:spokiai/view/utils/preference_manager.dart';

class ThemeController {
  ThemeController._();

  static const String _darkModeKey = 'is_dark_mode_enabled';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDarkModeEnabled =>
      themeModeNotifier.value == ThemeMode.dark;

  static void loadFromPreferences() {
    final bool isDark =
        PreferenceManager.getBooleanValue(key: _darkModeKey) ?? false;
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static void setDarkMode(bool enabled) {
    PreferenceManager.insertValue(key: _darkModeKey, value: enabled);
    themeModeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}
