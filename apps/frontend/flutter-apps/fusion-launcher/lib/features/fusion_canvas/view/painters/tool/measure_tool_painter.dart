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
          ..strokeWidth = nonScaling(2, painter)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    // Draw the main line
    canvas.drawLine(start, end, paint);
    // Draw arrows at both ends
    drawArrow(canvas, start, end, paint, painter);
    drawArrow(canvas, end, start, paint, painter);

    // Calculate center point for text positioning
    final Offset center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    drawText(
      canvas: canvas,
      text: (start - end).distance.toStringAsFixed(2),
      position: center,
      positionAlignment: Alignment.bottomCenter,
      style: TextStyle(fontSize: nonScaling(14, painter), color: Colors.white),
      backgroundPaint: Paint()..color = Colors.black,
      backgroundPadding: EdgeInsets.symmetric(horizontal: nonScaling(6, painter), vertical: nonScaling(3, painter)),
      backgroundBorderRadius: Radius.circular(nonScaling(5, painter)),
    );
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
