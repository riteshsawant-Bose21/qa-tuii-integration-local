import 'dart:developer';

import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';

class PBSlider extends StatelessWidget {
  const PBSlider({
    super.key,
    required this.item,
    this.showIntervals = true,
  });

  final PBItem item;
  final bool showIntervals;

  @override
  Widget build(BuildContext context) {
    final PBSliderParam data = item.param as PBSliderParam;

    final ValueNotifier<num> valueListenable = ValueNotifier<num>(0.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          children: <Widget>[
            Text(
              data.label,
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder<num>(
                valueListenable: valueListenable,
                builder: (BuildContext context, num value, Widget? child) {
                  return _Slider(
                    value: value,
                    min: data.min,
                    max: 20,
                    showIntervals: showIntervals,
                    onChanged: (num value) {
                      log(value.toString());
                      valueListenable.value = value;
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<num>(
              valueListenable: valueListenable,
              builder: (BuildContext context, num value, Widget? child) {
                return Text("${value.round()}");
              },
            ),
          ],
        );
      },
    );
  }
}

class _Slider extends StatefulWidget {
  final num value;
  final num max;
  final num min;
  final ValueChanged<num> onChanged;
  final bool showIntervals;

  const _Slider({
    required this.max,
    required this.min,
    required this.value,
    required this.onChanged,
    this.showIntervals = true,
  });

  @override
  State<_Slider> createState() => __SliderState();
}

class __SliderState extends State<_Slider> {
  static const Color _activeColor = Color(0xFF303030);
  static const Color _inactiveColor = Color(0xFFBABABA);

  late num _dragStartValue;
  num _dragStartDy = 0.0;

  double _toNormalized(num value) => (value - widget.min) / (widget.max - widget.min);
  num _fromNormalized(num normalized) => widget.min + normalized * (widget.max - widget.min);

  void _onPanStart(DragStartDetails details, num height) {
    _dragStartValue = widget.value;
    _dragStartDy = details.localPosition.dy;
  }

  void _onPanUpdate(DragUpdateDetails details, num height) {
    final num delta = _dragStartDy - details.localPosition.dy;
    final num deltaNormalized = delta / height;
    final num startNormalized = _toNormalized(_dragStartValue);
    final num newNormalized = (startNormalized + deltaNormalized).clamp(0.0, 1.0);
    final num newValue = _fromNormalized(newNormalized);
    widget.onChanged(num.parse(newValue.toStringAsFixed(2)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final num height = constraints.maxHeight;
        final double thumbSize = (constraints.maxWidth * 0.2).clamp(26, 28);

        // 🔹 Determine tick count dynamically based on height
        final num desiredSpacing = 50; // px between ticks
        final int tickCount = ((height / desiredSpacing).floor()).clamp(3, 12);

        final double normalizedValue = _toNormalized(widget.value);
        final double thumbBottom = normalizedValue * (height - thumbSize);

        final num activeHeight = thumbBottom + (thumbSize / 2);
        final num inactiveHeight = height - activeHeight;

        const double trackMargin = 6;
        const double trackWidth = 8;

        // 🔹 Generate intervals dynamically
        final List<num> intervals = List<num>.generate(
          tickCount,
          (int i) => widget.max - i * ((widget.max - widget.min) / (tickCount - 1)),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: trackMargin),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    if (widget.showIntervals) ...<Widget>[
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(right: (constraints.maxWidth * 0.5).clamp(40, 50)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              ...intervals.map((num v) {
                                return Row(
                                  spacing: 5,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      v.round().toString(),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _inactiveColor),
                                    ),
                                    Container(
                                      height: 2,
                                      width: 10,
                                      decoration: const BoxDecoration(color: _inactiveColor),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],

                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Inactive (top)
                          Container(
                            width: trackWidth,
                            height: inactiveHeight - trackMargin,
                            decoration: const BoxDecoration(
                              color: _inactiveColor,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(100),
                              ),
                            ),
                          ),
                          // Active (bottom)
                          Container(
                            width: trackWidth,
                            height: activeHeight - trackMargin,
                            decoration: const BoxDecoration(
                              color: _activeColor,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Thumb
            Positioned(
              left: 0,
              right: 0,
              bottom: thumbBottom,
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onPanStart: (DragStartDetails details) => _onPanStart(details, height),
                onPanUpdate: (DragUpdateDetails details) => _onPanUpdate(details, height),
                child: Container(
                  height: thumbSize,
                  width: thumbSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    height: thumbSize / 2,
                    width: thumbSize / 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
