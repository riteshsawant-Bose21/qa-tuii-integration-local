import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool isLoaderVisible = false;

class ColorUtils {
  static Color hexToColor(String hexString) {
    final StringBuffer buffer = StringBuffer();
    if (hexString.startsWith('#')) hexString = hexString.substring(1);
    if (hexString.length == 6) buffer.write('FF');
    buffer.write(hexString);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    String twoHex(int v) => v.toRadixString(16).padLeft(2, '0');

    final int a = (color.a * 255.0).round() & 0xff;
    final int r = (color.r * 255.0).round() & 0xff;
    final int g = (color.g * 255.0).round() & 0xff;
    final int b = (color.b * 255.0).round() & 0xff;

    final StringBuffer buffer = StringBuffer();
    if (includeAlpha) buffer.write(twoHex(a));
    buffer
      ..write(twoHex(r))
      ..write(twoHex(g))
      ..write(twoHex(b));

    return '#${buffer.toString().toUpperCase()}';
  }
}
