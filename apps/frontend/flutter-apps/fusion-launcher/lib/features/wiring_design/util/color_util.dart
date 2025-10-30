import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

extension WiringColorUtil on ColorScheme {
  Color get analogWireColor => wireColor;
  Color get switchWireColor => Colors.greenAccent;
  Color get selectedWireColor => const Color.fromRGBO(64, 196, 255, 1);
}

extension ColorUtil on Color {
  Color get darkerShade {
    final HSLColor hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).toColor();
  }
}
