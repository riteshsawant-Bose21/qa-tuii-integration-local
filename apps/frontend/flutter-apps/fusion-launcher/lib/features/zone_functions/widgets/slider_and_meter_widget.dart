import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_vertical_slider.dart';

import '../../processing_block/view/widgets/pb_meter.dart';

class SliderAndMeterWidget extends StatelessWidget {
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;
  final ValueChanged<num>? onSliderChanged;

  const SliderAndMeterWidget({
    super.key,
    this.onSliderChanged,
    this.sliderValue = 0.0,
    this.sliderMin = -60.0,
    this.sliderMax = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          VerticalSlider(
            onChanged: onSliderChanged,
            value: sliderValue,
            min: sliderMin,
            max: sliderMax,
            intervalGap: 6,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: VerticalMeter(
              value: 0,
              min: -60,
              max: 12,
              intervalGap: 6,
              showIntervals: true,
            ),
          ),
        ],
      ),
    );
  }
}
