import 'package:flutter/material.dart';
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
    path = getPolygonPath(polygon, painter);
    if (path != null) {
      canvas.drawPath(
        path!,
        getFillPaint(painter, id != null && painter.hoverViewModel.hoveredPainterId == id),
      );
      canvas.drawPath(
        path!,
        getStrokePaint(painter, id != null && painter.hoverViewModel.hoveredPainterId == id),
      );
    }
  }

  @override
  String? get id => polygon.id;

  @override
  List<FusionCanvasPoint> get points => polygon.points;

  Paint getFillPaint(FusionCanvasPainter painter, bool isHovered);
  Paint getStrokePaint(FusionCanvasPainter painter, bool isHovered);

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! FusionPolygonPainter) return true;
    return oldDelegate.polygon != polygon;
  }

  /// Check if this polygon is selected in the current tool state
  bool _isSelectedInToolState(FusionCanvasPainter painter) {
    return true;
    // final FusionToolState toolState = painter.toolState;
    // if (toolState is SelectToolState) {
    //   return toolState.isLayerSelected(id);
    // }
    // return false;
  }

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    path = getPolygonPath(polygon, painter);

    // If selected, check for point/edge hits first
    if (_isSelectedInToolState(painter)) {
      // Check point hits
      for (final FusionCanvasPoint point in polygon.points) {
        final Offset effectivePos = getEffectivePosition(point, painter, id);
        final double hitRadius = nonScaling(10, painter); // Larger hit area for points
        if ((position - effectivePos).distance <= hitRadius) {
          return point;
        }
      }

      // Check edge hits
      for (int i = 0; i < polygon.points.length; i++) {
        final FusionCanvasPoint start = polygon.points[i];
        final FusionCanvasPoint end = polygon.points[(i + 1) % polygon.points.length];
        final Offset startPos = getEffectivePosition(start, painter, id);
        final Offset endPos = getEffectivePosition(end, painter, id);

        final double distance = _distanceFromPointToLineSegment(position, startPos, endPos);
        final double hitThreshold = nonScaling(8, painter);
        if (distance <= hitThreshold) {
          return FusionCanvasLine(start: start, end: end);
        }
      }
    }

    // Check polygon fill hit
    return path != null && path!.contains(position) ? polygon : null;
  }

  double _distanceFromPointToLineSegment(Offset p, Offset a, Offset b) {
    final double lengthSquared = (b - a).distanceSquared;
    if (lengthSquared == 0) return (p - a).distance;
    final Offset pa = p - a;
    final Offset ba = b - a;
    final double dotProduct = pa.dx * ba.dx + pa.dy * ba.dy;
    final double t = dotProduct / lengthSquared;
    if (t < 0) return (p - a).distance;
    if (t > 1) return (p - b).distance;
    final Offset projection = a + (b - a) * t;
    return (p - projection).distance;
  }
}
