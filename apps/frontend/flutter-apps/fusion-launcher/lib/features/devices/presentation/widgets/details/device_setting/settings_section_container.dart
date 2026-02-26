import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SettingsSectionContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isSwitchHeader;
  final bool? switchValue;
  final String? redirectText;
  final VoidCallback? onRedirectTap;
  final ValueChanged<bool>? onSwitchChanged;

  const SettingsSectionContainer({
    super.key,
    required this.title,
    required this.child,
    this.isSwitchHeader = false,
    this.switchValue,
    this.redirectText,
    this.onRedirectTap,
    this.onSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (isSwitchHeader) ...<Widget>[
                FusionSwitch(
                  value: switchValue!,
                  onChanged: onSwitchChanged!,
                  height: 22,
                  width: 36,
                ),
                const SizedBox(width: 12),
              ],
              FusionAppText(
                text: title,
                style: TextStyle(color: context.colorScheme.textBody),
              ),
              const Spacer(),
              if (redirectText != null)
                InkWell(
                  onTap: onRedirectTap,
                  child: FusionAppText(
                    text: redirectText!,
                    style: context.textTheme.labelMedium!.copyWith(
                      color: context.colorScheme.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.colorScheme.elevation2),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
