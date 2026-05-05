import 'dart:math' as math;
import 'dart:ui' as painting;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/scheduling/view/sections/scheduler/widgets/time_picker.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class InlineClockPicker extends StatefulWidget {
  const InlineClockPicker({
    required this.time,
    required this.mode,
    required this.onChanged,
    this.onHourSelected,
  });

  final TimeOfDay time;
  final ClockMode mode;
  final ValueChanged<TimeOfDay> onChanged;
  final VoidCallback? onHourSelected;

  @override
  State<InlineClockPicker> createState() => InlineClockPickerState();
}

class InlineClockPickerState extends State<InlineClockPicker> {
  static const double _size = 170;
  static const double _padding = 20;

  void _handlePan(Offset localPos) {
    const Offset center = Offset(_size / 2, _size / 2);
    final Offset delta = localPos - center;
    double angle = math.atan2(delta.dx, -delta.dy);
    if (angle < 0) angle += 2 * math.pi;

    if (widget.mode == ClockMode.hour) {
      int hour = (angle / (2 * math.pi / 12)).round() % 12;
      if (hour == 0) hour = 12;

      final bool isAM = widget.time.period == DayPeriod.am;
      final int hour24 = isAM ? (hour == 12 ? 0 : hour) : (hour == 12 ? 12 : hour + 12);
      widget.onChanged(TimeOfDay(hour: hour24, minute: widget.time.minute));
    } else {
      final int minute = (angle / (2 * math.pi / 60)).round() % 60;
      widget.onChanged(TimeOfDay(hour: widget.time.hour, minute: minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onPanDown: (DragDownDetails d) => _handlePan(d.localPosition),
        onPanUpdate: (DragUpdateDetails d) => _handlePan(d.localPosition),
        onTapUp: (TapUpDetails d) {
          _handlePan(d.localPosition);
          if (widget.mode == ClockMode.hour) {
            widget.onHourSelected?.call();
          }
        },
        child: CustomPaint(
          size: const Size(_size, _size),
          painter: _ClockPainter(
            time: widget.time,
            mode: widget.mode,
            faceColor: context.colorScheme.elevation2,
            numberColor: context.colorScheme.textBody,
            selectorColor: context.colorScheme.primaryColor,
            padding: _padding,
          ),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.time,
    required this.mode,
    required this.faceColor,
    required this.numberColor,
    required this.selectorColor,
    required this.padding,
  });

  final TimeOfDay time;
  final ClockMode mode;
  final Color faceColor;
  final Color numberColor;
  final Color selectorColor;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    final double numberRadius = radius - padding;

    // Face
    canvas.drawCircle(center, radius, Paint()..color = faceColor);

    // Compute selector angle based on mode
    final double selectedAngle;
    if (mode == ClockMode.hour) {
      final int selectedHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      selectedAngle = (selectedHour * 2 * math.pi / 12) - math.pi / 2;
    } else {
      selectedAngle = (time.minute * 2 * math.pi / 60) - math.pi / 2;
    }

    final Offset selectorPos = Offset(
      center.dx + numberRadius * math.cos(selectedAngle),
      center.dy + numberRadius * math.sin(selectedAngle),
    );

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = selectorColor);

    // Hand line
    canvas.drawLine(
      center,
      selectorPos,
      Paint()
        ..color = selectorColor
        ..strokeWidth = 2,
    );

    // Selector circle
    canvas.drawCircle(selectorPos, 14, Paint()..color = selectorColor);

    // Number labels
    if (mode == ClockMode.hour) {
      _drawHourLabels(canvas, center, numberRadius);
    } else {
      _drawMinuteLabels(canvas, center, numberRadius);
    }
  }

  void _drawHourLabels(Canvas canvas, Offset center, double numberRadius) {
    final int selectedHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    for (int i = 1; i <= 12; i++) {
      final double angle = (i * 2 * math.pi / 12) - math.pi / 2;
      final Offset pos = Offset(
        center.dx + numberRadius * math.cos(angle),
        center.dy + numberRadius * math.sin(angle),
      );
      _paintLabel(canvas, pos, i.toString(), i == selectedHour);
    }
  }

  void _drawMinuteLabels(Canvas canvas, Offset center, double numberRadius) {
    // Show 0, 5, 10, ... 55 (12 labels, same positions as hour dial)
    for (int i = 0; i < 12; i++) {
      final int minute = i * 5;
      final double angle = (minute * 2 * math.pi / 60) - math.pi / 2;
      final Offset pos = Offset(
        center.dx + numberRadius * math.cos(angle),
        center.dy + numberRadius * math.sin(angle),
      );
      final bool isSelected = minute == time.minute;
      _paintLabel(canvas, pos, minute.toString().padLeft(2, '0'), isSelected);
    }
  }

  void _paintLabel(Canvas canvas, Offset pos, String text, bool isSelected) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isSelected ? Colors.white : numberColor,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      textDirection: painting.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.mode != mode;
  }
}
