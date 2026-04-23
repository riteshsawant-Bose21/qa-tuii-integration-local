import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/wall_model.dart';

import '../../fusion_base_painter.dart';
import '../mixin/fusion_canvas_interactable_mixin.dart';

class WallPainter extends FusionBasePainter with FusionCanvasInteractibleMixin {
  @override
  String get id => wall.id;

  final Wall wall;
  WallPainter({required this.wall}) {
    for (int i = 0; i < wall.vertices.length - 1; i++) {
      _lines.add(FusionCanvasLine(start: wall.vertices[i], end: wall.vertices[i + 1]));
    }
  }
  final List<FusionCanvasLine> _lines = <FusionCanvasLine>[];
  Path? _cachedPath;
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    if (wall.vertices.length < 2) return;

    final bool isSelected = painter.isSelected(id);
    final Paint paint =
        Paint()
          ..color = painter.context.colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5 / painter.state.scale;

    final List<FusionCanvasPoint> points = wall.vertices;
    for (int i = 0; i < points.length - 1; i++) {
      drawDashedLine(
        canvas,
        getEffectivePosition(points[i], painter, id),
        getEffectivePosition(points[i + 1], painter, id),
        paint,
        painter,
        gapLength: nonScaling(10, painter),
        dashLength: nonScaling(10, painter),
      );
      if (isSelected) {
        _paintHighlight(canvas, painter, points[i], this);
      }
    }
    if (isSelected) {
      _paintHighlight(canvas, painter, points.last, this);
    }
  }

  void _paintHighlight(Canvas canvas, FusionCanvasPainter painter, FusionCanvasPoint point, FusionBasePainter layer) {
    final Offset effectivePosition = getEffectivePosition(point, painter, layer.id ?? "");
    final double hitRadius = nonScaling(10, painter);
    canvas.drawCircle(
      effectivePosition,
      hitRadius * 0.75,
      Paint()
        ..color = painter.context.colorScheme.primary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  Set<FusionCanvasLayerInteraction>? possibleInteractionsForElement(FusionCanvasElement element) {
    if (element is FusionCanvasLine) {
      return const <FusionCanvasLayerInteraction>{
        FusionCanvasLayerInteraction.select,
        FusionCanvasLayerInteraction.drag,
      };
    }
    return null; // Inherit from layer
  }

  @override
  List<FusionCanvasElement> get elements => <FusionCanvasElement>[
    ..._lines,
    ...wall.vertices,
  ];
  @override
  Rect getBounds(FusionCanvasPainter painter) {
    if (_cachedPath == null) {
      final Path path = Path();
      if (wall.vertices.isNotEmpty) {
        path.moveTo(wall.vertices.first.position.dx, wall.vertices.first.position.dy);
        for (final FusionCanvasPoint vertex in wall.vertices.skip(1)) {
          path.lineTo(vertex.position.dx, vertex.position.dy);
        }
      }
      _cachedPath = path;
    }
    return _cachedPath!.getBounds();
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is WallPainter) {
      return oldDelegate.wall != wall;
    }
    return true;
  }

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    // Check point hits
    for (final FusionCanvasPoint point in wall.vertices) {
      final Offset effectivePos = getEffectivePosition(point, painter, id);
      final double hitRadius = nonScaling(10, painter); // Larger hit area for points
      if ((position - effectivePos).distance <= hitRadius) {
        return point;
      }
    }

    for (final FusionCanvasLine line in _lines) {
      if (isPointNearLine(position, line.start.position, line.end.position, 10 / painter.state.scale)) {
        return line;
      }
    }
    return null;
  }

  bool isPointNearLine(Offset point, Offset start, Offset end, double threshold) {
    final double lineLength = (end - start).distance;
    if (lineLength == 0) {
      return (point - start).distance <= threshold;
    }

    final double t = ((point.dx - start.dx) * (end.dx - start.dx) + (point.dy - start.dy) * (end.dy - start.dy)) / (lineLength * lineLength);
    final double clampedT = t.clamp(0, 1);
    final Offset closestPoint = Offset(start.dx + clampedT * (end.dx - start.dx), start.dy + clampedT * (end.dy - start.dy));
    return (point - closestPoint).distance <= threshold;
  }
}
