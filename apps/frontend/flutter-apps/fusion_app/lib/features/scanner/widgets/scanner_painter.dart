import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ScannerOverlayPainter extends CustomPainter {
  final BuildContext context;

  ScannerOverlayPainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = context.colorScheme.primaryBlack.withOpacity(0.6);

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 80),
      width: 260,
      height: 180,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    final framePaint = Paint()
      ..color = context.colorScheme.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const corner = 30.0;

    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + const Offset(corner, 0), framePaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + const Offset(0, corner), framePaint);

    canvas.drawLine(scanArea.topRight, scanArea.topRight - const Offset(corner, 0), framePaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + const Offset(0, corner), framePaint);

    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + const Offset(corner, 0), framePaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft - const Offset(0, corner), framePaint);

    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight - const Offset(corner, 0), framePaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight - const Offset(0, corner), framePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}