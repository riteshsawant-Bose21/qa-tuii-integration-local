import 'dart:math';

import 'package:flutter/material.dart';
// --- THE CUSTOM WIDGET WRAPPER (Unchanged) ---

class GaugeWidget extends StatelessWidget {
  final double value;
  final Size size;

  const GaugeWidget({super.key, required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    Color activeColor;
    if (value < 35) {
      activeColor = const Color(0xFF2D7D46);
    } else if (value < 70) {
      activeColor = const Color(0xFFF4B430);
    } else {
      activeColor = const Color(0xFFC63623);
    }

    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _GaugePainter(
          normalizedValue: (value / 100).clamp(0.0, 1.0),
          activeColor: activeColor,
          trackColor: Colors.grey.shade600,
          strokeWidth: size.width * 0.15,
        ),
      ),
    );
  }
}

// --- THE UPDATED CUSTOM PAINTER LOGIC ---

class _GaugePainter extends CustomPainter {
  final double normalizedValue;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  _GaugePainter({
    required this.normalizedValue,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  static const double startAngle = 140 * (pi / 180);
  static const double totalSweepAngle = 260 * (pi / 180);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (min(size.width, size.height) - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw Background Track Arc
    final Paint trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, totalSweepAngle, false, trackPaint);

    // 2. Draw Active Progress Arc
    final Paint activePaint =
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final double currentSweepAngle = totalSweepAngle * normalizedValue;
    canvas.drawArc(rect, startAngle, currentSweepAngle, false, activePaint);

    // --- 3. Draw the New Sharp Needle and Anchor ---

    final Paint needlePaint =
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.fill;

    // The angle where the needle points
    final double needleAngle = startAngle + currentSweepAngle;
    // Needle length, slightly shorter than the radius
    final double needleLength = radius - (strokeWidth * 0.4);
    // Width of the needle at its base
    final double needleBaseWidth = size.width * 0.05;

    // Calculate the tip position
    final double tipX = center.dx + needleLength * cos(needleAngle);
    final double tipY = center.dy + needleLength * sin(needleAngle);
    final Offset needleTip = Offset(tipX, tipY);

    // Calculate the two points at the base of the needle.
    // They are perpendicular to the needle's angle.
    final double baseAngle1 = needleAngle - pi / 2;
    final double baseAngle2 = needleAngle + pi / 2;

    final double base1X = center.dx + (needleBaseWidth / 2) * cos(baseAngle1);
    final double base1Y = center.dy + (needleBaseWidth / 2) * sin(baseAngle1);
    final Offset needleBase1 = Offset(base1X, base1Y);

    final double base2X = center.dx + (needleBaseWidth / 2) * cos(baseAngle2);
    final double base2Y = center.dy + (needleBaseWidth / 2) * sin(baseAngle2);
    final Offset needleBase2 = Offset(base2X, base2Y);

    // Draw the tapered needle shape using a Path
    final Path needlePath =
        Path()
          ..moveTo(needleBase1.dx, needleBase1.dy)
          ..lineTo(needleTip.dx, needleTip.dy)
          ..lineTo(needleBase2.dx, needleBase2.dy)
          ..close();

    canvas.drawPath(needlePath, needlePaint);

    // Draw the center anchor/pivot circle on top
    final double anchorRadius = size.width * 0.025;
    canvas.drawCircle(center, anchorRadius, needlePaint);

    // Optional: Draw a smaller inner circle for a "donut" anchor look
    // canvas.drawCircle(center, anchorRadius * 0.5, Paint()..color = bgColor);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.normalizedValue != normalizedValue || oldDelegate.activeColor != activeColor;
  }
}
