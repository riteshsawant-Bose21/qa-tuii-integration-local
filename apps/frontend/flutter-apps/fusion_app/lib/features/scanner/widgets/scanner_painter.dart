import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ScannerOverlayPainter extends CustomPainter {
  final BuildContext context;
  final double scanProgress; // 0 → 1

  ScannerOverlayPainter(this.context, {required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    /// 🔹 Overlay background
    final overlayPaint = Paint()
      ..color = context.colorScheme.primaryBlack.withValues(alpha: 0.6);

    /// 🔹 Scan area (cutout)
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 80),
      width: 260,
      height: 260,
    );

    const outerRadiusValue = 10.0;
    final scanRRect = RRect.fromRectAndRadius(
      scanArea,
      const Radius.circular(outerRadiusValue),
    );

    /// 🔹 Transparent cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(scanRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    /// 🔥 OUTSIDE BORDER CONFIG
    const borderPadding = 12.0;
    const cornerLength = 24.0;

    final outerRect = scanArea.inflate(borderPadding);

    /// 👉 Correct radius for outside border
    final outerCornerRadius = outerRadiusValue + borderPadding;

    final framePaint = Paint()
      ..color = context.colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = outerRect;

    /// =========================
    /// 🔸 TOP LEFT
    /// =========================
    final topLeft = Path()
      ..moveTo(r.left + outerCornerRadius + cornerLength, r.top)
      ..lineTo(r.left + outerCornerRadius, r.top)
      ..arcToPoint(
        Offset(r.left, r.top + outerCornerRadius),
        radius: Radius.circular(outerCornerRadius),
        clockwise: false,
      )
      ..lineTo(r.left, r.top + outerCornerRadius + cornerLength);

    canvas.drawPath(topLeft, framePaint);

    /// =========================
    /// 🔸 TOP RIGHT
    /// =========================
    final topRight = Path()
      ..moveTo(r.right - outerCornerRadius - cornerLength, r.top)
      ..lineTo(r.right - outerCornerRadius, r.top)
      ..arcToPoint(
        Offset(r.right, r.top + outerCornerRadius),
        radius: Radius.circular(outerCornerRadius),
        clockwise: true,
      )
      ..lineTo(r.right, r.top + outerCornerRadius + cornerLength);

    canvas.drawPath(topRight, framePaint);

    /// =========================
    /// 🔸 BOTTOM LEFT
    /// =========================
    final bottomLeft = Path()
      ..moveTo(r.left + outerCornerRadius + cornerLength, r.bottom)
      ..lineTo(r.left + outerCornerRadius, r.bottom)
      ..arcToPoint(
        Offset(r.left, r.bottom - outerCornerRadius),
        radius: Radius.circular(outerCornerRadius),
        clockwise: true,
      )
      ..lineTo(r.left, r.bottom - outerCornerRadius - cornerLength);

    canvas.drawPath(bottomLeft, framePaint);

    /// =========================
    /// 🔸 BOTTOM RIGHT
    /// =========================
    final bottomRight = Path()
      ..moveTo(r.right - outerCornerRadius - cornerLength, r.bottom)
      ..lineTo(r.right - outerCornerRadius, r.bottom)
      ..arcToPoint(
        Offset(r.right, r.bottom - outerCornerRadius),
        radius: Radius.circular(outerCornerRadius),
        clockwise: false,
      )
      ..lineTo(r.right, r.bottom - outerCornerRadius - cornerLength);

    canvas.drawPath(bottomRight, framePaint);

    /// =====================================
    /// 🔥 IMPROVED SCANNING LINE
    /// =====================================

    /// =====================================
    /// 🔥 SCAN LINE WITH DOWNWARD SHADOW
    /// =====================================

    final scanY = scanArea.top + (scanArea.height * scanProgress);

    /// 1️⃣ Main sharp line
    final linePaint = Paint()
      ..color = context.colorScheme.primary
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(scanArea.left, scanY),
      Offset(scanArea.right, scanY),
      linePaint,
    );

    /// 2️⃣ Shadow ONLY below the line
    final shadowHeight = 12.0;

    final shadowGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        context.colorScheme.primary.withValues(alpha: 0.1), // strong near line
        context.colorScheme.primary.withValues(alpha: 0.1),
        Colors.transparent, // fade out
      ],
    );

    final shadowPaint = Paint()
      ..shader = shadowGradient.createShader(
        Rect.fromLTWH(
          scanArea.left,
          scanY, // 👈 starts exactly at the line
          scanArea.width,
          shadowHeight,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(
        scanArea.left,
        scanY,
        scanArea.width,
        shadowHeight,
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}