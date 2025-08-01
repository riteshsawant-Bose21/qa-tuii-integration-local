import 'package:flutter/material.dart';

/// Painter that draws a simple grid of gray lines
class GridPainter extends CustomPainter {
  final double spacing;
  final Color lineColor;
  final double lineWidth;

  GridPainter({required this.spacing, required this.lineColor, required this.lineWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = lineWidth;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => false;
}
