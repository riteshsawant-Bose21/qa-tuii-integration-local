import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'audio_status_indicator.dart';
import 'section_divider.dart';

class AudioInputUsageRow extends StatelessWidget {
  final IconData? icon;
  final String? name;
  final String? subLabel;
  final bool hasSignal;
  final bool isStereo;

  const AudioInputUsageRow({
    this.icon,
    this.name,
    this.subLabel,
    this.hasSignal = false,
    this.isStereo = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (icon != null)
                      Icon(
                        icon,
                        size: 16,
                        color: context.colorScheme.iconDefault,
                      )
                    else if (name == null) // Indent for empty slots
                      const SizedBox(width: 16),

                    if (icon != null) const SizedBox(width: 12),
                    FusionAppText(text: name ?? "", style: context.textTheme.labelMedium),
                  ],
                ),
                if (name != null) const SectionDivider(),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (isStereo) ...<Widget>[
                      const StatusIndicator(isActive: true, label: "L"),
                      const SizedBox(width: 8),
                      const StatusIndicator(isActive: true, label: "R"),
                    ] else ...<Widget>[
                      StatusIndicator(isActive: hasSignal, label: subLabel ?? ""),
                    ],
                  ],
                ),

                const SectionDivider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
