import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'audio_details_input_usage_row.dart';

class AudioInputsUsageSection extends StatelessWidget {
  final HardwareComponent hardwareComponent;

  const AudioInputsUsageSection({
    super.key,
    required this.hardwareComponent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: const <Widget>[
        AudioInputUsageRow(icon: Icons.settings_input_component, name: "DVD", hasSignal: true, isStereo: true),

        AudioInputUsageRow(icon: Icons.graphic_eq, name: "Unidentified device", subLabel: "Line In 2", hasSignal: true),

        AudioInputUsageRow(icon: Icons.music_note, name: "Music Player 2", subLabel: "Line In 3"),

        AudioInputUsageRow(subLabel: "Line In 4"),

        AudioInputUsageRow(subLabel: "Line In 5"),

        AudioInputUsageRow(subLabel: "Line In 6"),

        AudioInputUsageRow(subLabel: "Line In 7"),

        AudioInputUsageRow(subLabel: "Line In 8"),
      ],
    );
  }
}
