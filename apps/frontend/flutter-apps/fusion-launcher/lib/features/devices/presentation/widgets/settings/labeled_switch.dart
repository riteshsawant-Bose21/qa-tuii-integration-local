import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class LabeledSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double switchHeight;
  final double switchWidth;
  final MainAxisAlignment mainAxisAlignment;

  const LabeledSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.switchHeight = 22,
    this.switchWidth = 36,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      children: <Widget>[
        // Using Transform to scale down the switch slightly to match the compact design
        FusionSwitch(
          height: switchHeight,
          width: switchWidth,
          value: value,
          onChanged: onChanged,
        ),
        const SizedBox(width: 4),
        FusionAppText(
          text: label,
          style: context.textTheme.labelMedium!.copyWith(),
        ),
      ],
    );
  }
}
