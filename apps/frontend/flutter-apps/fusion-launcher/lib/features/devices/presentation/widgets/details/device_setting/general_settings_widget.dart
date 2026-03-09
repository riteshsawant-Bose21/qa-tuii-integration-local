import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_section_container.dart';
import 'package:fusion_lib/fusion_lib.dart';

class GeneralSettingsWidget extends StatelessWidget {
  final bool allowMaster;
  final ValueChanged<bool> onChanged;

  const GeneralSettingsWidget({
    super.key,
    required this.allowMaster,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionContainer(
      title: "GENERAL",
      child: Row(
        children: <Widget>[
          FusionSwitch(
            value: allowMaster,
            onChanged: onChanged,
            height: 24,
            width: 44,
          ),
          const SizedBox(width: 12),
          const FusionAppText(text: "Allow to become master"),
        ],
      ),
    );
  }
}
