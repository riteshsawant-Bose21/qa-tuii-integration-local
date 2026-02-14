import 'package:flutter/material.dart';

import 'audio_output_usage_row.dart';

class AudioOutputsUsageSection extends StatelessWidget {
  const AudioOutputsUsageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const <Widget>[
        OutputUsageRow(index: 1, name: "Line Out 1", labelIcon: Icons.speaker_group_outlined, labelText: "PS (1), Line In 1", isActive: true),

        OutputUsageRow(index: 2, name: "Line Out 2", labelIcon: Icons.speaker_group_outlined, labelText: "PS (1), Line In 2", isActive: true),

        OutputUsageRow(index: 3, name: "Line Out 3", labelIcon: Icons.radio_button_checked, labelText: "Record <>", isActive: true),

        OutputUsageRow(index: 4, name: "Line Out 4"),

        OutputUsageRow(index: 5, name: "Line Out 5"),

        OutputUsageRow(index: 6, name: "Line Out 6"),

        OutputUsageRow(index: 7, name: "Line Out 7"),

        OutputUsageRow(index: 8, name: "Line Out 8"),
      ],
    );
  }
}
