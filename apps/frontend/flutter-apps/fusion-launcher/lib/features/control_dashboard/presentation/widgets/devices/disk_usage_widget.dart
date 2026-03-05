import 'package:flutter/material.dart';

class DiskUsageWidget extends StatelessWidget {
  final double value; // 0 to 100
  final Size size;

  const DiskUsageWidget({super.key, required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    // 1. Determine the Level (How many bars to light up)
    int activeBars;
    Color activeColor;

    if (value < 35) {
      activeBars = 1;
      activeColor = const Color(0xFF457F5A); // Muted Green
    } else if (value < 70) {
      activeBars = 2;
      activeColor = const Color(0xFFEAB14D); // Muted Yellow/Orange
    } else {
      activeBars = 3;
      activeColor = const Color(0xFFC34628); // Muted Red
    }

    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _DiskStackPainter(
          activeBars: activeBars,
          activeColor: activeColor,
          inactiveColor: Colors.grey.shade600, // Dark grey for empty bars
        ),
      ),
    );
  }
}

// --- THE PAINTER LOGIC ---

class _DiskStackPainter extends CustomPainter {
  final int activeBars; // 1, 2, or 3
  final Color activeColor;
  final Color inactiveColor;

  _DiskStackPainter({
    required this.activeBars,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Configuration for the stack
    const int totalBars = 3;
    // The gap is a fraction of the total height.
    // e.g., 0.1 means the gap is 10% of the single bar height.
    final double gapHeight = size.height * 0.10;

    // Calculate height of a single bar:
    // Total Height = (3 * barHeight) + (2 * gapHeight)
    // So: barHeight = (TotalHeight - (2 * gap)) / 3
    final double barHeight = (size.height - (2 * gapHeight)) / 4;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // We loop from 0 to 2 to draw the 3 bars.
    // i=0 is the TOP bar, i=2 is the BOTTOM bar (or vice versa).
    // The image shows the stack fills from Bottom to Top.
    // Let's index them: 0=Bottom, 1=Middle, 2=Top

    for (int i = 0; i < totalBars; i++) {
      // Determine if this specific bar should be lit
      // If activeBars is 1, only index 0 (Bottom) is lit.
      // If activeBars is 2, index 0 and 1 are lit.
      final bool isActive = i < activeBars;

      paint.color = isActive ? activeColor : inactiveColor;

      // Calculate Y position
      // Since we want index 0 at the BOTTOM, we need to invert the Y calculation.
      // Top bar (index 2) is at y=0
      // Middle bar (index 1) is at y = barHeight + gap
      // Bottom bar (index 0) is at y = 2*(barHeight + gap)

      // Let's map 'i' (0,1,2) to visual position (Bottom, Middle, Top)
      // Visual Position 0 (Top)    = Index 2
      // Visual Position 1 (Middle) = Index 1
      // Visual Position 2 (Bottom) = Index 0

      final int visualIndex = (totalBars - 1) - i;

      final double dy = visualIndex * (barHeight + gapHeight);

      // Define the rectangle for the bar
      final RRect barRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, dy, size.width, barHeight),
        Radius.circular(barHeight / 2), // Perfectly rounded ends
      );

      canvas.drawRRect(barRRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiskStackPainter oldDelegate) {
    return oldDelegate.activeBars != activeBars || oldDelegate.activeColor != activeColor;
  }
}
