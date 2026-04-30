import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/view_model/device_data_flow/device_data_flow_view_model.dart';
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
    final DeviceDataFlowViewModel vm = DeviceDataFlowViewModel();
    final List<DeviceConnectionInfo> connections = vm.getSourceConnections(dspId: hardwareComponent.id);

    if (connections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FusionAppText(
            text: "No audio inputs connected",
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
        return AudioInputUsageRow(
          icon: Icons.settings_input_component,
          name: info.deviceName,
          subLabel: info.connectedPortName,
          blockId: info.deviceId,
          isStereo: false,
        );
      },
    );
  }
}
