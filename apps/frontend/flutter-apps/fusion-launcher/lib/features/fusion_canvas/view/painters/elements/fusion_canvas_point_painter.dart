import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

import '../fusion_canvas_painter.dart';

class FusionCanvasPointPainter extends FusionBasePainter {
  final FusionCanvasPoint point;
  final double radius;
  final Color color;
  final String layerId;
  @override
  String get id => point.id;
  FusionCanvasPointPainter({
    required this.point,
    this.radius = 5.0,
    required this.layerId,
    this.color = const Color(0xFF000000),
  });

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter fusionCanvasPainter) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    canvas.drawCircle(getEffectivePosition(point, fusionCanvasPainter, layerId), nonScaling(radius, fusionCanvasPainter), paint);
  }

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter fusionCanvasPainter) {
    return (position - getEffectivePosition(point, fusionCanvasPainter, layerId)).distance <= nonScaling(radius, fusionCanvasPainter) ? point : null;
  }

  @override
  List<FusionCanvasPoint> get points => <FusionCanvasPoint>[
    point,
  ];

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! FusionCanvasPointPainter) return true;
    return oldDelegate.point != point || oldDelegate.radius != radius || oldDelegate.color != color;
  }
}
