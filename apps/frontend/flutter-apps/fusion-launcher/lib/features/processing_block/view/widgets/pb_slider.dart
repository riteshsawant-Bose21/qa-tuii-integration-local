import 'package:flutter/material.dart';

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
            value: handler?.getValue(item.field) ?? 100,
            min: data.min,
            max: data.max,
            showIntervals: showIntervals,
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
    this.activeColor = const Color(0xFF303030),
    this.inactiveColor = const Color(0xFFBABABA),
    this.thumbColor = Colors.black,
    this.thumbInnerColor = Colors.white,
    this.trackWidth = 4.0,
    this.thumbSize = 16.0,
    this.intervalSpacing = 50.0,
    this.intervalTickWidth = 10.0,
  });

  final num value;
  final num min;
  final num max;
  final ValueChanged<num>? onChanged;
  final bool showIntervals;

  // Styling
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final Color thumbInnerColor;
  final double trackWidth;
  final double thumbSize;
  final double intervalSpacing;
  final double intervalTickWidth;

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
                              spacing: 5,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  v.round().toString(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: widget.inactiveColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 8,
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  width: widget.intervalTickWidth,
                                  decoration: BoxDecoration(
                                    color: widget.inactiveColor,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(),
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
                                    color: widget.inactiveColor,
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
                                    color: widget.activeColor,
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
                              decoration: BoxDecoration(
                                color: widget.thumbColor,
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
                                  height: widget.thumbSize / 2,
                                  width: widget.thumbSize / 2,
                                  decoration: BoxDecoration(
                                    color: widget.thumbInnerColor,
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
