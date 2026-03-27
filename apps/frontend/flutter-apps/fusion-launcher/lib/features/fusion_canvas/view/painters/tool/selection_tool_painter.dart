import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
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
    if (state is MarqueeSelectToolState) {
      final Rect marqueeRect = (state as MarqueeSelectToolState).selectionRect;
      if (marqueeRect.width > 0 && marqueeRect.height > 0) {
        canvas.drawRect(
          marqueeRect,
          Paint()
            ..color = selectionColor.withValues(alpha: 0.15)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          marqueeRect,
          Paint()
            ..color = selectionColor.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = nonScaling(strokeWidth, painter),
        );
      }
    }

    if (state.selectedLayerIds.isEmpty) return;
    // print("Painting selection for layers: ${state.selectedLayerIds}, elements: ${state.selectedElementIds}");
    Rect? rect;
    for (final FusionBasePainter element in allPainters) {
      if (element.id != null && state.isLayerSelected(element.id)) {
        rect = rect?.expandToInclude(element.getBounds(painter)) ?? element.getBounds(painter);
        _paintSelectionForElement(canvas, size, painter, element);
        for (final FusionCanvasElement ele in element.elements) {
          if (state.isElementSelected(ele.id)) {
            _paintHighlight(canvas, painter, ele, element);
          }
        }
      }
    }

    if (state.selectedLayerIds.length > 1 && rect != null && rect.width > 0 && rect.height > 0) {
      // Draw overall bounding box for selection
      canvas.drawRect(
        rect, //.inflate(nonScaling(10, painter)),
        Paint()
          ..color = selectionColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = nonScaling(strokeWidth, painter),
      );
    }
  }

  void _paintHighlight(Canvas canvas, FusionCanvasPainter painter, FusionCanvasElement element, FusionBasePainter layer) {
    if (element is FusionCanvasLine) {
      drawDashedLine(
        canvas,
        getEffectivePosition(element.start, painter, layer.id ?? ""),
        getEffectivePosition(element.end, painter, layer.id ?? ""),
        Paint()
          ..color = selectionColor
          ..strokeWidth = nonScaling(strokeWidth * 2, painter)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
        painter,
        dashLength: nonScaling(5, painter),
        gapLength: nonScaling(7, painter),
      );
    } else if (element is FusionCanvasPoint) {
      final Offset effectivePosition = getEffectivePosition(element, painter, layer.id ?? "");
      final double nonScaling2 = nonScaling(handleRadius * 2, painter);
      canvas.drawCircle(
        effectivePosition,
        nonScaling2,
        Paint()
          ..color = selectionColor.withValues(alpha: 0.75)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        effectivePosition,
        nonScaling2 * 0.5,
        Paint()
          ..color = Colors.white
          ..strokeWidth = nonScaling(strokeWidth, painter)
          ..style = PaintingStyle.stroke,
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
    } else if (element is FusionCanvasElementPainter) {
      _paintSimpleRectSelection(canvas, element.getTransformedRect(painter), painter);
    }
  }

  void _paintSimpleRectSelection(Canvas canvas, Rect rect, FusionCanvasPainter painter) {
    canvas.drawRect(
      rect,
      Paint()
        ..color = selectionColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = nonScaling(strokeWidth, painter),
    );
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

      final FusionCanvasLine fusionCanvasLine = FusionCanvasLine(start: start, end: end);
      if (!state.isElementSelected(fusionCanvasLine.id)) {
        final FusionCanvasLinePainter edgePainter = FusionCanvasLinePainter(
          line: fusionCanvasLine,
          thickness: strokeWidth,
          color: selectionColor,
          showPoints: true,
          layerId: polygonPainter.id ?? '',
        );
        edgePainter.paint(canvas, size, painter);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! SelectionToolPainter) return true;
    return oldDelegate.state != state || oldDelegate.allPainters != allPainters;
  }
}
