import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';

class LineCenterHandlePainter extends FusionBasePainter {
  static const double visualRadius = 5.0;
  static const double hitRadius = 10.0;

  static Offset getLineCenter(
    FusionCanvasLine line,
    FusionBasePainter layerPainter,
    FusionCanvasPainter painter,
  ) {
    final Offset start = layerPainter.getEffectivePosition(line.start, painter, layerPainter.id);
    final Offset end = layerPainter.getEffectivePosition(line.end, painter, layerPainter.id);
    return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
  }

  static bool isLineCenterHit(
    Offset pointerPosition,
    FusionCanvasLine line,
    FusionBasePainter layerPainter,
    FusionCanvasPainter painter,
  ) {
    final Offset center = getLineCenter(line, layerPainter, painter);
    final double scaledHitRadius = hitRadius * (1 / painter.state.scale);
    return (pointerPosition - center).distance <= scaledHitRadius;
  }

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final FusionHoverState hoverState = painter.hoverViewModel;
    final FusionCanvasElement? hoveredElement = hoverState.hoveredElement;
    final String? layerId = hoverState.hoveredPainterId;

    if (hoveredElement is! FusionCanvasLine || layerId == null) {
      return;
    }

    if (!painter.isSelected(layerId)) return;

    final FusionBasePainter? hoveredPainter = painter.layers.cast<FusionBasePainter?>().firstWhere(
      (FusionBasePainter? layer) => layer?.id == layerId,
      orElse: () => null,
    );

    if (hoveredPainter == null) {
      return;
    }

    final Offset center = getLineCenter(hoveredElement, hoveredPainter, painter);

    final Paint fillPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = painter.context.colorScheme.secondary;

    final Paint strokePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = nonScaling(1.5, painter)
          ..color = painter.context.colorScheme.onPrimary;

    canvas.drawCircle(center, nonScaling(visualRadius, painter), fillPaint);
    canvas.drawCircle(center, nonScaling(visualRadius, painter), strokePaint);
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
