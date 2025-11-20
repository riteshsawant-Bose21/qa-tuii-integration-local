import 'package:flutter/material.dart';

import '../../widgets/pb_meter.dart';
import '../../widgets/pb_slider.dart';

class SliderAndMeterWidget extends StatelessWidget {
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;
  final ValueChanged<num>? onSliderChanged;

  const SliderAndMeterWidget({
    super.key,
    this.onSliderChanged,
    this.sliderValue = 0.0,
    this.sliderMin = 0.0,
    this.sliderMax = 0.0,
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
