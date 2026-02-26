import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/audio_control/section_divider.dart';
import 'package:fusion_lib/fusion_lib.dart';

class OutputUsageRow extends StatelessWidget {
  final int index;
  final String name;
  final String? labelText;
  final IconData? labelIcon;
  final bool isActive;

  const OutputUsageRow({
    required this.index,
    required this.name,
    this.labelText,
    this.labelIcon,
    this.isActive = false,
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
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? context.colorScheme.green : context.colorScheme.textGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FusionAppText(
                        text: name,
                        style: context.textTheme.labelMedium!.copyWith(
                          color: isActive ? context.colorScheme.textPrimary : context.colorScheme.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SectionDivider(),
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
                    if (labelText != null) ...<Widget>[
                      Icon(
                        labelIcon ?? Icons.device_hub,
                        size: 14,
                        color: context.colorScheme.iconDefault,
                      ),
                      const SizedBox(width: 8),
                      FusionAppText(
                        text: labelText!,
                        style: context.textTheme.labelSmall!.copyWith(
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (labelText != null) const SectionDivider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
