import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class StatusIndicator extends StatelessWidget {
  final bool isActive;
  final String label;

  const StatusIndicator({
    required this.isActive,
    required this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? context.colorScheme.green : context.colorScheme.textGrey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        FusionAppText(
          text: label,
          style: context.textTheme.labelMedium!.copyWith(color: isActive ? context.colorScheme.textPrimary : context.colorScheme.textGrey),
        ),
      ],
    );
  }
}
