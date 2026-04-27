import 'dart:math';

import 'package:flutter/material.dart';

class ArcSlider extends StatefulWidget {
  /// value = 0 to 100
  final double value;
  final Color color;
  final ValueChanged<double>? onChanged;

  const ArcSlider({
    super.key,
    required this.value,
    required this.color,
    this.onChanged,
  });

  @override
  State<ArcSlider> createState() =>
      _ArcSliderState();
}

class _ArcSliderState extends State<ArcSlider> {
  late double volume; // 0 -> 100

  @override
  void initState() {
    super.initState();
    volume = widget.value.clamp(
      0.0,
      100.0,
    );
  }

  @override
  void didUpdateWidget(
      covariant ArcSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      volume = widget.value.clamp(
        0.0,
        100.0,
      );
    }
  }

  void _updateValue(
      Offset localPos,
      Size size,
      ) {
    final center = Offset(
      size.width / 2,
      size.height - 10,
    );

    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    double angle = atan2(dy, dx);

    if (angle < 0) {
      angle += 2 * pi;
    }

    if (angle < pi ||
        angle > 2 * pi) {
      return;
    }

    double progress =
        (angle - pi) / pi;

    progress =
        progress.clamp(0.0, 1.0);

    if (progress < 0.02) {
      progress = 0.0;
    }

    if (progress > 0.98) {
      progress = 1.0;
    }

    final value =
    (progress * 100).roundToDouble();

    setState(() {
      volume = value;
    });

    widget.onChanged?.call(
      volume,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(
          c.maxWidth,
          c.maxWidth / 2 + 30,
        );

        return GestureDetector(
          behavior:
          HitTestBehavior.opaque,
          onPanDown: (d) =>
              _updateValue(
                d.localPosition,
                size,
              ),
          onPanUpdate: (d) =>
              _updateValue(
                d.localPosition,
                size,
              ),
          child: CustomPaint(
            size: size,
            painter: _ArcPainter(
              volume: volume,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double volume; // 0-100
  final Color color;

  _ArcPainter({
    required this.volume,
    required this.color,
  });

  @override
  void paint(
      Canvas canvas,
      Size size) {
    const int totalTicks = 50;
    const double startAngle = pi;
    const double sweepAngle = pi;
    const double tickLength = 18;
    const double shortTickLength =
    12;
    const double tickWidth = 2.8;
    const double gapFromArc = 4;

    final center = Offset(
      size.width / 2,
      size.height - 10,
    );

    final radius =
        size.width / 2 - 20;

    final activeColor = color;
    final inactiveColor =
    const Color(0xFF3A3A3A);

    final progress =
        volume / 100;

    for (int i = 0;
    i < totalTicks;
    i++) {
      final fraction =
          i / (totalTicks - 1);

      final angle =
          startAngle +
              sweepAngle *
                  fraction;

      final isActive =
          fraction <= progress;

      final isLong =
          i % 3 == 0;

      final tickLen = isLong
          ? tickLength
          : shortTickLength;

      final outerR =
          radius - gapFromArc;

      final innerR =
          outerR - tickLen;

      final outerX =
          center.dx +
              outerR *
                  cos(angle);

      final outerY =
          center.dy +
              outerR *
                  sin(angle);

      final innerX =
          center.dx +
              innerR *
                  cos(angle);

      final innerY =
          center.dy +
              innerR *
                  sin(angle);

      Color tickColor;

      if (isActive) {
        final brightness =
            0.65 +
                0.35 *
                    (fraction /
                        progress.clamp(
                          0.01,
                          1.0,
                        ));

        tickColor = Color.lerp(
          activeColor.withOpacity(
            0.5,
          ),
          activeColor,
          brightness.clamp(
            0.0,
            1.0,
          ),
        )!;
      } else {
        tickColor =
            inactiveColor;
      }

      final paint = Paint()
        ..color = tickColor
        ..strokeWidth =
            tickWidth
        ..strokeCap =
            StrokeCap.round;

      canvas.drawLine(
        Offset(
          outerX,
          outerY,
        ),
        Offset(
          innerX,
          innerY,
        ),
        paint,
      );
    }

  }

  @override
  bool shouldRepaint(
      _ArcPainter old) =>
      old.volume != volume ||
          old.color != color;
}
