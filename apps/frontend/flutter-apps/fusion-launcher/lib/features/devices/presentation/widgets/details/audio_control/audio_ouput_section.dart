import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'audio_output_usage_row.dart';

class AudioOutputsUsageSection extends StatelessWidget {
  final HardwareComponent hardwareComponent;

  const AudioOutputsUsageSection({
    super.key,
    required this.hardwareComponent,
  });

  bool get isAmplifier => hardwareComponent is Amplifier;

  bool get isDsp => hardwareComponent is FusionDsp;

  @override
  Widget build(BuildContext context) {
    final List<AudioOutputData> outputs = _getAudioOutputs();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: outputs.length,
      itemBuilder: (BuildContext context, int index) {
        final AudioOutputData data = outputs[index];
        return OutputUsageRow(
          index: index + 1,
          name: data.name,
          labelIcon: data.icon,
          labelText: data.labelText,
          isActive: data.isActive,
        );
      },
    );
  }

  List<AudioOutputData> _getAudioOutputs() {
    if (isAmplifier) {
      return List<AudioOutputData>.generate(8, (int index) {
        return AudioOutputData(
          name: "Line Out ${index + 1}",
          icon: Icons.speaker_group_outlined,
          labelText: "Circuit ${index + 1}",
          isActive: true,
        );
      });
    }

    // Default / DSP behavior (keeping existing hardcoded values for safety/reference)
    return <AudioOutputData>[
      AudioOutputData(name: "Line Out 1", icon: Icons.speaker_group_outlined, labelText: "PS (1), Line In 1", isActive: true),
      AudioOutputData(name: "Line Out 2", icon: Icons.speaker_group_outlined, labelText: "PS (1), Line In 2", isActive: true),
      AudioOutputData(name: "Line Out 3", icon: Icons.radio_button_checked, labelText: "Record <>", isActive: true),
      AudioOutputData(name: "Line Out 4"),
      AudioOutputData(name: "Line Out 5"),
      AudioOutputData(name: "Line Out 6"),
      AudioOutputData(name: "Line Out 7"),
      AudioOutputData(name: "Line Out 8"),
    ];
  }
}

class AudioOutputData {
  final String name;
  final IconData? icon;
  final String? labelText;
  final bool isActive;

  AudioOutputData({
    required this.name,
    this.icon,
    this.labelText,
    this.isActive = false,
  });
}
