import 'package:flutter/material.dart';

import '../semantics/semantic_helper.dart';
import '../semantics/semantic_type.dart';

class SimpleVerticalMeter extends StatelessWidget {
  const SimpleVerticalMeter({
    super.key,
    required this.value,
    this.min = -42,
    this.max = 0,

    this.width = 4,

    this.trackColor = const Color(0xFF6B6B6B),
    this.activeColor = const Color(0xFF2ECC71),

    this.intervalGap,
    this.intervalSpacing = 50,

    this.isBottomToTop = false,
    this.semanticId,
  });

  final double value;
  final String? semanticId;
  final double min;
  final double max;

  final double width;
  final Color trackColor;
  final Color activeColor;

  final double? intervalGap;
  final double intervalSpacing;

  /// NEW
  final bool isBottomToTop;

  double _normalize(double v) => ((v - min) / (max - min)).clamp(0.0, 1.0);

  List<double> _generateIntervals(double height) {
    if (intervalGap != null) {
      final int count = ((max - min) / intervalGap!).floor() + 1;

      return List<double>.generate(
        count,
        (int i) => max - (i * intervalGap!),
      ).where((double e) => e >= min).toList();
    }

    final int tickCount = (height / intervalSpacing).floor().clamp(3, 10);
    final double step = (max - min) / (tickCount - 1);

    return List<double>.generate(
      tickCount,
      (int i) => max - (i * step),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        'simple_vertical_meter${semanticId}',
      ),
      label: value.toString(),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double h = c.maxHeight;
          final double normalized = _normalize(value);
          final double activeHeight = normalized * h;
          final List<double> intervals = _generateIntervals(h);

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              /// SCALE
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: intervals
                      .map(
                        (double v) => Text(
                          v.round().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(width: 6),

              /// BAR
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: SizedBox(
                  width: width,
                  height: h,
                  child: Stack(
                    children: <Widget>[
                      /// TRACK
                      Container(color: trackColor),

                      /// ACTIVE PART (direction aware)
                      Align(
                        alignment: isBottomToTop
                            ? Alignment.bottomCenter
                            : Alignment.topCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          height: activeHeight,
                          color: activeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
