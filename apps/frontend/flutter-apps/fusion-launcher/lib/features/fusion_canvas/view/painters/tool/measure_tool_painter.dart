import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/measure_tool_state.dart';

import '../fusion_canvas_painter.dart';

class MeasureToolPainter extends FusionBasePainter {
  final MeasureToolState state;
  final Offset? cursor;
  MeasureToolPainter({required this.state, this.cursor});
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    if (state.start == null) return;
    final Offset start = state.start!;
    final Offset end = state.end ?? cursor ?? start;
    final Paint paint =
        Paint()
          ..color = const Color(0xFF000000)
          ..strokeWidth = 3 * (1 / painter.state.scale)
          ..style = PaintingStyle.stroke;

    // Draw the main line
    canvas.drawLine(start, end, paint);

    // Draw arrows at both ends
    _drawArrow(canvas, start, end, paint, painter);
    _drawArrow(canvas, end, start, paint, painter);

    // Calculate center point for text positioning
    final Offset center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: (start - end).distance.toStringAsFixed(2),
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: 16 * (1 / painter.state.scale),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position text above the center of the line
    final Offset textPosition = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height - 5,
    );

    // Draw black box behind text
    final Paint boxPaint =
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.fill;

    final RRect textBox = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        textPosition.dx - 10,
        textPosition.dy - 5,
        textPainter.width + 20,
        textPainter.height + 15,
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(textBox, boxPaint);
    textPainter.paint(canvas, textPosition);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint, FusionCanvasPainter painter) {
    final double arrowLength = 15.0 * (1 / painter.state.scale);
    final double arrowAngle = 0.5; // radians

    // Calculate direction vector
    final Offset direction = (to - from);
    final double distance = direction.distance;
    if (distance == 0) return;

    final Offset normalizedDirection = direction / distance;

    // Calculate arrow points
    final double angle = normalizedDirection.direction;
    final Offset arrowPoint1 =
        from +
        Offset(
          arrowLength * math.cos(angle - arrowAngle),
          arrowLength * math.sin(angle - arrowAngle),
        );
    final Offset arrowPoint2 =
        from +
        Offset(
          arrowLength * math.cos(angle + arrowAngle),
          arrowLength * math.sin(angle + arrowAngle),
        );

    // Draw arrow lines
    canvas.drawLine(from, arrowPoint1, paint);
    canvas.drawLine(from, arrowPoint2, paint);
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
