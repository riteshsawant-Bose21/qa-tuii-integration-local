import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';
import 'fusion_canvas_line_painter.dart';

abstract class FusionPolygonPainter extends FusionBasePainter {
  final FusionCanvasPolygon polygon;
  FusionPolygonPainter({
    required this.polygon,
  });
  Path? path;
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    path = getPolygonPath(polygon, painter);
    _buildEdges(painter);
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

    if (isSelected) {
      for (final FusionCanvasLinePainter edge in _edges) {
        edge.paint(canvas, size, painter);
      }
    }
  }

  final List<FusionCanvasLinePainter> _edges = <FusionCanvasLinePainter>[];

  void _buildEdges(FusionCanvasPainter painter) {
    for (int i = 0; i < polygon.points.length; i++) {
      final FusionCanvasPoint start = polygon.points[i];
      final FusionCanvasPoint end = polygon.points[(i + 1) % polygon.points.length];
      _edges.add(
        FusionCanvasLinePainter(
          line: FusionCanvasLine(start: start, end: end),
          thickness: 3,
          color: Colors.blue,
          showPoints: true,
          layerId: id ?? '',
        ),
      );
    }
  }

  @override
  String? get id => polygon.id;

  @override
  List<FusionCanvasPoint> get points => polygon.points;

  // void

  Paint getFillPaint(FusionCanvasPainter painter, bool isHovered);
  Paint getStrokePaint(FusionCanvasPainter painter, bool isHovered);

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! FusionPolygonPainter) return true;
    return oldDelegate.polygon != polygon;
  }

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    path = getPolygonPath(polygon, painter);
    _buildEdges(painter);
    for (final FusionCanvasLinePainter edge in _edges) {
      final FusionCanvasElement? hitId = edge.isHit(position, painter);
      if (hitId != null) {
        return hitId;
      }
    }
    return path != null && path!.contains(position) ? polygon : null;
  }
}
