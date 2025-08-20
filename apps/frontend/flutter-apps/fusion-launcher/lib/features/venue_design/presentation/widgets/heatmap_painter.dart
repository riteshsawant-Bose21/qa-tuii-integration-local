import 'dart:math';

import 'package:flutter/material.dart';

/// A simple data class for one graph-space point + its value.
class GraphPoint {
  final double x, y, value;

  GraphPoint(this.x, this.y, this.value);
}

class GraphDotPainter extends CustomPainter {
  static const List<double> _legendStops = <double>[55, 57, 59, 61, 63, 65, 67, 69, 71, 73, 75, 77, 79, 81, 83, 85];

  static const List<Color> _legendColors = <Color>[
    Color(0xFF00008B), // 55 → dark blue
    Color(0xFF0000CD), // 57 → medium blue
    Color(0xFF0000FF), // 59 → true blue
    Color(0xFF007FFF), // 61 → sky blue
    Color(0xFF00FFFF), // 63 → cyan
    Color(0xFF00FF7F), // 65 → spring green
    Color(0xFF00FF00), // 67 → green
    Color(0xFF7FFF00), // 69 → chartreuse (yellow‑green)
    Color(0xFFFFFF00), // 71 → yellow
    Color(0xFFFFBF00), // 73 → gold
    Color(0xFFFFA500), // 75 → orange
    Color(0xFFFF8C00), // 77 → dark orange
    Color(0xFFFF4500), // 79 → orangered
    Color(0xFFFF0000), // 81 → red
    Color(0xFF8B0000), // 83 → dark red
    Color(0xFFFF0000), // 85 → red (peak)
  ];

  // 2) Map any value in 0…132 into the ramp:
  static Color _colorFromLegend(double v) {
    v = v.clamp(_legendStops.first, _legendStops.last);
    for (int i = 0; i < _legendStops.length - 1; i++) {
      final double lo = _legendStops[i], hi = _legendStops[i + 1];
      if (v <= hi) {
        final double t = (v - lo) / (hi - lo);
        return Color.lerp(_legendColors[i], _legendColors[i + 1], t)!;
      }
    }
    return _legendColors.last;
  }

  final List<GraphPoint> points;
  final double centerX, centerY; // graph coords of container center
  final double scaleX, scaleY; // domain→pixel scales
  final double blurRadius; // how “wide” each heat blob is
  final double dataMax; // e.g. 68.0

  GraphDotPainter({
    required this.points,
    required this.centerX,
    required this.centerY,
    required this.scaleX,
    required this.scaleY,
    this.blurRadius = 5.0,
    this.dataMax = 85.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double halfW = size.width / 2;
    final double halfH = size.height / 2;

    for (final GraphPoint p in points) {
      // 1) graph→local coords
      final double lx = (p.x - centerX) * scaleX + halfW;
      final double ly = (centerY - p.y) * scaleY + halfH;

      // 2) skip offscreen
      if (lx < -blurRadius || lx > size.width + blurRadius || ly < -blurRadius || ly > size.height + blurRadius) continue;

      // 3) clamp  data value
      final double v = p.value.clamp(55.0, 105.0);
      final Color color = _colorFromLegend(v);

      final Paint paint =
          Paint()
            ..color = color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, max((size.width * 0.02), (size.height * 0.02)));
      // canvas.drawCircle(Offset(lx, ly), 7.5 * scaleX, paint);

      canvas.drawRect(Rect.fromCenter(center: Offset(lx, ly), width: (size.width * 0.05), height: (size.height * 0.05)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GraphDotPainter old) {
    return old.points != points ||
        old.centerX != centerX ||
        old.centerY != centerY ||
        old.scaleX != scaleX ||
        old.scaleY != scaleY ||
        old.blurRadius != blurRadius;
  }
}
