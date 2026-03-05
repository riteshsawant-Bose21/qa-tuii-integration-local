import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';
import 'fusion_rect_painter.dart';

class ListeningAreaPainter extends FusionPolygonPainter {
  final ListeningArea listeningArea;
  @override
  final bool isSelected;
  ListeningAreaPainter({required this.listeningArea, required this.isSelected})
    : super(
        polygon: FusionCanvasPolygon(points: listeningArea.vertices, id: listeningArea.id),
      );

  @override
  String toString() {
    return 'ListeningAreaPainter(name: ${listeningArea.name}, vertices: ${listeningArea.vertices.length}, isSelected: $isSelected)';
  }

  Color getColor(FusionCanvasPainter painter) => painter.context.colorScheme.elevation4;

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    super.paint(canvas, size, painter);
    if (listeningArea.vertices.isEmpty) return;
    final List<Offset> poly = listeningArea.vertices.map((FusionCanvasPoint e) => e.position).toList();
    final (Offset position, Alignment alignment) = (_leftMostVertex(poly, painter.state.scale), Alignment.topLeft);
    final Offset transformOffsetForLayer2 = transformOffsetForLayer(position, painter, id);
    final Size textSize = drawText(
      canvas: canvas,
      text: listeningArea.name,
      position: transformOffsetForLayer2,
      positionAlignment: alignment,
      style: TextStyle(fontSize: nonScaling(12, painter), color: Colors.white),
      backgroundPaint: Paint()..color = getColor(painter),
      backgroundPadding: EdgeInsets.symmetric(horizontal: nonScaling(4, painter), vertical: nonScaling(2, painter)),
      backgroundBorderRadius: Radius.circular(nonScaling(3, painter)),
    );
    labelRect = transformOffsetForLayer2 & textSize;
  }

  Rect? labelRect;

  Offset _leftMostVertex(List<Offset> poly, double zoomScale) {
    const double baseTol = 0.5; // px
    final double tol = baseTol / zoomScale;
    Offset best = poly.first;
    for (final Offset p in poly) {
      final bool moreLeft = p.dx < best.dx - tol;
      final bool sameXHigher = (p.dx - best.dx).abs() <= tol && p.dy < best.dy;
      if (moreLeft || sameXHigher) best = p;
    }
    return best;
  }

  @override
  Paint getFillPaint(FusionCanvasPainter painter, bool isHovered) {
    final Color color = getColor(painter);
    return Paint()
      ..color =
          isSelected
              ? color.withOpacity(0.7)
              : isHovered
              ? color.withOpacity(0.5)
              : color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
  }

  @override
  Paint getStrokePaint(FusionCanvasPainter painter, bool isHovered) {
    return Paint()
      ..color = getColor(painter)
      ..strokeWidth = nonScaling(2, painter)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
  }

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    if (labelRect != null && labelRect!.contains(position)) {
      return polygon;
    }
    return super.isHit(position, painter);
  }
}
