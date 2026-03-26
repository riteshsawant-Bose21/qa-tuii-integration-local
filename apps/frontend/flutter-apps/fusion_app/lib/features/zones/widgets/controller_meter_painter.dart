import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ControllerAudioMeterPainter extends CustomPainter {
  final double currentValue;
  final double minDb;
  final double maxDb;
  final Color trackColor;

  ControllerAudioMeterPainter({
    required this.currentValue,
    required this.minDb,
    required this.maxDb,
    required this.trackColor, // Default dark gray track
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Layout Constants ---
    const double barHeight = 10.0;
    const double labelSectionHeight = 0.0;

    // The light box is a square, its size matches the bar height
    final double lightBoxSize = barHeight;

    // The width available for the actual meter bar
    // (Total Width - Light Box Width - The Gap we just increased)
    final double barWidth = size.width - 0;

    // Y position centering
    final double contentCenterY = (size.height - labelSectionHeight) / 3;
    final double barTop = contentCenterY;

    // Helper to normalize dB value to 0.0 - 1.0 range
    double normalize(double db) => (db - minDb) / (maxDb - minDb);

    // --- 1. Draw Background Track ---
    final Paint trackPaint =
    Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    print("barTop");
    print(barTop);
    final RRect trackRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, barTop, barWidth, barHeight),
      const Radius.circular(barHeight / 2),
    );
    canvas.drawRRect(trackRRect, trackPaint);

    // --- 2. Draw Gradient Active Level ---
    final double effectiveValue = currentValue.clamp(minDb, maxDb + 1);
    final double fillPercentage = normalize(effectiveValue);

    if (fillPercentage > 0) {
      final Paint activePaint =
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(barWidth, 0),
          <ui.Color>[
            const Color(0xFF388E3C), // Darker Green
            const Color(0xFF8BC34A), // Light Green
            const Color(0xFFFFEB3B), // Yellow
            const Color(0xFFFF9800), // Orange
          ],
          <double>[0.0, 0.3, 0.55, 0.7],
        );

      final double currentWidth = barWidth * fillPercentage;
      final RRect activeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barTop, currentWidth, barHeight),
        const Radius.circular(barHeight / 2),
      );
      canvas.drawRRect(activeRRect, activePaint);
    }

  }

  @override
  bool shouldRepaint(covariant ControllerAudioMeterPainter oldDelegate) {
    return false;
  }
}