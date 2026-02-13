import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SettingsItemRow extends StatelessWidget {
  final String label;
  final Widget child;

  const SettingsItemRow({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Fixed width label for alignment
        Expanded(
          flex: 2,
          child: FusionAppText(
            text: label,
            style: context.textTheme.labelMedium,
          ),
        ),
        // The input field/switches
        Expanded(flex: 8, child: child),
      ],
    );
  }
}
