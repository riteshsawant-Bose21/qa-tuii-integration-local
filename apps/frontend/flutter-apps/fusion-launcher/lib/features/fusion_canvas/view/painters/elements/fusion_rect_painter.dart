import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';

abstract class FusionPolygonPainter extends FusionBasePainter {
  final FusionCanvasPolygon polygon;
  FusionPolygonPainter({
    required this.polygon,
  });
  Path? path;
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    path = getPolygonPath(polygon);
    if (path != null) {
      canvas.drawPath(
        path!,
        getFillPaint(painter, isHit(painter.cursor ?? Offset.zero, painter)),
      );
      canvas.drawPath(
        path!,
        getStrokePaint(painter, isHit(painter.cursor ?? Offset.zero, painter)),
      );
    }
  }

  Paint getFillPaint(FusionCanvasPainter painter, bool isHovered);
  Paint getStrokePaint(FusionCanvasPainter painter, bool isHovered);

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! FusionPolygonPainter) return true;
    return oldDelegate.polygon != polygon;
  }
  

  @override
  bool isHit(Offset position, FusionCanvasPainter painter) {
    return path != null && path!.contains(position);
  }
}
