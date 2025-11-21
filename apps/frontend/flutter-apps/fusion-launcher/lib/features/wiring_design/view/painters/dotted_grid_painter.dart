import 'package:flutter/material.dart';

class DottedGridPainter {
  final Color color;

  DottedGridPainter({required this.color});

  void paint(Canvas canvas, Size size, Offset offset, double scale) {
    const double baseSpacing = 40.0; // Grid spacing at scale=1
    const double dotRadius = 1.5;

    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

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
        canvas.drawCircle(Offset(x, y), dotRadius / scale, paint);
      }
    }
  }
}
