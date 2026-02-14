import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SettingsItemRow extends StatelessWidget {
  final String label;
  final Widget child;
  final int labelFlex;
  final int childFlex;

  const SettingsItemRow({
    super.key,
    required this.label,
    required this.child,
    this.labelFlex = 2,
    this.childFlex = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Fixed width label for alignment
        Expanded(
          flex: labelFlex,
          child: FusionAppText(
            text: label,
            style: context.textTheme.labelMedium,
          ),
        ),
        // The input field/switches
        Expanded(
          flex: childFlex,
          child: child,
        ),
      ],
    );
  }
}
