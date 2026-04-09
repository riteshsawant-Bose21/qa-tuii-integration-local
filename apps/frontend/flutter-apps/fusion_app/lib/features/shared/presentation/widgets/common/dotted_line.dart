import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
/*Usage Examples
# Dotted Divider (Rounded Dots)
  const DottedLine(
      dashLength: 4,
      dashGap: 6,
      thickness: 1,
      color: Colors.white24,
      cap: StrokeCap.round,
    );

# Dashed Divider (Flat Ends)
  const DottedLine(
        dashLength: 10,
        dashGap: 6,
        thickness: 1,
        cap: StrokeCap.butt,
      );

# Vertical Dotted Separator
    const SizedBox(
    height: 40,
        child: DottedLine(
        axis: Axis.vertical,
        dashLength: 4,
        dashGap: 4,
        ),
    );

# Thick Dotted Line
      const DottedLine(
      dashLength: 6,
      dashGap: 4,
      thickness: 2,
      cap: StrokeCap.round,
      );

# Theme-Aware Divider
    DottedLine(
    color: Theme.of(context).dividerColor,
    );

# StrokeCap Guide
    StrokeCap	Visual Style
    StrokeCap.round	● ● ● Rounded dots
    StrokeCap.butt	▬ ▬ ▬ Flat dashes
    StrokeCap.square	■ ■ ■ Square ends
*/
class CustomDottedLine extends StatelessWidget {
  final Axis axis;
  final double dashLength;
  final double dashGap;
  final double thickness;
  final Color color;
  final StrokeCap cap;

  const CustomDottedLine({
    super.key,
    this.axis = Axis.horizontal,
    this.dashLength = 6,
    this.dashGap = 4,
    this.thickness = 1,
    required this.color,
    this.cap = StrokeCap.round,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: axis == Axis.horizontal
          ? Size(double.infinity, thickness)
          : Size(thickness, double.infinity),
      painter: _DottedLinePainter(
        axis: axis,
        dashLength: dashLength,
        dashGap: dashGap,
        thickness: thickness,
        color: color,
        cap: cap,
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Axis axis;
  final double dashLength;
  final double dashGap;
  final double thickness;
  final Color color;
  final StrokeCap cap;

  _DottedLinePainter({
    required this.axis,
    required this.dashLength,
    required this.dashGap,
    required this.thickness,
    required this.color,
    required this.cap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = cap;

    double start = 0;
    final totalLength = axis == Axis.horizontal ? size.width : size.height;

    while (start < totalLength) {
      final end = start + dashLength;

      if (axis == Axis.horizontal) {
        canvas.drawLine(Offset(start, 0), Offset(end, 0), paint);
      } else {
        canvas.drawLine(Offset(0, start), Offset(0, end), paint);
      }

      start += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
