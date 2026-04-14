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
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 250,
                    ),
                    child: AudioStatusCard(
                      title: "AUDIO INPUTS",
                      content: AudioInputsUsageSection(
                        hardwareComponent: hardwareComponent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 250,
                    ),
                    child: AudioStatusCard(
                      title: "AUDIO OUTPUTS",
                      content: AudioOutputsUsageSection(
                        hardwareComponent: hardwareComponent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Row 2: Control I/O & AES67
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 250,
                    ),
                    child: AudioStatusCard(
                      title: "CONTROL I/O",
                      content: ControlIOSection(
                        hardwareComponent: hardwareComponent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child:
                      isDsp
                          ? Container(
                            constraints: const BoxConstraints(
                              minHeight: 250,
                            ),
                            child: const AudioStatusCard(
                              title: "AES67 I/O",
                              content: Aes67IOUsageSection(),
                            ),
                          )
                          : Container(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
