import 'package:flutter/material.dart';

class DottedGridPainter {
  final Color color;

  DottedGridPainter({required this.color});

  void paint(Canvas canvas, Size size, Offset offset, double scale) {
    const double baseSpacing = 100.0; // 100 pixels spacing same as building page.
    const double dotRadius = 10;

    final Paint paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.fill;

    // Find visible bounds in world coordinates
    final double left = -offset.dx / scale;
    final double top = -offset.dy / scale;
    final double right = left + size.width / scale;
    final double bottom = top + size.height / scale;

    // Snap to grid so it always looks infinite
    final double spacing = baseSpacing;
    final double startX = (left ~/ spacing) * spacing;
    final double startY = (top ~/ spacing) * spacing;

    for (double x = startX; x < right; x += spacing) {
      for (double y = startY; y < bottom; y += spacing) {
        final double r = (dotRadius / scale).clamp(6.0, 8.0); // clamp to avoid oversized dots
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }
}
