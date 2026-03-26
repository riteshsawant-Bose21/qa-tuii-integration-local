import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class VolumeMeterPainter extends CustomPainter {
  final double value; // 0 - 100
  final Color trackColor;
  final List<Color> gradientColors;

  VolumeMeterPainter({
    required this.value,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double thumbRadius = 18;
    const double trackRadius = 40;

    final double meterHeight = size.height;
    final double meterWidth = 30;

    /// Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    final RRect track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, meterWidth, meterHeight),
      const Radius.circular(trackRadius),
    );

    canvas.drawRRect(track, trackPaint);
    /// Fill percentage
    final double percent = (value / 100).clamp(0.0, 1.0);
    final double fillHeight = meterHeight * percent;

    if (fillHeight > 0) {
      final Rect fillRect = Rect.fromLTWH(
        0,
        meterHeight - fillHeight,
        meterWidth,
        fillHeight,
      );

      /// Gradient
      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, meterHeight),
          Offset(0, 0),
          [
            const Color(0xFF3BA37A),
            const Color(0xFF9ED7C4),
          ],
        );

      /// Clip inside track so it doesn't overflow
      canvas.save();
      canvas.clipRRect(track);

      canvas.drawRect(fillRect, fillPaint);

      canvas.restore();
    }
    /// Normalize value
    // final double percentage = (value / 100).clamp(0.0, 1.0);
    //
    // final double filledHeight = meterHeight * percentage;
    //
    // /// Gradient fill
    // final fillPaint = Paint()
    //   ..shader = ui.Gradient.linear(
    //     Offset(0, meterHeight),
    //     Offset(0, 0),
    //     gradientColors,
    //   );
    //
    // final RRect fillRect = RRect.fromRectAndRadius(
    //   Rect.fromLTWH(
    //     0,
    //     meterHeight - filledHeight,
    //     meterWidth,
    //     filledHeight,
    //   ),
    //   const Radius.circular(trackRadius),
    // );
    //
    // canvas.drawRRect(fillRect, fillPaint);

    /// Thumb position
    final double thumbY = meterHeight - fillHeight;

    /// Thumb shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(meterWidth / 2, thumbY),
      thumbRadius + 4,
      shadowPaint,
    );

    /// Thumb
    final thumbPaint = Paint()..color = Colors.white;

    canvas.drawCircle(
      Offset(meterWidth / 2, thumbY),
      thumbRadius,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant VolumeMeterPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class VolumeMeterPainterBG extends CustomPainter {
  final double value; // 0 - 100
  final Color trackColor;
  final List<Color> gradientColors;

  VolumeMeterPainterBG({
    required this.value,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double thumbRadius = 18;
    const double trackRadius = 40;

    final double meterHeight = size.height;
    final double meterWidth = size.width;

    /// Track
    // final trackPaint = Paint()
    //   ..color = trackColor
    //   ..style = PaintingStyle.fill;
    //
    final RRect track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, meterWidth, meterHeight),
      const Radius.circular(trackRadius),
    );
    //
    // canvas.drawRRect(track, trackPaint);
    // /// Fill percentage
   final double percent = (value / 100).clamp(0.0, 1.0);
     final double fillHeight = meterHeight * percent;

    if (fillHeight > 0) {
      final Rect fillRect = Rect.fromLTWH(
        0,
        meterHeight - fillHeight,
        meterWidth,
        fillHeight,
      );

      /// Gradient
      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, meterHeight),
          Offset(0, 0),
          gradientColors,
        );

      /// Clip inside track so it doesn't overflow
      canvas.save();
      canvas.clipRRect(track);

      canvas.drawRect(fillRect, fillPaint);

      canvas.restore();
    }
    /// Thumb position
    final double thumbY = meterHeight - fillHeight;

    /// Thumb shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(meterWidth / 2, thumbY),
      thumbRadius + 4,
      shadowPaint,
    );

    /// Thumb
    final thumbPaint = Paint()..color = Colors.white;

    canvas.drawCircle(
      Offset(meterWidth / 2, thumbY),
      thumbRadius,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant VolumeMeterPainterBG oldDelegate) {
    return true;
  }
}