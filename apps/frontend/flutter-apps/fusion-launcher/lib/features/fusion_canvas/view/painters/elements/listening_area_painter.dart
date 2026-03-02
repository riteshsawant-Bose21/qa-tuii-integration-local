import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';
import 'fusion_rect_painter.dart';

class ListeningAreaPainter extends FusionPolygonPainter {
  final ListeningArea listeningArea;
  final bool isSelected;
  ListeningAreaPainter({required this.listeningArea, required this.isSelected})
    : super(
        polygon: FusionCanvasPolygon(points: listeningArea.vertices, id: listeningArea.id),
      );

  @override
  String toString() {
    return 'ListeningAreaPainter(name: ${listeningArea.name}, vertices: ${listeningArea.vertices.length}, isSelected: $isSelected)';
  }

  @override
  Paint getFillPaint(FusionCanvasPainter painter, bool isHovered) {
    return Paint()
      ..color =
          isSelected
              ? Colors.blue.withOpacity(0.7)
              : isHovered
              ? Colors.blue.withOpacity(0.5)
              : Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
  }

  @override
  Paint getStrokePaint(FusionCanvasPainter painter, bool isHovered) {
    return Paint()
      ..color =
          isSelected
              ? Colors.blue
              : isHovered
              ? Colors.blue.withOpacity(0.8)
              : Colors.blue.withOpacity(0.5)
      ..strokeWidth = nonScaling(isHovered ? 3 : 2, painter)
      ..style = PaintingStyle.stroke;
  }
}
