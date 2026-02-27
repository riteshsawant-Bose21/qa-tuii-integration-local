import 'dart:ui';

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

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Rect dstRect = Rect.fromLTWH(position.dx, position.dy, this.size.width, this.size.height);
    drawImage(
      canvas: canvas,
      imagePath: image,
      rect: dstRect,
      painter: painter,
    );
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
