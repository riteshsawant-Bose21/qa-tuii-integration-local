import 'package:flutter/material.dart';

import 'package:fusion_lib/fusion_lib.dart';

class CompactThermostatWidget extends StatelessWidget {
  final int temperature; // e.g., 30
  final int maxTemperature; // e.g., 100

  const CompactThermostatWidget({
    super.key,
    required this.temperature,
    this.maxTemperature = 100,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage clamped between 0.0 and 1.0
    final double percentage = (temperature / maxTemperature).clamp(0.0, 1.0);

    // Get color based on temp thresholds
    final Color statusColor = _getTempColor(temperature);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // 1. The Small Custom Painter Icon
        CustomPaint(
          // Size of the widget canvas
          size: const Size(12, 24),
          painter: _ThermostatMiniPainter(
            percentage: percentage,
            color: statusColor,
            // Thin grey outline color
            outlineColor: const Color(0xFF616161),
          ),
        ),
        const SizedBox(width: 6),

        // 2. The Text Value
        FusionAppText(
          text: "$temperature°C",
          style: context.textTheme.labelMedium,
        ),
      ],
    );
  }

  Color _getTempColor(int temp) {
    if (temp < 45) return const Color(0xFF4CAF50); // Green
    if (temp < 75) return const Color(0xFFFFC107); // Yellow/Orange
    return const Color(0xFFF44336); // Red
  }
}

class _ThermostatMiniPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color outlineColor;

  _ThermostatMiniPainter({
    required this.percentage,
    required this.color,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Configuration ---
    const double strokeWidth = 1.5;
    // The gap between the border stroke and the liquid fill
    const double fillPadding = 2.0;

    // Basic layout calculations to center everything
    const double canvasPadding = strokeWidth / 2;
    final double centerX = size.width / 2;

    // Outer Dimensions (For the stroke border)
    final double outerBulbRadius = (size.width - strokeWidth) / 2;
    final Offset bulbCenter = Offset(centerX, size.height - outerBulbRadius - canvasPadding);
    final double outerTubeWidth = outerBulbRadius * 1.2;
    final double outerTubeRadius = outerTubeWidth / 2;
    final double outerTubeTopY = canvasPadding + outerTubeRadius;

    // --- 1. Draw The Outer Border Stroke ---

    // Shape A: Outer Bulb
    final Path outerBulbPath = Path()..addOval(Rect.fromCircle(center: bulbCenter, radius: outerBulbRadius));

    // Shape B: Outer Tube (extending down into bulb center)
    final Path outerTubePath =
        Path()..addRRect(RRect.fromLTRBR(centerX - outerTubeRadius, canvasPadding, centerX + outerTubeRadius, bulbCenter.dy, Radius.circular(outerTubeRadius)));

    // Combine into seamless outer shape
    final Path outlinePath = Path.combine(PathOperation.union, outerTubePath, outerBulbPath);

    final Paint outlinePaint =
        Paint()
          ..color = outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawPath(outlinePath, outlinePaint);

    // --- 2. Draw The Inner Liquid Fill ---

    // Inner Dimensions (Reduced by fillPadding)
    final double innerBulbRadius = outerBulbRadius - fillPadding;
    final double innerTubeRadius = outerTubeRadius - fillPadding;
    // Start tube lower down to leave a gap at the top
    final double innerTubeTopY = outerTubeTopY + fillPadding;

    // Ensure dimensions don't go negative if widget is too small
    if (innerBulbRadius <= 0 || innerTubeRadius <= 0) return;

    // Create Inner Shape for clipping the fill
    final Path innerBulbPath = Path()..addOval(Rect.fromCircle(center: bulbCenter, radius: innerBulbRadius));

    final Path innerTubePath =
        Path()..addRRect(RRect.fromLTRBR(centerX - innerTubeRadius, innerTubeTopY, centerX + innerTubeRadius, bulbCenter.dy, Radius.circular(innerTubeRadius)));

    // Combine to get the shape representing the "hollow" inside of the glass
    final Path innerContainerPath = Path.combine(PathOperation.union, innerTubePath, innerBulbPath);

    // Calculate Fill Level based on percentage
    // Total height available inside the inner container
    final double totalInnerHeight = (bulbCenter.dy + innerBulbRadius) - innerTubeTopY;
    final double fillHeight = totalInnerHeight * percentage;
    // The Y coordinate where the liquid stops (from bottom up)
    final double fillTopY = (bulbCenter.dy + innerBulbRadius) - fillHeight;

    // Define a large rectangle representing the liquid level
    final Rect fillLevelRect = Rect.fromLTRB(
      0, // Left boundary (doesn't matter much, intersection handles it)
      fillTopY, // Top level of liquid
      size.width, // Right boundary
      size.height, // Bottom boundary
    );

    final Path fillRectPath = Path()..addRect(fillLevelRect);

    // Crucial Step: Intersect the liquid level rectangle with the INNER container shape.
    // This ensures the fill stays inside the padded area.
    final Path finalFillPath = Path.combine(PathOperation.intersect, innerContainerPath, fillRectPath);

    final Paint fillPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    canvas.drawPath(finalFillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _ThermostatMiniPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
