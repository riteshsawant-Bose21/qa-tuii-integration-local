import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/service/snap_service.dart';

import 'fusion_canvas_painter.dart';

class SnapPainter extends FusionBasePainter {
  final SnapResult? snapResult;

  SnapPainter({this.snapResult});

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    if (snapResult == null || !snapResult!.hasSnapped) return;

    final SnapPoint snapPoint = snapResult!.snapPoint!;
    final Offset position = snapPoint.position;

    // Create paint for snap indicators
    final Paint indicatorPaint =
        Paint()
          ..color = _getColorForSnapType(snapPoint.type)
          ..strokeWidth = nonScaling(2, painter)
          ..style = PaintingStyle.stroke;

    final Paint fillPaint =
        Paint()
          ..color = _getColorForSnapType(snapPoint.type)
          ..style = PaintingStyle.fill;

    // Draw snap indicator based on type
    switch (snapPoint.type) {
      case SnapPointType.point:
        _drawPointSnapIndicator(canvas, position, indicatorPaint, fillPaint, painter);
        break;
      case SnapPointType.orthogonalX:
      // _drawOrthogonalXSnapIndicator(canvas, position, indicatorPaint, painter, size * painter.state.scale);
      // break;
      case SnapPointType.orthogonalY:
        _lineSnapIndicator(canvas, position, indicatorPaint, painter, size * painter.state.scale);
        break;
    }
  }

  void _drawPointSnapIndicator(Canvas canvas, Offset position, Paint indicatorPaint, Paint fillPaint, FusionCanvasPainter painter) {
    final double radius = nonScaling(6, painter);
    canvas.drawCircle(position, radius, fillPaint);
    canvas.drawCircle(position, radius, indicatorPaint);
  }

  void _lineSnapIndicator(Canvas canvas, Offset position, Paint indicatorPaint, FusionCanvasPainter painter, Size canvasSize) {
    // Draw horizontal line indicator from reference point to snapped position
    final Paint dashedPaint =
        Paint()
          ..color = indicatorPaint.color
          ..strokeWidth = indicatorPaint.strokeWidth
          ..style = PaintingStyle.stroke;

    final Offset? referencePoint = snapResult?.referencePoint;
    if (referencePoint != null) {
      // Draw line from reference point to snapped position
      drawDashedLine(canvas, referencePoint, position, dashedPaint, painter);
    } else {
      // Fallback to full canvas line if no reference point
      drawDashedLine(canvas, Offset(0, position.dy), Offset(canvasSize.width, position.dy), dashedPaint, painter);
    }

    // Draw small cross at cursor position
    _drawCross(canvas, position, indicatorPaint, painter);
    if (referencePoint != null) {
      _drawCross(canvas, referencePoint, indicatorPaint, painter);
    }
  }

  void _drawCross(Canvas canvas, Offset center, Paint paint, FusionCanvasPainter painter) {
    final double size = nonScaling(4, painter);
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
  }

  Color _getColorForSnapType(SnapPointType type) {
    switch (type) {
      case SnapPointType.point:
        return Colors.green;
      case SnapPointType.orthogonalX:
      case SnapPointType.orthogonalY:
        return Colors.red;
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return oldDelegate is! SnapPainter || oldDelegate.snapResult != snapResult;
  }
}
