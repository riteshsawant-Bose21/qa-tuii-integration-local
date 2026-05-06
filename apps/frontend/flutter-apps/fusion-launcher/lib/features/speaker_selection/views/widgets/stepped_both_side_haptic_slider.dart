import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import 'stepped_haptic_slider.dart';

/// A highly customizable stepped horizontal range slider with haptic feedback at each stop.
///
/// - Left and right thumbs drag **smoothly**.
/// - Haptic feedback fires when the active thumb crosses a stop line.
/// - Both thumbs stay fully contained inside the track.
/// - Active fill is rendered between selected min and max values.
///
/// Example:
/// ```dart
/// SteppedBothSideHapticSlider(
///   min: 50,
///   max: 100,
///   interval: 10,
///   initialStartValue: 60,
///   initialEndValue: 90,
///   onRangeChanged: (values) => print(values),
/// )
/// ```
class SteppedBothSideHapticSlider extends StatefulWidget {
  /// Minimum value of the slider.
  final double min;

  /// Maximum value of the slider.
  final double max;

  /// Interval between each stop/tick mark. Must divide (max - min) evenly.
  final double interval;

  /// Initial start value of the range.
  final double initialStartValue;

  /// Initial end value of the range.
  final double initialEndValue;

  /// Callback fired whenever the selected range changes.
  final ValueChanged<RangeValues>? onRangeChanged;

  /// Callback fired when the user lifts their finger.
  final ValueChanged<RangeValues>? onRangeChangeEnd;

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
  /// Defaults to [thumbDiameter] / 2 + 6 for a cleaner edge gap at min/max.
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

  /// Optional classification bands shown above the track.
  final List<SliderTopBand> topBands;

  /// Text style for top band labels.
  final TextStyle? topBandLabelStyle;

  /// Spacing between top band labels and the slider track.
  final double topBandSpacing;

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

  const SteppedBothSideHapticSlider({
    super.key,
    required this.min,
    required this.max,
    required this.interval,
    required this.initialStartValue,
    required this.initialEndValue,
    this.onRangeChanged,
    this.onRangeChangeEnd,
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
    this.topBands = const <SliderTopBand>[],
    this.topBandLabelStyle,
    this.topBandSpacing = 10,
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
       ),
       assert(
         initialStartValue <= initialEndValue,
         'initialStartValue must be <= initialEndValue',
       );

  @override
  State<SteppedBothSideHapticSlider> createState() => _SteppedBothSideHapticSliderState();
}

class _SteppedBothSideHapticSliderState extends State<SteppedBothSideHapticSlider> {
  /// Raw (unsnapped) 0→1 ratios that drive smooth thumb movement while dragging.
  late double _startRawRatio;
  late double _endRawRatio;

  /// Whether user is actively dragging a thumb.
  bool _isDragging = false;

  _ActiveThumb _activeThumb = _ActiveThumb.start;

  /// Last interval index crossed by each thumb center (used for haptic trigger).
  late int _lastCrossedStartStepIndex;
  late int _lastCrossedEndStepIndex;

  double get _effectivePadding => widget.trackInnerPadding ?? (widget.thumbDiameter / 2 + 6);

  @override
  void initState() {
    super.initState();
    final double clampedStart = widget.initialStartValue.clamp(widget.min, widget.max);
    final double clampedEnd = widget.initialEndValue.clamp(widget.min, widget.max);
    final double normalizedStart = clampedStart <= clampedEnd ? clampedStart : clampedEnd;
    final double normalizedEnd = clampedEnd >= clampedStart ? clampedEnd : clampedStart;

    _startRawRatio = ((normalizedStart - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    _endRawRatio = ((normalizedEnd - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    _lastCrossedStartStepIndex = _stepIndexForValue(normalizedStart);
    _lastCrossedEndStepIndex = _stepIndexForValue(normalizedEnd);
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

  double _snapValueToStepWindow(double rawValue) {
    final double nearestStop = _nearestStop(rawValue);
    final double snapWindow = widget.interval * widget.stepSnapWindowFactor;
    final bool shouldSnapToStep = (rawValue - nearestStop).abs() <= snapWindow;

    return shouldSnapToStep ? nearestStop : rawValue;
  }

  _ActiveThumb _thumbForDx(double localDx, double totalWidth) {
    final double usable = totalWidth - _effectivePadding * 2;
    final double startCx = _effectivePadding + _startRawRatio * usable;
    final double endCx = _effectivePadding + _endRawRatio * usable;
    final double distToStart = (localDx - startCx).abs();
    final double distToEnd = (localDx - endCx).abs();

    if (distToStart == distToEnd) {
      final double mid = (startCx + endCx) / 2;
      return localDx <= mid ? _ActiveThumb.start : _ActiveThumb.end;
    }
    return distToStart < distToEnd ? _ActiveThumb.start : _ActiveThumb.end;
  }

  void _onDragStart(double localDx, double totalWidth) {
    setState(() {
      _isDragging = true;
      _activeThumb = _thumbForDx(localDx, totalWidth);
    });
    _onDrag(localDx, totalWidth);
  }

  void _onDrag(double localDx, double totalWidth) {
    final double rawRatio = _dxToRatio(localDx, totalWidth);
    final double rawValue = widget.min + rawRatio * (widget.max - widget.min);
    final double snappedValue = _snapValueToStepWindow(rawValue);

    if (_activeThumb == _ActiveThumb.start) {
      final double endValue = widget.min + _endRawRatio * (widget.max - widget.min);
      final double clampedStartValue = snappedValue.clamp(widget.min, endValue);
      final double startRatio = ((clampedStartValue - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
      final int crossedStepIndex = _stepIndexForValue(clampedStartValue);

      setState(() => _startRawRatio = startRatio);

      if (crossedStepIndex != _lastCrossedStartStepIndex) {
        _lastCrossedStartStepIndex = crossedStepIndex;
        _triggerHaptic();
      }
    } else {
      final double startValue = widget.min + _startRawRatio * (widget.max - widget.min);
      final double clampedEndValue = snappedValue.clamp(startValue, widget.max);
      final double endRatio = ((clampedEndValue - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
      final int crossedStepIndex = _stepIndexForValue(clampedEndValue);

      setState(() => _endRawRatio = endRatio);

      if (crossedStepIndex != _lastCrossedEndStepIndex) {
        _lastCrossedEndStepIndex = crossedStepIndex;
        _triggerHaptic();
      }
    }

    widget.onRangeChanged?.call(
      RangeValues(
        widget.min + _startRawRatio * (widget.max - widget.min),
        widget.min + _endRawRatio * (widget.max - widget.min),
      ),
    );
  }

  void _onDragEnd() {
    setState(() => _isDragging = false);
    widget.onRangeChangeEnd?.call(
      RangeValues(
        widget.min + _startRawRatio * (widget.max - widget.min),
        widget.min + _endRawRatio * (widget.max - widget.min),
      ),
    );
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
    final TextStyle effectiveTopBandStyle =
        widget.topBandLabelStyle ?? context.textTheme.l3Caps.copyWith(color: context.colorScheme.textBody, fontSize: 6, letterSpacing: 0);

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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double totalWidth = constraints.maxWidth;
        final double usable = totalWidth - _effectivePadding * 2;
        final double startThumbCx = _effectivePadding + _startRawRatio * usable;
        final double endThumbCx = _effectivePadding + _endRawRatio * usable;
        final double activeValue =
            _activeThumb == _ActiveThumb.start
                ? widget.min + _startRawRatio * (widget.max - widget.min)
                : widget.min + _endRawRatio * (widget.max - widget.min);
        final double activeThumbCx = _activeThumb == _ActiveThumb.start ? startThumbCx : endThumbCx;
        final String valueText = widget.labelFormatter != null ? widget.labelFormatter!(activeValue) : activeValue.toStringAsFixed(0);
        final bool showIndicator = widget.showValueIndicatorOnDrag && _isDragging;
        final double indicatorHeight = showIndicator ? 28 : 0;
        final double indicatorAreaHeight = showIndicator ? (indicatorHeight + widget.valueIndicatorBottomSpacing) : 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.topBands.isNotEmpty) ...<Widget>[
              SizedBox(
                width: totalWidth,
                child: _TopBandsRow(
                  min: widget.min,
                  max: widget.max,
                  bands: widget.topBands,
                  innerPadding: _effectivePadding,
                  labelStyle: effectiveTopBandStyle,
                ),
              ),
              SizedBox(height: widget.topBandSpacing),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: totalWidth,
              height: widget.trackHeight + indicatorAreaHeight,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (DragStartDetails d) => _onDragStart(d.localPosition.dx, totalWidth),
                  onHorizontalDragUpdate: (DragUpdateDetails d) => _onDrag(d.localPosition.dx, totalWidth),
                  onHorizontalDragEnd: (_) => _onDragEnd(),
                  onTapDown: (TapDownDetails d) {
                    _activeThumb = _thumbForDx(d.localPosition.dx, totalWidth);
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
                            startRawRatio: _startRawRatio,
                            endRawRatio: _endRawRatio,
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
                          ),
                        ),
                      ),
                      if (showIndicator)
                        Positioned(
                          left: activeThumbCx,
                          bottom: widget.trackHeight + widget.valueIndicatorBottomSpacing,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, 0),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOut,
                              opacity: showIndicator ? 1 : 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: widget.valueIndicatorBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: widget.valueIndicatorPadding,
                                  child: Text(valueText, style: effectiveIndicatorTextStyle),
                                ),
                              ),
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

  /// Continuous 0→1 ratios — drive smooth thumb X positions.
  final double startRawRatio;
  final double endRawRatio;

  final List<double> stops;
  final double trackHeight, trackBorderRadius;
  final Color trackBackgroundColor, trackFillColor;

  /// Left/right inset so thumb never overflows track edges.
  final double innerPadding;

  final double thumbDiameter, thumbElevation;
  final Color thumbColor, thumbShadowColor;
  final double tickHeight, tickWidth;
  final Color tickColorActive, tickColorInactive;
  final bool showEdgeTicks;

  _SliderPainter({
    required this.min,
    required this.max,
    required this.startRawRatio,
    required this.endRawRatio,
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

    // Thumb centers follow raw ratios continuously
    final double startThumbCX = innerPadding + startRawRatio * usable;
    final double endThumbCX = innerPadding + endRawRatio * usable;

    final double thumbR = thumbDiameter / 2;
    final double activeCapRadius = thumbR + 4;
    final double fillLeft = (startThumbCX - activeCapRadius).clamp(0.0, size.width);
    final double fillRight = (endThumbCX + activeCapRadius).clamp(0.0, size.width);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(bgRect, rr));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(fillLeft, trackTop, fillRight, trackBottom),
        topRight: rr,
        bottomRight: rr,
        topLeft: rr,
        bottomLeft: rr,
      ),
      Paint()..color = trackFillColor,
    );

    // Keep cap extensions clipped to the track so edge curvature stays clean.
    canvas.drawCircle(
      Offset(startThumbCX, trackCY),
      activeCapRadius,
      Paint()..color = trackFillColor,
    );
    canvas.drawCircle(
      Offset(endThumbCX, trackCY),
      activeCapRadius,
      Paint()..color = trackFillColor,
    );
    canvas.restore();

    // ── Tick marks ──────────────────────────────────────────────────────────
    final Paint tickPaint = Paint()..strokeWidth = tickWidth;
    for (final double stop in stops) {
      final bool isEdge = stop == min || stop == max;
      if (isEdge && !showEdgeTicks) continue;

      final double tx = innerPadding + _stopRatio(stop) * usable;
      final bool isActiveTick = tx >= fillLeft - 0.5 && tx <= fillRight + 0.5;
      tickPaint.color = isActiveTick ? tickColorActive : tickColorInactive;

      canvas.drawLine(
        Offset(tx, trackCY - tickHeight / 2),
        Offset(tx, trackCY + tickHeight / 2),
        tickPaint,
      );
    }

    // ── Thumb shadow ────────────────────────────────────────────────────────
    if (thumbElevation > 0) {
      canvas.drawShadow(
        Path()..addOval(Rect.fromCircle(center: Offset(startThumbCX, trackCY), radius: thumbR)),
        thumbShadowColor,
        thumbElevation,
        false,
      );
      canvas.drawShadow(
        Path()..addOval(Rect.fromCircle(center: Offset(endThumbCX, trackCY), radius: thumbR)),
        thumbShadowColor,
        thumbElevation,
        false,
      );
    }

    // ── Thumb ───────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(startThumbCX, trackCY),
      thumbR,
      Paint()..color = thumbColor,
    );
    canvas.drawCircle(
      Offset(endThumbCX, trackCY),
      thumbR,
      Paint()..color = thumbColor,
    );
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.startRawRatio != startRawRatio ||
      old.endRawRatio != endRawRatio ||
      old.trackFillColor != trackFillColor ||
      old.trackBackgroundColor != trackBackgroundColor;
}

enum _ActiveThumb {
  start,
  end,
}

class SliderTopBand {
  final String label;
  final double start;
  final double end;
  final String? description;

  const SliderTopBand({
    required this.label,
    required this.start,
    required this.end,
    this.description,
  }) : assert(start <= end, 'start must be <= end');
}

class _TopBandsRow extends StatelessWidget {
  final double min;
  final double max;
  final List<SliderTopBand> bands;
  final double innerPadding;
  final TextStyle labelStyle;

  const _TopBandsRow({
    required this.min,
    required this.max,
    required this.bands,
    required this.innerPadding,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final double totalWidth = constraints.maxWidth;
        final double usable = totalWidth - innerPadding * 2;
        final double rowHeight = ((labelStyle.fontSize ?? 9) * 1.9).clamp(16.0, 26.0);

        double xForValue(double value) {
          final double ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);
          return innerPadding + ratio * usable;
        }

        return SizedBox(
          height: rowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (int i = 0; i < bands.length; i++) ...<Widget>[
                Builder(
                  builder: (BuildContext context) {
                    final SliderTopBand band = bands[i];
                    final double start = band.start.clamp(min, max);
                    final double end = band.end.clamp(min, max);
                    if (end <= start) return const SizedBox.shrink();
                    final double cx = xForValue((start + end) / 2);

                    return Positioned(
                      left: cx,
                      top: 0,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: Tooltip(
                          waitDuration: const Duration(milliseconds: 250),
                          message: band.description ?? '${band.label}: ${start.toInt()}-${end.toInt()} dB SPL',
                          child: Text(
                            band.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: labelStyle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (i < bands.length - 1)
                  Builder(
                    builder: (BuildContext context) {
                      final double boundary = bands[i].end.clamp(min, max);
                      final double x = xForValue(boundary);
                      return Positioned(
                        left: x,
                        bottom: 0,
                        child: Container(
                          width: 1,
                          height: 9,
                          color: Colors.white.withOpacity(0.28),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
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
