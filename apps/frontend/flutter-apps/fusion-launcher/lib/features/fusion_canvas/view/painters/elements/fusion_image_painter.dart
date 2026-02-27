import 'dart:ui';

import '../fusion_canvas_painter.dart';

class FusionImagePainter extends FusionBasePainter {
  final Image? image;
  final Offset position;
  final Size size;

  FusionImagePainter({
    required this.image,
    required this.position,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    if (image == null) return;
    final Rect dstRect = Rect.fromLTWH(position.dx, position.dy, this.size.width, this.size.height);
    canvas.drawImageRect(image!, Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()), dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
