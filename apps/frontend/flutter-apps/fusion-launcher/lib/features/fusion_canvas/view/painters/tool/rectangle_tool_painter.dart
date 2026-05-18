import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/rectangle_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

class RectangleToolPainter extends FusionBasePainter {
  final RectangleToolState state;

  RectangleToolPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    if (state is! DrawingRectangleToolState) {
      return;
    }

    final DrawingRectangleToolState drawingState = state as DrawingRectangleToolState;
    final Rect rect = drawingState.rect;

    final Paint fillPaint =
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;

    final Paint strokePaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = nonScaling(2, painter)
          ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) => true;
}
