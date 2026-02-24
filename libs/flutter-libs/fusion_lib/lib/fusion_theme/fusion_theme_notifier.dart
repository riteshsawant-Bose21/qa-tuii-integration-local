import 'package:flutter/material.dart';
import 'package:fusion_lib/di/service_locator.dart';

import '../fusion_utils/shared_preference_handler.dart';
import 'app_theme.dart';

class FusionThemeController {
  /// Global theme mode notifier
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    fusionLibLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.themeMode) == ThemeMode.light.name ? ThemeMode.light : ThemeMode.dark,
  );

  /// Set theme mode
  static void setThemeMode(ThemeMode mode) {
    fusionLibLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.themeMode, mode.name);
    themeModeNotifier.value = mode;
  }

  /// Getters for light/dark themes
  static ThemeData get lightTheme => FusionAppTheme.lightTheme;
  static ThemeData get darkTheme => FusionAppTheme.darkTheme;
}
