import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';

import '../fusion_canvas_painter.dart';

class FusionImagePainter extends FusionBasePainter {
  final String image;
  final Offset position;
  final Size size;

  FusionImagePainter({
    required this.image,
    required this.position,
    required this.size,
  });

  Rect getRect() {
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    drawImage(
      canvas: canvas,
      imagePath: image,
      rect: getRect(),
      painter: painter,
    );
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
