import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_vertical_meter.dart';

class SourceMeter extends StatelessWidget {
  final String? sourceId;
  const SourceMeter({super.key, this.sourceId});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 4,
      height: 16,
      child: VerticalMeter(
        showIntervals: false,
        meterWidth: 4,
        semanticId: 'out_meter_vertical_meter',
        value: -0,
        min: -60,
        max: 0,
      ),
    );
  }
}
