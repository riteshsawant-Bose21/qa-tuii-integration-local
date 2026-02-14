import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'audio_control/aes_67_io_usage.dart';
import 'audio_control/audio_input_usage_section.dart';
import 'audio_control/audio_ouput_section.dart';
import 'audio_control/audio_status_card.dart';
import 'audio_control/controller_io_section.dart';

class AudioControlTab extends StatelessWidget {
  const AudioControlTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SingleChildScrollView(
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
                      content: AudioInputsUsageSection(),
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: AudioStatusCard(
                      title: "AUDIO OUTPUTS",
                      content: AudioOutputsUsageSection(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            // Row 2: Control I/O & AES67
            SizedBox(
              height: 220,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AudioStatusCard(
                      title: "CONTROL I/O",
                      content: ControlIOSection(),
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: AudioStatusCard(
                      title: "AES67 I/O",
                      content: Aes67IOUsageSection(),
                    ),
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
