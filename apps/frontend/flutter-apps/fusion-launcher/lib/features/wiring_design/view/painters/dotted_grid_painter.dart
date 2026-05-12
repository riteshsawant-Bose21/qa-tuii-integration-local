import 'dart:math' as math;

import 'package:flutter/material.dart';

class DottedGridPainter {
  final Color color;

  DottedGridPainter({required this.color});

  void paint(Canvas canvas, Size size, Offset offset, double scale, double dotRadius) {
    const double baseSpacing = 50.0; // 100 pixels spacing same as building page.

    final Paint paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.fill;

    // Find visible bounds in world coordinates
    final double left = -offset.dx / scale;
    final double top = -offset.dy / scale;
    final double right = left + size.width / scale;
    final double bottom = top + size.height / scale;

    // Snap to grid so it always looks infinite
    // Every time scale halves (factor of 2), spacing doubles → fewer dots
    const double scaleFactor = 2.0;
    final int level = scale < 1.0 ? (-math.log(scale) / math.log(scaleFactor)).ceil() : 0;
    final double spacing = baseSpacing * math.pow(scaleFactor, level);
    final double startX = (left ~/ spacing) * spacing;
    final double startY = (top ~/ spacing) * spacing;

    for (double x = startX; x < right; x += spacing) {
      for (double y = startY; y < bottom; y += spacing) {
        final double r = (dotRadius); // clamp to avoid oversized dots
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }
}
