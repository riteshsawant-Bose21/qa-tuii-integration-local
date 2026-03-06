import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../state/tools/select_tool_state.dart';
import '../elements/fusion_canvas_line_painter.dart';
import '../elements/fusion_rect_painter.dart';
import '../fusion_canvas_painter.dart';

/// Painter that draws selection highlights and drag handles for selected elements
class SelectionToolPainter extends FusionBasePainter {
  final SelectToolState state;
  final List<FusionBasePainter> allPainters;
  final Color selectionColor;
  final Color handleColor;
  final double handleRadius;
  final double strokeWidth;

  SelectionToolPainter({
    required this.state,
    required this.allPainters,
    this.selectionColor = Colors.blue,
    this.handleColor = Colors.blue,
    this.handleRadius = 5.0,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    if (state.selectedLayerIds.isEmpty) return;

    for (final FusionBasePainter element in allPainters) {
      if (element.id != null && state.isLayerSelected(element.id)) {
        _paintSelectionForElement(canvas, size, painter, element);
      }
    }
  }

  void _paintSelectionForElement(
    Canvas canvas,
    Size size,
    FusionCanvasPainter painter,
    FusionBasePainter element,
  ) {
    if (element is FusionPolygonPainter) {
      _paintPolygonSelection(canvas, size, painter, element);
    }
  }

  void _paintPolygonSelection(
    Canvas canvas,
    Size size,
    FusionCanvasPainter painter,
    FusionPolygonPainter polygonPainter,
  ) {
    final List<FusionCanvasPoint> points = polygonPainter.polygon.points;
    if (points.isEmpty) return;

    // Draw edge lines with handles
    for (int i = 0; i < points.length; i++) {
      final FusionCanvasPoint start = points[i];
      final FusionCanvasPoint end = points[(i + 1) % points.length];

      final FusionCanvasLinePainter edgePainter = FusionCanvasLinePainter(
        line: FusionCanvasLine(start: start, end: end),
        thickness: strokeWidth,
        color: selectionColor,
        showPoints: true,
        layerId: polygonPainter.id ?? '',
      );
      edgePainter.paint(canvas, size, painter);
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! SelectionToolPainter) return true;
    return oldDelegate.state != state || oldDelegate.allPainters != allPainters;
  }
}
