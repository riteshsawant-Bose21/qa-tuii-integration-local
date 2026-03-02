import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';

class ListeningAreaPainter extends FusionBasePainter {
  final ListeningArea listeningArea;
  final bool isSelected;
  ListeningAreaPainter({required this.listeningArea, required this.isSelected});
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    drawClosedPath(
      canvas: canvas,
      points: listeningArea.vertices,
      fillPaint:
          Paint()
            ..color = Colors.blue.withOpacity(isSelected ? 0.5 : 0.3)
            ..style = PaintingStyle.fill,
      strokePaint:
          Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = nonScaling(3, painter),
    );
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return false; // No need to repaint since it doesn't draw anything
  }
}
