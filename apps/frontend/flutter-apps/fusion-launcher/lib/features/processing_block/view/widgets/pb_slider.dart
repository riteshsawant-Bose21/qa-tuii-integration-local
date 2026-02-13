import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../item_widget_builder.dart';

class PBSlider extends StatelessWidget {
  const PBSlider({
    super.key,
    required this.item,
    this.showIntervals = true,
    this.onChanged,
    this.handler,
  });

  final PBItem item;
  final bool showIntervals;
  final ValueChanged<num>? onChanged;
  final PBWidgetValueHandler? handler;

  @override
  Widget build(BuildContext context) {
    final PBSliderParam data = (handler?.resolveForItem(item) ?? item.param) as PBSliderParam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            data.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
        Expanded(
          child: VerticalSlider(
            value: handler?.getValue(item) ?? item.value ?? 10,
            min: data.min,
            max: data.max,
            showIntervals: showIntervals,
            activeColor: context.colorScheme.primary,
            onChanged:
                onChanged ??
                (num value) {
                  print("ON CHANGED: $value");
                  handler?.onValueChanged(item, value);
                },
          ),
        ),
      ],
    );
  }
}

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
    final double newNormalized = (startNormalized + deltaNormalized).clamp(0.0, 1.0);
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
    final int tickCount = ((height / widget.intervalSpacing).floor()).clamp(3, 12);
    final double step = (widget.max - widget.min) / (tickCount - 1);

    return List<num>.generate(
      tickCount,
      (int i) => widget.max - (i * step),
    );
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

        final List<num> intervals = widget.showIntervals ? _generateIntervals(height) : <num>[];

        return Center(
          child: IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Intervals (if enabled)
                if (widget.showIntervals)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: widget.thumbSize / 4),
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
                                    color: widget.activeColor ?? context.colorScheme.primaryColor,
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
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: _onPanStart,
                            onPanUpdate: (DragUpdateDetails details) => _onPanUpdate(details, height),
                            onPanEnd: _onPanEnd,
                            child: Container(
                              height: widget.thumbSize,
                              width: widget.thumbSize,
                              padding: EdgeInsets.all(widget.thumbSize * 0.2),
                              decoration: BoxDecoration(
                                color: context.colorScheme.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  height: widget.thumbSize,
                                  width: widget.thumbSize,
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.primaryWhite,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class VerticalRangeSelectionSlider extends StatefulWidget {
  const VerticalRangeSelectionSlider({
    super.key,
    required this.lowerValue,
    required this.upperValue,
    required this.min,
    required this.max,
    required this.onLowerChanged,
    required this.onUpperChanged,
    this.minGap = 1,
    this.showIntervals = true,
    this.trackWidth = 4,
    this.thumbSize = 16,
    this.intervalSpacing = 50,
    this.intervalTickWidth = 10,
    this.intervalGap,
  });

  final num lowerValue;
  final num upperValue;
  final num min;
  final num max;

  final ValueChanged<num> onLowerChanged;
  final ValueChanged<num> onUpperChanged;

  final num minGap;

  final bool showIntervals;
  final double trackWidth;
  final double thumbSize;
  final double intervalSpacing;
  final double intervalTickWidth;
  final num? intervalGap;

  @override
  State<VerticalRangeSelectionSlider> createState() => _VerticalRangeSelectionSliderState();
}

class _VerticalRangeSelectionSliderState extends State<VerticalRangeSelectionSlider> {
  num? _dragStartLower;
  num? _dragStartUpper;
  double _dragStartDy = 0;

  double _toNorm(num v) => ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  num _fromNorm(num n) => widget.min + n * (widget.max - widget.min);

  void _startLower(DragStartDetails d) {
    _dragStartLower = widget.lowerValue;
    _dragStartDy = d.localPosition.dy;
  }

  void _startUpper(DragStartDetails d) {
    _dragStartUpper = widget.upperValue;
    _dragStartDy = d.localPosition.dy;
  }

  void _updateLower(DragUpdateDetails d, double h) {
    if (_dragStartLower == null) return;

    final double range = h - widget.thumbSize;
    final double delta = _dragStartDy - d.localPosition.dy;

    final double startNorm = _toNorm(_dragStartLower!);
    final num nextNorm = (startNorm + delta / range).clamp(0, 1);

    final num next = _fromNorm(nextNorm).clamp(widget.min, widget.upperValue - widget.minGap);

    widget.onLowerChanged(next);
  }

  void _updateUpper(DragUpdateDetails d, double h) {
    if (_dragStartUpper == null) return;

    final double range = h - widget.thumbSize;
    final double delta = _dragStartDy - d.localPosition.dy;

    final double startNorm = _toNorm(_dragStartUpper!);
    final num nextNorm = (startNorm + delta / range).clamp(0, 1);

    final num next = _fromNorm(nextNorm).clamp(widget.lowerValue + widget.minGap, widget.max);

    widget.onUpperChanged(next);
  }

  void _end(_) {
    _dragStartLower = null;
    _dragStartUpper = null;
  }

  List<num> _intervals(double h) {
    if (widget.intervalGap != null) {
      final int count = ((widget.max - widget.min) / widget.intervalGap!).floor() + 1;

      return List<num>.generate(count, (int i) => widget.max - i * widget.intervalGap!);
    }

    final int ticks = ((h / widget.intervalSpacing).floor()).clamp(3, 12);
    final double step = (widget.max - widget.min) / (ticks - 1);

    return List<num>.generate(ticks, (int i) => widget.max - i * step);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints c) {
        final double h = c.maxHeight;

        final double half = widget.thumbSize / 2;
        final double range = h - widget.thumbSize;

        final double lowerNorm = _toNorm(widget.lowerValue);
        final double upperNorm = _toNorm(widget.upperValue);

        final double lowerCenter = half + lowerNorm * range;
        final double upperCenter = half + upperNorm * range;

        final List<num> ticks = widget.showIntervals ? _intervals(h) : <num>[];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.showIntervals)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  ...ticks.map(
                    (num v) => Row(
                      children: <Widget>[
                        Text(v.round().toString(), style: const TextStyle(fontSize: 8)),
                        Container(
                          width: widget.intervalTickWidth,
                          height: 2,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            SizedBox(
              width: widget.thumbSize,
              height: h,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: widget.trackWidth,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                  Positioned.fill(
                    bottom: lowerCenter,
                    top: h - upperCenter,
                    child: Center(
                      child: Container(
                        width: widget.trackWidth,
                        color: context.colorScheme.primaryColor,
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: lowerCenter - half,
                    left: 0,
                    right: 0,
                    child: _Thumb(
                      size: widget.thumbSize,
                      onStart: _startLower,
                      onUpdate: (DragUpdateDetails d) => _updateLower(d, h),
                      onEnd: _end,
                    ),
                  ),

                  Positioned(
                    bottom: upperCenter - half,
                    left: 0,
                    right: 0,
                    child: _Thumb(
                      size: widget.thumbSize,
                      onStart: _startUpper,
                      onUpdate: (DragUpdateDetails d) => _updateUpper(d, h),
                      onEnd: _end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
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
