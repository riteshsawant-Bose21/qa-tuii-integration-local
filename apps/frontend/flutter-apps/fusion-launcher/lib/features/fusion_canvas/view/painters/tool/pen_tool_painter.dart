import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/model/fusion_canvas_point.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

import '../../../state/tools/pen_tool_state.dart';

class PenToolPainter extends FusionBasePainter {
  final PenToolState state;
  final Offset? cursor;

  PenToolPainter({
    required this.state,
    required this.cursor,
  });

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    if (state is DrawingPenToolState) {
      final DrawingPenToolState drawingState = state as DrawingPenToolState;
      if (drawingState.points.isEmpty) return;
      final Paint paint =
          Paint()
            ..color = const Color(0xFF000000)
            ..strokeWidth = nonScaling(2, painter)
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;

      for (int i = 0; i < drawingState.points.length - 1; i++) {
        final Offset start = drawingState.points[i].position;
        final Offset end = drawingState.points[i + 1].position;
        canvas.drawLine(start, end, paint);
        canvas.drawCircle(
          start,
          nonScaling(3, painter),
          paint
            ..style = PaintingStyle.fill
            ..color = const Color(0xFF000000),
        );
        final FusionCanvasPoint p = drawingState.points[i];
        if (p.handleIn != null) {
          canvas.drawLine(p.position, p.handleIn!, paint);
          canvas.drawCircle(p.handleIn!, nonScaling(4, painter), paint);
        }

        if (p.handleOut != null) {
          canvas.drawLine(p.position, p.handleOut!, paint);
          canvas.drawCircle(p.handleOut!, nonScaling(4, painter), paint);
        }
      }

      // Draw line to cursor if currently drawing
      if (cursor != null) {
        final Offset lastPoint = drawingState.points.last.position;
        canvas.drawLine(lastPoint, cursor!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
