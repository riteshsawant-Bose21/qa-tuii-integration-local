import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';

class LauncherBackground extends StatelessWidget {
  final Widget child;

  const LauncherBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final LinearGradient bgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: <Color>[
        Theme.of(context).colorScheme.launcherBgColor1,
        Theme.of(context).colorScheme.launcherBgColor2,
      ],
    );

    final ColorFilter textureFilter = const ColorFilter.mode(
      Colors.grey,
      BlendMode.srcATop,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: bgGradient,
        image: DecorationImage(
          image: const AssetImage(
            'assets/images/launcher_bg_pattern.png',
          ),
          fit: BoxFit.cover,
          opacity: isDark ? 0.05 : 0.1,
          colorFilter: textureFilter,
        ),
      ),
      child: child,
    );
  }
}
