import 'package:flutter/material.dart';

import 'app_theme.dart';

class FusionThemeController {
  /// Global theme mode notifier
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Set theme mode
  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  /// Getters for light/dark themes
  static ThemeData get lightTheme => FusionAppTheme.lightTheme;
  static ThemeData get darkTheme => FusionAppTheme.darkTheme;
}
