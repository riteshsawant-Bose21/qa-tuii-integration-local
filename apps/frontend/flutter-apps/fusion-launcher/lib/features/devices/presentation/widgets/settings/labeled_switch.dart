import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class LabeledSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LabeledSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Using Transform to scale down the switch slightly to match the compact design
        FusionSwitch(
          height: 22,
          width: 36,
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
