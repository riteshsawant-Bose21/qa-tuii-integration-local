import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../fusion_theme/app_theme.dart';
import '../text_views/fusion_app_text.dart';

class VerticalSlider extends StatefulWidget {
  const VerticalSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
    this.showIntervals = true,
    this.activeColor,
    this.inactiveColor,
    this.trackWidth = 4.0,
    this.thumbSize = 16.0,
    this.intervalSpacing = 50.0,
    this.intervalTickWidth = 10.0,
    this.intervalGap,
  });

  final num value;
  final num min;
  final num max;
  final ValueChanged<num>? onChanged;
  final bool showIntervals;

  // Styling
  final Color? activeColor;
  final Color? inactiveColor;
  final double trackWidth;
  final double thumbSize;
  final double intervalSpacing;
  final double intervalTickWidth;
  final num? intervalGap;

  @override
  State<VerticalSlider> createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  late num _currentValue;
  num? _dragStartValue;
  double _dragStartDy = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(VerticalSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _currentValue = widget.value.clamp(widget.min, widget.max);
    }
  }

  double _toNormalized(num value) {
    final num range = widget.max - widget.min;
    if (range == 0) return 0.0;
    return ((value - widget.min) / range).clamp(0.0, 1.0).toDouble();
  }

  num _fromNormalized(double normalized) {
    return widget.min + normalized * (widget.max - widget.min);
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartValue = _currentValue;
    _dragStartDy = details.localPosition.dy;
  }

  void _onPanUpdate(DragUpdateDetails details, double height) {
    if (_dragStartValue == null) return;

    final double trackRange = height - widget.thumbSize;
    final double delta = _dragStartDy - details.localPosition.dy;
    final double deltaNormalized = delta / trackRange;
    final double startNormalized = _toNormalized(_dragStartValue!);
    final double newNormalized = (startNormalized + deltaNormalized).clamp(
      0.0,
      1.0,
    );
    final num newValue = _fromNormalized(newNormalized);

    setState(() {
      _currentValue = num.parse(newValue.toStringAsFixed(2));
    });

    widget.onChanged?.call(_currentValue);
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStartValue = null;
  }

  List<num> _generateIntervals(double height) {
    // If intervalGap is provided, use it to generate intervals
    if (widget.intervalGap != null) {
      final num range = widget.max - widget.min;
      final int tickCount = (range / widget.intervalGap!).floor() + 1;

      return List<num>.generate(
        tickCount,
        (int i) => widget.max - (i * widget.intervalGap!),
      ).where((num v) => v >= widget.min && v <= widget.max).toList();
    }

    // Otherwise, generate based on height
    final int tickCount = ((height / widget.intervalSpacing).floor()).clamp(
      3,
      12,
    );
    final double step = (widget.max - widget.min) / (tickCount - 1);

    return List<num>.generate(
      tickCount,
      (int i) => widget.max - (i * step),
    );
  }

  void _jumpToPosition(double localDy, double height) {
    final double trackRange = height - widget.thumbSize;
    final double clampedDy = localDy.clamp(
      widget.thumbSize / 2,
      height - widget.thumbSize / 2,
    );

    final double normalized =
        1 - ((clampedDy - widget.thumbSize / 2) / trackRange);

    final num newValue = _fromNormalized(normalized);

    setState(() {
      _currentValue = num.parse(newValue.toStringAsFixed(2));
    });

    widget.onChanged?.call(_currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.maxHeight;
        final double normalizedValue = _toNormalized(_currentValue);

        // Thumb center travels from halfThumb to (height - halfThumb)
        // So it touches line ends perfectly
        final double halfThumb = widget.thumbSize / 2;
        final double trackHeight = height - widget.thumbSize;
        final double thumbCenter = halfThumb + (normalizedValue * trackHeight);
        final double thumbBottom = thumbCenter - halfThumb;

        // Track sections based on thumb center
        final double activeHeight = thumbCenter - (widget.thumbSize / 2);
        final double inactiveHeight = height - thumbCenter;

        final List<num> intervals = widget.showIntervals
            ? _generateIntervals(height)
            : <num>[];

        return Center(
          child: IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Intervals (if enabled)
                if (widget.showIntervals)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: widget.thumbSize / 4,
                    ),
                    child: SizedBox(
                      height: height,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          ...intervals.map((num v) {
                            return Row(
                              spacing: 2,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                FusionAppText(
                                  text: v.round().toString(),
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: context.colorScheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 8,
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  width: widget.intervalTickWidth,
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.textPrimary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                // Slider area with track and thumb
                SizedBox(
                  width: widget.thumbSize,
                  height: height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (TapDownDetails d) =>
                        _jumpToPosition(d.localPosition.dy, height),
                    onVerticalDragStart: (DragStartDetails d) =>
                        _jumpToPosition(d.localPosition.dy, height),
                    onVerticalDragUpdate: (DragUpdateDetails d) =>
                        _jumpToPosition(d.localPosition.dy, height),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        // Track - centered
                        Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width: widget.trackWidth,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  // Inactive (top)
                                  Container(
                                    width: widget.trackWidth,
                                    height: inactiveHeight,
                                    decoration: BoxDecoration(
                                      color: context.colorScheme.elevation5,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(100),
                                      ),
                                    ),
                                  ),
                                  // Active (bottom)
                                  Container(
                                    width: widget.trackWidth,
                                    height: activeHeight,
                                    decoration: BoxDecoration(
                                      color:
                                          widget.activeColor ??
                                          context.colorScheme.primaryColor,
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(100),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Thumb - centered horizontally
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: thumbBottom,
                          child: Center(
                            child: Thumb(
                              size: widget.thumbSize,
                              onStart: _onPanStart,
                              onUpdate: (DragUpdateDetails details) =>
                                  _onPanUpdate(details, height),
                              onEnd: _onPanEnd,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class Thumb extends StatelessWidget {
  const Thumb({
    required this.size,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final double size;
  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: onStart,
      onPanUpdate: onUpdate,
      onPanEnd: onEnd,
      child: Center(
        child: Container(
          height: size,
          width: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
