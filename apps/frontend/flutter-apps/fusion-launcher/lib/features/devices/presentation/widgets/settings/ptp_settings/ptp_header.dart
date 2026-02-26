import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class PtpSettingsHeader extends StatelessWidget {
  final bool isDefault;
  final ValueChanged<bool> onDefaultChanged;

  const PtpSettingsHeader({
    super.key,
    required this.isDefault,
    required this.onDefaultChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            FusionAppText(
              text: "PTP",
              style: context.textTheme.labelMedium!.copyWith(
                color: context.colorScheme.textBody,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 50),
            // Reusing LabeledSwitch but reversing order to match design: "Default [Switch]"
            Row(
              children: <Widget>[
                FusionAppText(
                  text: "Custom",
                  style: context.textTheme.labelMedium!.copyWith(
                    color: context.colorScheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                FusionSwitch(
                  height: 22,
                  width: 36,
                  value: isDefault,
                  onChanged: onDefaultChanged,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        Divider(
          color: context.colorScheme.elevation2,
          thickness: 1,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
