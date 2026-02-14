import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import 'audio_control/aes_67_io_usage.dart';
import 'audio_control/audio_input_usage_section.dart';
import 'audio_control/audio_ouput_section.dart';
import 'audio_control/audio_status_card.dart';
import 'audio_control/controller_io_section.dart';

class AudioControlTab extends StatelessWidget {
  final HardwareComponent hardwareComponent;

  const AudioControlTab({
    super.key,
    required this.hardwareComponent,
  });

  bool get isAmplifier => hardwareComponent is Amplifier;

  bool get isController => hardwareComponent is FusionController;

  bool get isDsp => hardwareComponent is FusionDsp;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Row 1: Audio Inputs & Outputs
            SizedBox(
              height: 380, // Fixed height to align cards row
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AudioStatusCard(
                      title: "AUDIO INPUTS",
                      content: AudioInputsUsageSection(
                        hardwareComponent: hardwareComponent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: AudioStatusCard(
                      title: "AUDIO OUTPUTS",
                      content: AudioOutputsUsageSection(
                        hardwareComponent: hardwareComponent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            // Row 2: Control I/O & AES67
            SizedBox(
              height: 220,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AudioStatusCard(
                      title: "CONTROL I/O",
                      content: ControlIOSection(
                        hardwareComponent: hardwareComponent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child:
                        isDsp
                            ? const AudioStatusCard(
                              title: "AES67 I/O",
                              content: Aes67IOUsageSection(),
                            )
                            : Container(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
