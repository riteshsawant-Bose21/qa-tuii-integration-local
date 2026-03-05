import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';
import 'fusion_canvas_point_painter.dart';

class FusionCanvasLinePainter extends FusionBasePainter {
  final FusionCanvasLine line;
  final double thickness;
  final bool showPoints;
  final Color color;
  final String layerId;
  @override
  String get id => line.id;
  FusionCanvasLinePainter({
    required this.line,
    this.thickness = 2.0,
    this.showPoints = false,
    required this.color,
    required this.layerId,
  });

  final List<FusionCanvasPointPainter> _pointPainters = <FusionCanvasPointPainter>[];

  void _buildPointPainters() {
    if (!showPoints) {
      _pointPainters.clear();
      return;
    }
    if (_pointPainters.isNotEmpty) return;
    _pointPainters
      ..clear()
      ..add(FusionCanvasPointPainter(point: start, layerId: layerId, radius: thickness * 2, color: color))
      ..add(FusionCanvasPointPainter(point: end, layerId: layerId, radius: thickness * 2, color: color));
  }

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    _buildPointPainters();
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = nonScaling(thickness, painter);
    canvas.drawLine(getEffectivePosition(start, painter, layerId), getEffectivePosition(end, painter, layerId), paint);

    if (showPoints) {
      for (final FusionCanvasPointPainter pointPainter in _pointPainters) {
        pointPainter.paint(canvas, size, painter);
      }
    }
  }

  FusionCanvasPoint get start => line.start;
  FusionCanvasPoint get end => line.end;

  @override
  List<FusionCanvasPoint> get points => <FusionCanvasPoint>[
    start,
    end,
  ];

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    for (final FusionCanvasPointPainter pointPainter in _pointPainters) {
      final FusionCanvasElement? hitId = pointPainter.isHit(position, painter);
      if (hitId != null) {
        // print("Hit point ${pointPainter.point.id} of line $id");
        return hitId;
      }
    }

    // Check line hit using distance from point to line segment
    final double distance = _distanceFromPointToLineSegment(
      position,
      getEffectivePosition(start, painter, layerId),
      getEffectivePosition(end, painter, layerId),
    );
    final double nonScaling2 = nonScaling(thickness, painter) * 2;
    if (distance <= nonScaling2) {
      // print("Hit line $id with distance $distance     Thickness threshold: $nonScaling2");
      return line;
    } else {
      // if (distance < 20) print("Missed line $id with distance $distance.    Thickness threshold: $nonScaling2");
    }
    return null;
  }

  double _distanceFromPointToLineSegment(Offset p, Offset a, Offset b) {
    final double lengthSquared = (b - a).distanceSquared;
    if (lengthSquared == 0) return (p - a).distance; // a and b are the same point
    final Offset pa = p - a;
    final Offset ba = b - a;
    final double dotProduct = pa.dx * ba.dx + pa.dy * ba.dy;
    final double t = dotProduct / lengthSquared;
    if (t < 0) return (p - a).distance; // Beyond point a
    if (t > 1) return (p - b).distance; // Beyond point b
    final Offset projection = a + (b - a) * t;
    return (p - projection).distance;
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! FusionCanvasLinePainter) return true;
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.thickness != thickness ||
        oldDelegate.showPoints != showPoints ||
        oldDelegate.color != color ||
        oldDelegate.layerId != layerId;
  }
}
