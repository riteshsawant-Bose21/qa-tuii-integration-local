import 'package:flutter/material.dart' hide Thumb;
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
    final PBSliderParam data =
        (handler?.resolveForItem(item) ?? item.param) as PBSliderParam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            data.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
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
  State<VerticalRangeSelectionSlider> createState() =>
      _VerticalRangeSelectionSliderState();
}

class _VerticalRangeSelectionSliderState
    extends State<VerticalRangeSelectionSlider> {
  num? _dragStartLower;
  num? _dragStartUpper;
  double _dragStartDy = 0;

  double _toNorm(num v) =>
      ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

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

    final num next = _fromNorm(
      nextNorm,
    ).clamp(widget.min, widget.upperValue - widget.minGap);

    widget.onLowerChanged(next);
  }

  void _updateUpper(DragUpdateDetails d, double h) {
    if (_dragStartUpper == null) return;

    final double range = h - widget.thumbSize;
    final double delta = _dragStartDy - d.localPosition.dy;

    final double startNorm = _toNorm(_dragStartUpper!);
    final num nextNorm = (startNorm + delta / range).clamp(0, 1);

    final num next = _fromNorm(
      nextNorm,
    ).clamp(widget.lowerValue + widget.minGap, widget.max);

    widget.onUpperChanged(next);
  }

  void _end(_) {
    _dragStartLower = null;
    _dragStartUpper = null;
  }

  List<num> _intervals(double h) {
    if (widget.intervalGap != null) {
      final int count =
          ((widget.max - widget.min) / widget.intervalGap!).floor() + 1;

      return List<num>.generate(
        count,
        (int i) => widget.max - i * widget.intervalGap!,
      );
    }

    final int ticks = ((h / widget.intervalSpacing).floor()).clamp(3, 12);
    final double step = (widget.max - widget.min) / (ticks - 1);

    return List<num>.generate(ticks, (int i) => widget.max - i * step);
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.toggle,
        "PB_Slider",
      ),
      child: LayoutBuilder(
        builder: (_, BoxConstraints c) {
          final double h = c.maxHeight;

          final double half = widget.thumbSize / 2;
          final double range = h - widget.thumbSize;

          final double lowerNorm = _toNorm(widget.lowerValue);
          final double upperNorm = _toNorm(widget.upperValue);

          final double lowerCenter = half + lowerNorm * range;
          final double upperCenter = half + upperNorm * range;

          final List<num> ticks =
              widget.showIntervals ? _intervals(h) : <num>[];

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
                          Text(
                            v.round().toString(),
                            style: const TextStyle(fontSize: 8),
                          ),
                          Container(
                            width: widget.intervalTickWidth,
                            height: 2,
                            color: context.colorScheme.textPrimary,
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
                          color: context.colorScheme.strokeLight,
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
                      child: Thumb(
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
                      child: Thumb(
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
      ),
    );
  }
}
