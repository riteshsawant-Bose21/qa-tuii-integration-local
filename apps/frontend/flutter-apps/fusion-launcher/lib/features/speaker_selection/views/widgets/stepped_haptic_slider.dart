import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A highly customizable stepped horizontal slider with haptic feedback at each stop.
///
/// - Thumb drags **smoothly** — no jumping between stops while dragging.
/// - Haptic feedback fires the instant the thumb's center crosses a stop line.
/// - Thumb is fully contained inside the track with configurable inner padding.
/// - Drag is continuous; haptic triggers when crossing each step line.
///
/// Example:
/// ```dart
/// SteppedHapticSlider(
///   min: 50,
///   max: 100,
///   interval: 10,
///   initialValue: 70,
///   onChanged: (val) => print(val),
/// )
/// ```
class SteppedHapticSlider extends StatefulWidget {
  /// Minimum value of the slider.
  final double min;

  /// Maximum value of the slider.
  final double max;

  /// Interval between each stop/tick mark. Must divide (max - min) evenly.
  final double interval;

  /// Initial value of the slider.
  final double initialValue;

  /// Callback fired whenever the value changes during drag (continuous).
  final ValueChanged<double>? onChanged;

  /// Callback fired when the user lifts their finger (continuous value).
  final ValueChanged<double>? onChangeEnd;

  // ── Track ──────────────────────────────────────────────────────────────────

  /// Height of the slider track (pill shape).
  final double trackHeight;

  /// Background color of the unfilled portion of the track.
  final Color trackBackgroundColor;

  /// Color of the filled (active) portion of the track.
  final Color trackFillColor;

  /// Border radius of the track pill. Defaults to [trackHeight] / 2 (fully rounded).
  final double? trackBorderRadius;

  /// Horizontal padding inside the track so the thumb never touches the edges.
  /// Defaults to [thumbDiameter] / 2 + 2 (matches the screenshot aesthetic).
  final double? trackInnerPadding;

  /// Magnetic snap window around each step, expressed as a fraction of [interval].
  /// Example: 0.10 means +/-10% of each interval around a stop will snap exactly.
  final double stepSnapWindowFactor;

  // ── Thumb ──────────────────────────────────────────────────────────────────

  /// Diameter of the circular thumb.
  final double thumbDiameter;

  /// Color of the thumb.
  final Color thumbColor;

  /// Elevation/shadow spread of the thumb.
  final double thumbElevation;

  /// Color of the thumb shadow.
  final Color thumbShadowColor;

  // ── Tick marks ─────────────────────────────────────────────────────────────

  /// Height of each tick/stop mark drawn on the track.
  final double tickHeight;

  /// Width of each tick/stop mark.
  final double tickWidth;

  /// Color of tick marks in the active (filled) region.
  final Color tickColorActive;

  /// Color of tick marks in the inactive (unfilled) region.
  final Color tickColorInactive;

  /// Whether to show tick marks at min and max edges.
  final bool showEdgeTicks;

  // ── Labels ─────────────────────────────────────────────────────────────────

  /// Whether to show numeric labels below the slider.
  final bool showLabels;

  /// Text style for the labels.
  final TextStyle? labelStyle;

  /// Formats a stop value to a display string. Defaults to `value.toInt().toString()`.
  final String Function(double value)? labelFormatter;

  /// Spacing between the bottom of the track and the top of the labels.
  final double labelSpacing;

  // ── Drag value indicator ─────────────────────────────────────────────────

  /// Show current value above the thumb while dragging.
  final bool showValueIndicatorOnDrag;

  /// Text style for the drag value indicator.
  final TextStyle? valueIndicatorTextStyle;

  /// Background color of the drag value indicator bubble.
  final Color valueIndicatorBackgroundColor;

  /// Padding inside the drag value indicator bubble.
  final EdgeInsets valueIndicatorPadding;

  /// Spacing between the track top and value bubble bottom.
  final double valueIndicatorBottomSpacing;

  // ── Haptics ────────────────────────────────────────────────────────────────

  /// Type of haptic feedback to trigger when the thumb crosses a stop.
  final HapticFeedbackType hapticFeedbackType;

  /// Whether haptic feedback is enabled.
  final bool hapticEnabled;

  const SteppedHapticSlider({
    super.key,
    required this.min,
    required this.max,
    required this.interval,
    this.initialValue = 0,
    this.onChanged,
    this.onChangeEnd,
    // Track
    this.trackHeight = 36,
    this.trackBackgroundColor = const Color(0xFF2A2A2A),
    this.trackFillColor = const Color(0xFF3DBF7A),
    this.trackBorderRadius,
    this.trackInnerPadding,
    this.stepSnapWindowFactor = 0.12,
    // Thumb
    this.thumbDiameter = 28,
    this.thumbColor = Colors.white,
    this.thumbElevation = 6,
    this.thumbShadowColor = Colors.black38,
    // Ticks
    this.tickHeight = 12,
    this.tickWidth = 2,
    this.tickColorActive = Colors.white24,
    this.tickColorInactive = Colors.white24,
    this.showEdgeTicks = false,
    // Labels
    this.showLabels = true,
    this.labelStyle,
    this.labelFormatter,
    this.labelSpacing = 8,
    // Drag value indicator
    this.showValueIndicatorOnDrag = true,
    this.valueIndicatorTextStyle,
    this.valueIndicatorBackgroundColor = const Color(0xFF2A2A2A),
    this.valueIndicatorPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.valueIndicatorBottomSpacing = 6,
    // Haptics
    this.hapticFeedbackType = HapticFeedbackType.selection,
    this.hapticEnabled = true,
  }) : assert(
         interval > 0 && (max - min) % interval == 0,
         'interval must be > 0 and divide (max - min) evenly',
       );

  @override
  State<SteppedHapticSlider> createState() => _SteppedHapticSliderState();
}

class _SteppedHapticSliderState extends State<SteppedHapticSlider> {
  /// Raw (unsnapped) 0→1 ratio that drives smooth thumb movement while dragging.
  late double _rawRatio;

  /// Last interval index crossed by thumb center (used for haptic trigger).
  late int _lastCrossedStepIndex;

  double get _effectivePadding => widget.trackInnerPadding ?? (widget.thumbDiameter / 2 + 2);

  @override
  void initState() {
    super.initState();
    final double clamped = widget.initialValue.clamp(widget.min, widget.max);
    _rawRatio = ((clamped - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    _lastCrossedStepIndex = _stepIndexForValue(clamped);
  }

  List<double> get _stops {
    final List<double> s = <double>[];
    double v = widget.min;
    while (v <= widget.max + 1e-9) {
      s.add(v);
      v += widget.interval;
    }
    return s;
  }

  double _nearestStop(double value) {
    double best = _stops.first;
    double bestDist = (value - best).abs();
    for (final double stop in _stops) {
      final double d = (value - stop).abs();
      if (d < bestDist) {
        bestDist = d;
        best = stop;
      }
    }
    return best;
  }

  int _stepIndexForValue(double value) {
    final int maxStepIndex = _stops.length - 1;
    final int index = ((value - widget.min) / widget.interval).floor();
    return index.clamp(0, maxStepIndex);
  }

  /// Convert a local dx touch position to a 0→1 ratio, clamped to usable range.
  double _dxToRatio(double localDx, double totalWidth) {
    final double usable = totalWidth - _effectivePadding * 2;
    if (usable <= 0) return 0;
    return ((localDx - _effectivePadding) / usable).clamp(0.0, 1.0);
  }

  void _onDrag(double localDx, double totalWidth) {
    final double rawRatio = _dxToRatio(localDx, totalWidth);
    final double rawValue = widget.min + rawRatio * (widget.max - widget.min);

    final double nearestStop = _nearestStop(rawValue);
    final double snapWindow = widget.interval * widget.stepSnapWindowFactor;
    final bool shouldSnapToStep = (rawValue - nearestStop).abs() <= snapWindow;

    final double effectiveValue = shouldSnapToStep ? nearestStop : rawValue;
    final double effectiveRatio = ((effectiveValue - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

    final int crossedStepIndex = _stepIndexForValue(effectiveValue);

    setState(() => _rawRatio = effectiveRatio);
    widget.onChanged?.call(effectiveValue);

    // Fire haptic only when thumb crosses a step line.
    if (crossedStepIndex != _lastCrossedStepIndex) {
      _lastCrossedStepIndex = crossedStepIndex;
      _triggerHaptic();
    }
  }

  void _onDragEnd() {
    final double rawValue = widget.min + _rawRatio * (widget.max - widget.min);
    widget.onChangeEnd?.call(rawValue);
  }

  void _triggerHaptic() {
    if (!widget.hapticEnabled) return;
    switch (widget.hapticFeedbackType) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveLabelStyle =
        widget.labelStyle ??
        TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        );

    final TextStyle effectiveIndicatorTextStyle =
        widget.valueIndicatorTextStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        );
    final TextStyle effectiveThumbValueTextStyle = effectiveIndicatorTextStyle.copyWith(
      color: Colors.black87,
      fontSize: (effectiveIndicatorTextStyle.fontSize ?? 11).clamp(5, 8.0),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double totalWidth = constraints.maxWidth;
        final double currentValue = widget.min + _rawRatio * (widget.max - widget.min);
        final String valueText = widget.labelFormatter != null ? widget.labelFormatter!(currentValue) : currentValue.toStringAsFixed(0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: totalWidth,
              height: widget.trackHeight,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (DragStartDetails d) {
                    _onDrag(d.localPosition.dx, totalWidth);
                  },
                  onHorizontalDragUpdate: (DragUpdateDetails d) => _onDrag(d.localPosition.dx, totalWidth),
                  onHorizontalDragEnd: (_) => _onDragEnd(),
                  onTapDown: (TapDownDetails d) {
                    _onDrag(d.localPosition.dx, totalWidth);
                    _onDragEnd();
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: widget.trackHeight,
                        child: CustomPaint(
                          painter: _SliderPainter(
                            min: widget.min,
                            max: widget.max,
                            rawRatio: _rawRatio,
                            stops: _stops,
                            trackHeight: widget.trackHeight,
                            trackBorderRadius: widget.trackBorderRadius ?? widget.trackHeight / 2,
                            trackBackgroundColor: widget.trackBackgroundColor,
                            trackFillColor: widget.trackFillColor,
                            innerPadding: _effectivePadding,
                            thumbDiameter: widget.thumbDiameter,
                            thumbColor: widget.thumbColor,
                            thumbElevation: widget.thumbElevation,
                            thumbShadowColor: widget.thumbShadowColor,
                            tickHeight: widget.tickHeight,
                            tickWidth: widget.tickWidth,
                            tickColorActive: widget.tickColorActive,
                            tickColorInactive: widget.tickColorInactive,
                            showEdgeTicks: widget.showEdgeTicks,
                            thumbValueText: valueText,
                            thumbValueTextStyle: effectiveThumbValueTextStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.showLabels) ...<Widget>[
              SizedBox(height: widget.labelSpacing),
              SizedBox(
                width: totalWidth,
                child: _LabelsRow(
                  stops: _stops,
                  innerPadding: _effectivePadding,
                  labelStyle: effectiveLabelStyle,
                  labelFormatter: widget.labelFormatter ?? (double v) => v.toInt().toString(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter
// ─────────────────────────────────────────────────────────────────────────────

class _SliderPainter extends CustomPainter {
  final double min, max;

  /// Continuous 0→1 ratio — drives smooth thumb X (not snapped).
  final double rawRatio;

  final List<double> stops;
  final double trackHeight, trackBorderRadius;
  final Color trackBackgroundColor, trackFillColor;

  /// Left/right inset so thumb never overflows track edges.
  final double innerPadding;

  final double thumbDiameter, thumbElevation;
  final Color thumbColor, thumbShadowColor;
  final String thumbValueText;
  final TextStyle thumbValueTextStyle;
  final double tickHeight, tickWidth;
  final Color tickColorActive, tickColorInactive;
  final bool showEdgeTicks;

  _SliderPainter({
    required this.min,
    required this.max,
    required this.rawRatio,
    required this.stops,
    required this.trackHeight,
    required this.trackBorderRadius,
    required this.trackBackgroundColor,
    required this.trackFillColor,
    required this.innerPadding,
    required this.thumbDiameter,
    required this.thumbElevation,
    required this.thumbColor,
    required this.thumbShadowColor,
    required this.thumbValueText,
    required this.thumbValueTextStyle,
    required this.tickHeight,
    required this.tickWidth,
    required this.tickColorActive,
    required this.tickColorInactive,
    required this.showEdgeTicks,
  });

  double _stopRatio(double stop) => (stop - min) / (max - min);

  @override
  void paint(Canvas canvas, Size size) {
    final double trackCY = size.height / 2;
    final double trackTop = trackCY - trackHeight / 2;
    final double trackBottom = trackCY + trackHeight / 2;
    final Radius rr = Radius.circular(trackBorderRadius);

    // Full background track pill
    final Rect bgRect = Rect.fromLTRB(0, trackTop, size.width, trackBottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, rr),
      Paint()..color = trackBackgroundColor,
    );

    // Usable travel range for thumb center
    final double usable = size.width - innerPadding * 2;

    // Thumb center follows rawRatio continuously
    final double thumbCX = innerPadding + rawRatio * usable;

    // Filled region extends slightly beyond the thumb edge so the knob feels
    // visually embedded inside the green segment.
    final double thumbR = thumbDiameter / 2;
    final double activeCapRadius = thumbR + 4;
    final double fillRight = (thumbCX + activeCapRadius).clamp(0.0, size.width);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(bgRect, rr));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(0, trackTop, fillRight, trackBottom),
        topLeft: rr,
        bottomLeft: rr,
        topRight: rr,
        bottomRight: rr,
      ),
      Paint()..color = trackFillColor,
    );
    canvas.restore();

    // Extra cap keeps the thumb fully inside green, not touching/exceeding the edge.
    canvas.drawCircle(
      Offset(thumbCX, trackCY),
      activeCapRadius,
      Paint()..color = trackFillColor,
    );

    // ── Tick marks ──────────────────────────────────────────────────────────
    final Paint tickPaint = Paint()..strokeWidth = tickWidth;
    for (final double stop in stops) {
      final bool isEdge = stop == min || stop == max;
      if (isEdge && !showEdgeTicks) continue;

      final double tx = innerPadding + _stopRatio(stop) * usable;
      // A tick is "active" when the thumb center has passed it
      tickPaint.color = (tx <= thumbCX + 0.5) ? tickColorActive : tickColorInactive;

      canvas.drawLine(
        Offset(tx, trackCY - tickHeight / 2),
        Offset(tx, trackCY + tickHeight / 2),
        tickPaint,
      );
    }

    // ── Thumb shadow ────────────────────────────────────────────────────────
    if (thumbElevation > 0) {
      canvas.drawShadow(
        Path()..addOval(Rect.fromCircle(center: Offset(thumbCX, trackCY), radius: thumbR)),
        thumbShadowColor,
        thumbElevation,
        false,
      );
    }

    // ── Thumb ───────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(thumbCX, trackCY),
      thumbR,
      Paint()..color = thumbColor,
    );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: thumbValueText, style: thumbValueTextStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: thumbDiameter - 6);
    textPainter.paint(
      canvas,
      Offset(thumbCX - textPainter.width / 2, trackCY - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.rawRatio != rawRatio || old.trackFillColor != trackFillColor || old.trackBackgroundColor != trackBackgroundColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Labels row
// ─────────────────────────────────────────────────────────────────────────────

class _LabelsRow extends StatelessWidget {
  final List<double> stops;
  final double innerPadding;
  final TextStyle labelStyle;
  final String Function(double) labelFormatter;

  const _LabelsRow({
    required this.stops,
    required this.innerPadding,
    required this.labelStyle,
    required this.labelFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final double totalWidth = constraints.maxWidth;
        final double usable = totalWidth - innerPadding * 2;
        final double minVal = stops.first;
        final double maxVal = stops.last;
        final double rowHeight = ((labelStyle.fontSize ?? 11) * 1.5).clamp(14.0, 26.0);

        return SizedBox(
          height: rowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children:
                stops.map((double stop) {
                  final double ratio = (stop - minVal) / (maxVal - minVal);
                  final double cx = innerPadding + ratio * usable;
                  return Positioned(
                    left: cx,
                    top: 0,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text(labelFormatter(stop), style: labelStyle),
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Haptic feedback type enum
// ─────────────────────────────────────────────────────────────────────────────

enum HapticFeedbackType {
  /// Light tap — best for dense sliders with many stops.
  light,

  /// Medium impact.
  medium,

  /// Heavy bump.
  heavy,

  /// Selection click — mimics a mechanical detent. Recommended default.
  selection,

  /// Full device vibration.
  vibrate,
}
