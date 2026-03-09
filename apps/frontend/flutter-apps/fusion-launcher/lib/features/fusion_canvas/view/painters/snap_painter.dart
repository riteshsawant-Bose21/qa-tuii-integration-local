import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/service/snap_service.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';

import 'fusion_canvas_painter.dart';

class SnapPainter extends FusionBasePainter {
  final SnapResult? snapResult;

  SnapPainter({this.snapResult});

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    if (snapResult == null || !snapResult!.hasSnapped) return;

    final List<SnapPoint> snapPoints = snapResult!.snapPoints;
    if (snapPoints.isEmpty) return;

    final Offset snappedPosition = snapResult!.snappedPosition;

    // Draw indicators for all snap points
    for (final SnapPoint snapPoint in snapPoints) {
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
        case SnapPointType.orthogonalY:
          _lineSnapIndicator(canvas, snapPoint, snappedPosition, indicatorPaint, painter);
          break;
      }
    }

    // Draw combined snap indicator if multiple orthogonal snaps
    if (snapPoints.length > 1) {
      final Paint combinedPaint =
          Paint()
            ..color = Colors.red
            ..strokeWidth = nonScaling(2, painter)
            ..style = PaintingStyle.stroke;
      _drawCross(canvas, snappedPosition, combinedPaint, painter);
    }
  }

  void _drawPointSnapIndicator(Canvas canvas, Offset position, Paint indicatorPaint, Paint fillPaint, FusionCanvasPainter painter) {
    final double radius = nonScaling(6, painter);
    canvas.drawCircle(position, radius, fillPaint);
    canvas.drawCircle(position, radius, indicatorPaint);
  }

  void _lineSnapIndicator(Canvas canvas, SnapPoint snapPoint, Offset snappedPosition, Paint indicatorPaint, FusionCanvasPainter painter) {
    // Draw line from reference point to snapped position
    final Paint dashedPaint =
        Paint()
          ..color = indicatorPaint.color
          ..strokeWidth = indicatorPaint.strokeWidth
          ..style = PaintingStyle.stroke;

    final Offset referencePoint = snapPoint.referencePosition;

    // Draw line from reference point to the snapped position
    drawDashedLine(canvas, referencePoint, snappedPosition, dashedPaint, painter);

    // Draw small cross at reference position
    _drawCross(canvas, referencePoint, indicatorPaint, painter);
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
        return Colors.red;
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
