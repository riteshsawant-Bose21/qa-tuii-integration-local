import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/neumorphic_button.dart';

class HorizontalMeter extends StatelessWidget {
  const HorizontalMeter({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.showIntervals = true,
    this.meterHeight = 4.0,
    this.inactiveColor = const Color(0xFFBABABA),
    this.intervalSpacing = 50.0,
    this.intervalTickWidth = 10.0,
    this.intervalGap,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  final num value;
  final num min;
  final num max;
  final bool showIntervals;

  // Styling
  final double meterHeight;
  final Color inactiveColor;
  final double intervalSpacing;
  final double intervalTickWidth;
  final num? intervalGap;
  final Duration animationDuration;

  static const double _borderRadius = 4;

  double _toNormalized(num value) {
    final num range = max - min;
    if (range == 0) return 0.0;
    return ((value - min) / range).clamp(0.0, 1.0).toDouble();
  }

  List<num> _generateIntervals(double height) {
    // If intervalGap is provided, use it to generate intervals
    if (intervalGap != null) {
      final num range = max - min;
      final int tickCount = (range / intervalGap!).floor() + 1;

      return List<num>.generate(
        tickCount,
            (int i) => max - (i * intervalGap!),
      ).where((num v) => v >= min && v <= max).toList();
    }

    // Otherwise, generate based on height
    final int tickCount = ((height / intervalSpacing).floor()).clamp(3, 12);
    final double step = (max - min) / (tickCount - 1);

    return List<num>.generate(
      tickCount,
          (int i) => max - (i * step),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double normalized = _toNormalized(value);
        final double activeWidth = normalized * width;
        final List<num> intervals = showIntervals ? _generateIntervals(width) : <num>[];

        return Container(
          child: Center(
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Meter area with gradient and overlay
                  Container(
                    width: width,
                    height: meterHeight,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_borderRadius),
                        bottom: Radius.circular(_borderRadius),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          // Gradient background (no internal borderRadius)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width:  width - activeWidth,
                              height: meterHeight,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  stops: [
                                    0.3,0.4,0.9,1.0
                                  ],
                                  colors: <Color>[
                                    Colors.green,
                                    Colors.yellow,
                                    Colors.orange,
                                    Colors.red,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Grey inactive overlay (clipped by parent)
                          Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedContainer(
                              duration: animationDuration,
                              curve: Curves.easeOut,
                              width: width-activeWidth,
                              height: meterHeight,
                              decoration: BoxDecoration(
                                color: inactiveColor,
                                // no need to set radius here — already clipped by parent
                              ),
                            ),
                          ),




                        ],
                      ),
                    ),
                  ),

                 // Intervals (if enabled) - positioned to the right
                  if (showIntervals)
                    Padding(
                      padding: const EdgeInsets.only(top: 4,left: 4),
                      child: SizedBox(
                        height: meterHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ...intervals.map((num v) {
                              return Column(
                                spacing: 2,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    height: intervalTickWidth,
                                    width: 1,
                                    decoration: BoxDecoration(
                                      color: inactiveColor,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  Text(
                                    v.round().toString(),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
