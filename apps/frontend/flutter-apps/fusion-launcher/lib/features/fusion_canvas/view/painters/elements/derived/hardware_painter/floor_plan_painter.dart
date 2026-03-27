import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

import '../../fusion_image_painter.dart';

class FloorPlanPainter extends FusionImagePainter {
  final bool showSpl;
  FloorPlanPainter({required super.image, required super.position, required super.size, required this.showSpl});

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Rect dst = getRect();
    canvas.saveLayer(dst, Paint());
    drawImage(canvas: canvas, imagePath: image, rect: dst, painter: painter, paint: Paint());

    const List<double> invLum = <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, -0.2126, -0.7152, -0.0722, 1, 0];
    Paint floorPlanPaint = Paint();

    if (showSpl) {
      floorPlanPaint =
          Paint()
            ..colorFilter = const ColorFilter.matrix(invLum)
            ..blendMode = BlendMode.dstIn;
    }

    drawImage(canvas: canvas, imagePath: image, rect: dst, painter: painter, paint: floorPlanPaint);

    canvas.restore();
  }
}
