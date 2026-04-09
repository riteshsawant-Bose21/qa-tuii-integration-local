import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';
import 'mixin/fusion_canvas_interactable_mixin.dart';

abstract class FusionPolygonPainter extends FusionBasePainter with FusionCanvasInteractibleMixin {
  final FusionCanvasPolygon polygon;
  FusionPolygonPainter({
    required this.polygon,
  });
  Path? path;
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    path = getPolygonPath(polygon, painter);
    if (path != null) {
      final Paint? fillPaint = getFillPaint(painter, id != null && painter.hoverViewModel.hoveredPainterId == id);
      if (fillPaint != null) {
        canvas.drawPath(
          path!,
          fillPaint,
        );
      }
      final Paint? strokePaint = getStrokePaint(painter, id != null && painter.hoverViewModel.hoveredPainterId == id);
      if (strokePaint != null) {
        canvas.drawPath(
          path!,
          strokePaint,
        );
      }
    }
  }

  @override
  Rect getBounds(FusionCanvasPainter painter) {
    path = getPolygonPath(polygon, painter);
    if (path != null) {
      return path!.getBounds();
    }
    return Rect.zero;
  }

  Path? getPath(FusionCanvasPainter painter) {
    return getPolygonPath(polygon, painter);
  }

  @override
  String? get id => polygon.id;

  List<FusionCanvasLine> get lines {
    final List<FusionCanvasLine> edges = <FusionCanvasLine>[];
    for (int i = 0; i < polygon.points.length; i++) {
      final FusionCanvasPoint start = polygon.points[i];
      final FusionCanvasPoint end = polygon.points[(i + 1) % polygon.points.length];
      edges.add(FusionCanvasLine(start: start, end: end));
    }
    return edges;
  }

  @override
  List<FusionCanvasElement> get elements => <FusionCanvasElement>[
    ...lines,
    ...polygon.points,
  ];

  Paint? getFillPaint(FusionCanvasPainter painter, bool isHovered);
  Paint? getStrokePaint(FusionCanvasPainter painter, bool isHovered);

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! FusionPolygonPainter) return true;
    return oldDelegate.polygon != polygon;
  }

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    path = getPolygonPath(polygon, painter);

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
