import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBMeter extends StatelessWidget {
  const PBMeter({
    super.key,
    required this.item,
    this.showIntervals = true,
    this.handler,
    this.semanticId,
  });

  final PBItem item;
  final bool showIntervals;
  final PBWidgetValueHandler? handler;
  final String? semanticId;

  @override
  Widget build(BuildContext context) {
    final PBMeterParam data = (handler?.resolveForItem(item) ?? item.param) as PBMeterParam;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "PBMeter_${semanticId ?? ''}",
      ),
      value: (handler?.getValue(item) ?? item.value ?? 40).toStringAsFixed(1),
      child: VerticalMeter(
        value: handler?.getValue(item) ?? item.value ?? 40,
        min: data.min,
        max: data.max,
        showIntervals: showIntervals,
      ),
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
    this.animationDuration = const Duration(milliseconds: 100),
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
