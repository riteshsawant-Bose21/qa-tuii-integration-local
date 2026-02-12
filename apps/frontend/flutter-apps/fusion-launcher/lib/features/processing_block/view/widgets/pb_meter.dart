import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBMeter extends StatelessWidget {
  const PBMeter({
    super.key,
    required this.item,
    this.showIntervals = true,
    this.handler,
  });

  final PBItem item;
  final bool showIntervals;
  final PBWidgetValueHandler? handler;

  @override
  Widget build(BuildContext context) {
    final PBMeterParam data = (handler?.resolveForItem(item) ?? item.param) as PBMeterParam;

    return VerticalMeter(
      value: handler?.getValue(item) ?? item.value ?? 40,
      min: data.min,
      max: data.max,
      showIntervals: showIntervals,
    );
  }
}

// Vertical meter with intervals
class VerticalMeter extends StatelessWidget {
  const VerticalMeter({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.showIntervals = true,
    this.meterWidth = 4.0,
    this.inactiveColor,
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
  final double meterWidth;
  final Color? inactiveColor;
  final double intervalSpacing;
  final double intervalTickWidth;
  final num? intervalGap;
  final Duration animationDuration;

  static const double _borderRadius = 100;

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
        final double height = constraints.maxHeight;
        final double normalized = _toNormalized(value);
        final double activeHeight = normalized * height;
        final List<num> intervals = showIntervals ? _generateIntervals(height) : <num>[];

        return Center(
          child: IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Meter area with gradient and overlay
                SizedBox(
                  width: meterWidth,
                  height: height,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_borderRadius),
                      bottom: Radius.circular(_borderRadius),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        // Gradient background (no internal borderRadius)
                        Container(
                          width: meterWidth,
                          height: height,
                          decoration: const BoxDecoration(
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

                        // Grey inactive overlay (clipped by parent)
                        Align(
                          alignment: Alignment.topCenter,
                          child: AnimatedContainer(
                            duration: animationDuration,
                            curve: Curves.easeOut,
                            width: meterWidth,
                            height: height - activeHeight,
                            decoration: BoxDecoration(
                              color: inactiveColor ?? context.colorScheme.elevation5,
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
                    padding: const EdgeInsets.only(left: 4),
                    child: SizedBox(
                      height: height,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ...intervals.map((num v) {
                            return Row(
                              spacing: 2,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  height: 2,
                                  width: intervalTickWidth,
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.textPrimary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                FusionAppText(
                                  text: v.round().toString(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: context.colorScheme.textPrimary,
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
        );
      },
    );
  }
}

// class VerticalGradientMeter extends StatefulWidget {
//   const VerticalGradientMeter({
//     super.key,
//     required this.value,
//     required this.onChanged,
//     this.min = -60,
//     this.max = 12,

//     this.width = 4,
//     this.knobSize = 24,

//     this.intervalGap,
//     this.intervalSpacing = 50,

//     this.animationDuration = const Duration(milliseconds: 120),
//   });

//   final double value;
//   final double min;
//   final double max;

//   final double width;
//   final double knobSize;

//   final double? intervalGap;
//   final double intervalSpacing;

//   final Duration animationDuration;

//   final ValueChanged<double> onChanged;

//   @override
//   State<VerticalGradientMeter> createState() => _VerticalGradientMeterState();
// }

// class _VerticalGradientMeterState extends State<VerticalGradientMeter> {
//   double _normalize(double v) => ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

//   double _denormalize(double n) => widget.min + (n * (widget.max - widget.min));

//   List<double> _generateIntervals(double height) {
//     if (widget.intervalGap != null) {
//       final int count = ((widget.max - widget.min) / widget.intervalGap!).floor() + 1;

//       return List<double>.generate(
//         count,
//         (int i) => widget.max - (i * widget.intervalGap!),
//       ).where((double e) => e >= widget.min).toList();
//     }

//     final int tickCount = (height / widget.intervalSpacing).floor().clamp(3, 10);
//     final double step = (widget.max - widget.min) / (tickCount - 1);

//     return List<double>.generate(
//       tickCount,
//       (int i) => widget.max - (i * step),
//     );
//   }

//   void _handleDrag(Offset localPosition, double height) {
//     final double dy = localPosition.dy.clamp(0.0, height);

//     // invert because 0 is top
//     final double normalized = 1 - (dy / height);
//     final double value = _denormalize(normalized);

//     widget.onChanged(value);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (BuildContext context, BoxConstraints c) {
//         final double h = c.maxHeight;
//         final double normalized = _normalize(widget.value);
//         final double knobY = normalized * h;
//         final List<double> intervals = _generateIntervals(h);

//         return Row(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: <Widget>[
//             /// SCALE
//             SizedBox(
//               width: 40,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: <Widget>[
//                   ...intervals.map(
//                     (double v) => Text(
//                       v.round().toString(),
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 10,
//                       ),
//                     ),
//                   ),
//                   // const Text(
//                   //   'inf',
//                   //   style: TextStyle(color: Colors.white70, fontSize: 10),
//                   // ),
//                 ],
//               ),
//             ),

//             const SizedBox(width: 6),

//             /// INTERACTIVE BAR
//             GestureDetector(
//               behavior: HitTestBehavior.translucent,
//               onVerticalDragStart: (DragStartDetails details) => _handleDrag(details.localPosition, h),
//               onVerticalDragUpdate: (DragUpdateDetails details) => _handleDrag(details.localPosition, h),
//               onTapDown: (TapDownDetails details) => _handleDrag(details.localPosition, h),
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 alignment: Alignment.bottomCenter,
//                 children: <Widget>[
//                   /// Gradient bar
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(100),
//                     child: SizedBox(
//                       width: widget.width,
//                       height: h,
//                       child: const DecoratedBox(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                             colors: <Color>[
//                               Colors.red,
//                               Colors.orange,
//                               Colors.yellow,
//                               Colors.green,
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   /// Knob
//                   AnimatedPositioned(
//                     duration: widget.animationDuration,
//                     curve: Curves.easeOut,
//                     bottom: knobY - widget.knobSize / 2,
//                     child: Container(
//                       width: widget.knobSize,
//                       height: widget.knobSize,
//                       padding: const EdgeInsets.all(2),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                         border: Border.all(
//                           color: Colors.black,
//                           width: 4,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

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
  });

  final double value;
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
    return LayoutBuilder(
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
                children:
                    intervals
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
                      alignment: isBottomToTop ? Alignment.bottomCenter : Alignment.topCenter,
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
    );
  }
}
