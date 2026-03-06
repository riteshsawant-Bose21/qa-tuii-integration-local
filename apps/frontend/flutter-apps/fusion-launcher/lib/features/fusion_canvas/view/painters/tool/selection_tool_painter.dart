import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../state/tools/select_tool_state.dart';
import '../elements/fusion_canvas_line_painter.dart';
import '../elements/fusion_canvas_point_painter.dart';
import '../elements/fusion_image_painter.dart';
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
        for (final FusionCanvasElement ele in element.elements) {
          if (state.isElementSelected(ele.id)) {
            _paintHighlight(canvas, painter, ele, element);
          }
        }
      }
    }
  }

  void _paintHighlight(Canvas canvas, FusionCanvasPainter painter, FusionCanvasElement element, FusionBasePainter layer) {
    final Paint highlightPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;
    if (element is FusionCanvasLine) {
      canvas.drawLine(
        getEffectivePosition(element.start, painter, layer.id ?? ""),
        getEffectivePosition(element.end, painter, layer.id ?? ""),
        highlightPaint
          ..strokeWidth = nonScaling(strokeWidth * 2, painter)
          ..style = PaintingStyle.stroke,
      );
    } else if (element is FusionCanvasPoint) {
      canvas.drawCircle(
        getEffectivePosition(element, painter, layer.id ?? ""),
        nonScaling(handleRadius * 2, painter),
        highlightPaint,
      );
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
    } else if (element is FusionCanvasLinePainter) {
      _paintLineSelection(canvas, size, painter, element);
    } else if (element is FusionImagePainter) {
      _paintImageSelection(canvas, size, painter, element);
    }
  }

  void _paintLineSelection(
    Canvas canvas,
    Size size,
    FusionCanvasPainter painter,
    FusionCanvasLinePainter linePainter,
  ) {
    // Draw highlighted line
    final FusionCanvasLinePainter selectionLinePainter = FusionCanvasLinePainter(
      line: linePainter.line,
      thickness: strokeWidth,
      color: Colors.red,
      showPoints: true,
      layerId: linePainter.layerId,
    );
    selectionLinePainter.paint(canvas, size, painter);
  }

  void _paintImageSelection(
    Canvas canvas,
    Size size,
    FusionCanvasPainter painter,
    FusionImagePainter imagePainter,
  ) {
    final Rect imageRect = Rect.fromLTWH(
      imagePainter.position.dx,
      imagePainter.position.dy,
      imagePainter.size.width,
      imagePainter.size.height,
    );

    // Draw selection rectangle
    final Paint strokePaint =
        Paint()
          ..color = selectionColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = nonScaling(strokeWidth, painter);
    canvas.drawRect(imageRect, strokePaint);

    // Draw corner handles
    final List<Offset> cornerPoints = <Offset>[
      imageRect.topLeft,
      imageRect.topRight,
      imageRect.bottomRight,
      imageRect.bottomLeft,
    ];

    for (final Offset corner in cornerPoints) {
      final FusionCanvasPointPainter handlePainter = FusionCanvasPointPainter(
        point: FusionCanvasPoint(position: corner),
        radius: handleRadius,
        color: handleColor,
        layerId: imagePainter.id ?? '',
      );
      handlePainter.paint(canvas, size, painter);
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
