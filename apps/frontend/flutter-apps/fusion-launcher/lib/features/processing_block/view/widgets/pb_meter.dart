import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';

class PBMeter extends StatelessWidget {
  const PBMeter({super.key, required this.item});
  final PBItem item;

  @override
  Widget build(BuildContext context) {
    final PBMeterParam data = item.param as PBMeterParam;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return _Meter(
          min: data.min,
          max: data.max,
          value: 10,
        );
      },
    );
  }
}

class _Meter extends StatelessWidget {
  final num min;
  final num max;
  final num value;

  const _Meter({
    required this.min,
    required this.max,
    required this.value,
  });

  static const double _borderRadius = 100;
  static const Color _inactiveOverlayColor = Colors.grey;

  double _toNormalized(double value) {
    if (max == min) return 0.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.maxHeight;
        final double mw = constraints.maxWidth * 0.05;

        double meterWidth = mw > 10 ? 10 : mw;
        if (meterWidth < 6) meterWidth = 6;

        final double normalized = _toNormalized(value.toDouble());
        final double activeHeight = normalized * height;

        return Center(
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              // 1️⃣ Full gradient background (always visible)
              Container(
                width: meterWidth,
                height: height,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_borderRadius),
                    bottom: Radius.circular(_borderRadius),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                    ],
                  ),
                ),
              ),

              // 2️⃣ Grey inactive overlay (covers *above* the active section)
              Align(
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: meterWidth,
                  height: height - activeHeight,
                  decoration: BoxDecoration(
                    color: _inactiveOverlayColor,
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(_borderRadius),
                      bottom: value == 0 ? const Radius.circular(_borderRadius) : Radius.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
