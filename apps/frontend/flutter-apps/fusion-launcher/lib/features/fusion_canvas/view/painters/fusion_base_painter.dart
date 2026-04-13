import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_snap_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

abstract class FusionBasePainter {
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter);
  bool shouldRepaint(covariant FusionBasePainter oldDelegate);

  String? get id => null;
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    // By default, painters are not interactive. Override this method in interactive painters.
    return null;
  }

  List<FusionCanvasElement> get elements => <FusionCanvasElement>[];

  Rect getBounds(FusionCanvasPainter painter) {
    // By default, return an empty rect. Override this method to provide actual bounds for interactive painters.
    return Rect.zero;
  }

  ///
  /// Util function for number that should not scale with canvas zoom
  ///

  double nonScaling(num value, FusionCanvasPainter painter) {
    return value * (1 / painter.state.scale);
  }

  bool drawImage({
    required Canvas canvas,
    required String imagePath,
    required Rect rect,
    required FusionCanvasPainter painter,
    Paint? paint,
    Color? color,
  }) {
    final ui.Image? image = imagePath.trim().isNotEmpty ? painter.getImage(imagePath) : null;
    if (image != null) {
      final Rect src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );

      canvas.drawImageRect(
        image,
        src,
        rect,
        paint ?? Paint()
          ..colorFilter = color != null ? ColorFilter.mode(color, BlendMode.srcIn) : paint?.colorFilter,
      );

      return true;
    }
    return false;
  }

  ///
  /// All Paint functions which will help in painting.
  ///

  Size drawText({
    required Canvas canvas,
    required String text,
    TextStyle? style,
    required Offset position,
    double maxWidth = double.infinity,
    Alignment positionAlignment = Alignment.center,
    Paint? backgroundPaint,
    EdgeInsets backgroundPadding = EdgeInsets.zero,
    Radius backgroundBorderRadius = Radius.zero,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    // Draw background if provided

    if (backgroundPaint != null) {
      final RRect bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          position.dx - tp.width / 2 - tp.width * 0.5 * positionAlignment.x - backgroundPadding.left,
          position.dy - tp.height / 2 - tp.height * 0.5 * positionAlignment.y - backgroundPadding.top,
          tp.width + backgroundPadding.horizontal,
          tp.height + backgroundPadding.vertical,
        ),
        backgroundBorderRadius,
      );
      canvas.drawRRect(bgRect, backgroundPaint);
    }

    tp.paint(
      canvas,
      Offset(
        position.dx - tp.width / 2 - tp.width * 0.5 * positionAlignment.x,
        position.dy - tp.height / 2 - tp.height * 0.5 * positionAlignment.y,
      ),
    );
    return Size(tp.width, tp.height);
  }

  void drawArrow(Canvas canvas, Offset from, Offset to, Paint paint, FusionCanvasPainter painter) {
    final double arrowLength = nonScaling(10.0, painter);
    final double arrowAngle = 0.5; // radians

    // Calculate direction vector
    final Offset direction = (to - from);
    final double distance = direction.distance;
    if (distance == 0) return;

    final Offset normalizedDirection = direction / distance;

    // Calculate arrow points
    final double angle = normalizedDirection.direction;
    final Offset arrowPoint1 =
        from +
        Offset(
          arrowLength * math.cos(angle - arrowAngle),
          arrowLength * math.sin(angle - arrowAngle),
        );
    final Offset arrowPoint2 =
        from +
        Offset(
          arrowLength * math.cos(angle + arrowAngle),
          arrowLength * math.sin(angle + arrowAngle),
        );

    // Draw arrow lines
    canvas.drawLine(from, arrowPoint1, paint);
    canvas.drawLine(from, arrowPoint2, paint);
  }

  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, FusionCanvasPainter painter, {double dashLength = 5.0, double gapLength = 3.0}) {
    final double distance = (end - start).distance;
    final Offset direction = (end - start) / distance;

    double currentDistance = 0;
    bool isDash = true;

    while (currentDistance < distance) {
      final double segmentLength = isDash ? dashLength : gapLength;
      final double remainingDistance = distance - currentDistance;
      final double actualLength = segmentLength > remainingDistance ? remainingDistance : segmentLength;

      if (isDash) {
        final Offset segmentStart = start + direction * currentDistance;
        final Offset segmentEnd = start + direction * (currentDistance + actualLength);
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentDistance += actualLength;
      isDash = !isDash;
    }
  }

  Path? getPolygonPath(FusionCanvasPolygon polygon, FusionCanvasPainter painter) {
    final List<FusionCanvasPoint> points = polygon.points;
    if (points.length < 2) return null;

    final ui.Offset firstPos = getEffectivePosition(points[0], painter, polygon.id);
    final Path path = Path()..moveTo(firstPos.dx, firstPos.dy);
    for (int i = 1; i < points.length; i++) {
      final ui.Offset pos = getEffectivePosition(points[i], painter, polygon.id);
      path.lineTo(pos.dx, pos.dy);
    }
    path.close();
    return path;
  }

  ui.Offset getEffectivePosition(FusionCanvasPoint point, FusionCanvasPainter painter, String? layerId) {
    if (painter.toolState is PointsDraggingState) {
      final PointsDraggingState draggingState = painter.toolState as PointsDraggingState;
      if (draggingState.pointIds.contains(point.id)) {
        return point.position + draggingState.delta + _getSnapAdjustment(painter);
      }
    }

    if (painter.toolState is LayerDraggingState) {
      final LayerDraggingState draggingState = painter.toolState as LayerDraggingState;
      if (draggingState.layerIds.contains(layerId)) {
        return point.position + draggingState.delta + _getSnapAdjustment(painter);
      }
    }
    return point.position;
  }

  ui.Offset transformOffsetForLayer(Offset offset, FusionCanvasPainter painter, String? layerId) {
    if (painter.toolState is LayerDraggingState) {
      final LayerDraggingState draggingState = painter.toolState as LayerDraggingState;
      if (draggingState.layerIds.contains(layerId)) {
        return offset + draggingState.delta + _getSnapAdjustment(painter);
      }
    }
    if (painter.toolState is PointsDraggingState) {
      final PointsDraggingState draggingState = painter.toolState as PointsDraggingState;
      if (draggingState.selectedLayerIds.contains(layerId)) {
        return offset + draggingState.delta + _getSnapAdjustment(painter);
      }
    }
    return offset;
  }

  /// Calculate snap adjustment based on the current snap state
  Offset _getSnapAdjustment(FusionCanvasPainter painter) {
    final FusionSnapState snapState = painter.snapViewModel;
    if (snapState.isSnapped && snapState.cursorPositions != null && snapState.snapResult?.cursorIndex != null) {
      final int cursorIndex = snapState.snapResult!.cursorIndex!;
      if (cursorIndex < snapState.cursorPositions!.length) {
        final Offset currentPosition = snapState.cursorPositions![cursorIndex];
        final Offset snappedPosition = snapState.snapResult!.snappedPosition;
        return snappedPosition - currentPosition;
      }
    }
    return Offset.zero;
  }
}
