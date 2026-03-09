import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DeviceDetailsFooter extends StatelessWidget {
  final String label;
  final String value;
  final Widget? info;

  const DeviceDetailsFooter({
    super.key,
    required this.label,
    required this.value,
    this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: label,
          style: context.textTheme.labelSmall!.copyWith(fontSize: 10, color: context.colorScheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Row(
          children: <Widget>[
            FusionAppText(
              text: value,
              style: context.textTheme.labelSmall!.copyWith(color: context.colorScheme.textPrimary),
            ),
            if (info != null) ...<Widget>[
              const SizedBox(width: 4),
              info!,
            ],
          ],
        ),
      ],
    );
  }
}
