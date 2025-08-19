import 'package:flutter/material.dart';

import 'fusion_theme_notifier.dart';

typedef ThemeModeWidgetBuilder = Widget Function(BuildContext context, ThemeMode mode);

class FusionThemeBuilder extends StatelessWidget {
  final ThemeModeWidgetBuilder builder;

  const FusionThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: FusionThemeController.themeModeNotifier,
      builder: (context, mode, _) {
        return builder(context, mode);
      },
    );
  }
}
