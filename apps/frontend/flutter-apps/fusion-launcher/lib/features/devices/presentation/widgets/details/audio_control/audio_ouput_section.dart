import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/view_model/device_data_flow/device_data_flow_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'audio_output_usage_row.dart';

class AudioOutputsUsageSection extends StatelessWidget {
  final HardwareComponent hardwareComponent;

  const AudioOutputsUsageSection({
    super.key,
    required this.hardwareComponent,
  });

  @override
  Widget build(BuildContext context) {
    final DeviceDataFlowViewModel vm = DeviceDataFlowViewModel();
    final List<DeviceConnectionInfo> connections = vm.getOutputConnects(dspId: hardwareComponent.id);

    if (connections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FusionAppText(
            text: "No audio outputs connected",
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: connections.length,
      itemBuilder: (BuildContext context, int index) {
        final DeviceConnectionInfo info = connections[index];
        return OutputUsageRow(
          index: index + 1,
          name: info.connectedPortName,
          labelIcon: Icons.speaker_group_outlined,
          labelText: info.deviceName,
          isActive: true,
        );
      },
    );
  }
}
