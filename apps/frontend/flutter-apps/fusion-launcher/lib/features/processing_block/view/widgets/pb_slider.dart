import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../functions/widgets.dart';

class PBSlider extends StatelessWidget {
  const PBSlider({
    super.key,
    required this.item,
    this.showIntervals = true,
    this.onChanged,
  });

  final PBItem item;
  final bool showIntervals;
  final ValueChanged<num>? onChanged;

  @override
  Widget build(BuildContext context) {
    final PBSliderParam data = item.param as PBSliderParam;

    return VerticalSlider(
      value: 100,
      min: data.min,
      max: data.max,
      showIntervals: showIntervals,
      onChanged: onChanged,
    );
  }
}
