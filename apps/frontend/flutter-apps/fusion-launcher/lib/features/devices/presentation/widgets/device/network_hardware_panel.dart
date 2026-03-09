import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/view_model/devices/fusion_network_device_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../hardware_card.dart';

class NetworkHardwarePanel extends StatelessWidget {
  final List<FusionNetworkDevice> networkDevices;
  final Function(String) onDragStarted;
  final VoidCallback onDragEnded;
  final VoidCallback onRecommission;

  const NetworkHardwarePanel({
    super.key,
    required this.networkDevices,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onRecommission,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: 'HARDWARES ON THE NETWORK',
                style: context.textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
                if (vip != null) {
                  context.read<FusionNetworkDeviceViewModel>().getFusionNetworkDevice(vip: vip);
                }
              },
              icon: Icon(Icons.refresh, color: context.colorScheme.primaryColor),
              label: FusionAppText(
                text: 'Refresh',
                style: context.textTheme.labelMedium!.copyWith(
                  color: context.colorScheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline, size: 16, color: context.colorScheme.iconDefault),
            const SizedBox(width: 8),
            Expanded(
              child: FusionAppText(
                text: 'Drag and drop the hardwares to the unassigned area or just select the drop down to map the devices.',
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: context.colorScheme.textBody,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(
          thickness: 1,
          color: context.colorScheme.strokeLight,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BlocBuilder<FusionNetworkDeviceViewModel, FusionNetworkDeviceViewModelState>(
            builder: (BuildContext context, FusionNetworkDeviceViewModelState state) {
              return _buildHardwareListContent(context, state);
            },
          ),
        ),
        const SizedBox(height: 16),
        FusionNeumorphicButton(
          text: "Recommission Network",
          height: 48,
          onTap: onRecommission,
        ),
      ],
    );
  }

  Widget _buildHardwareListContent(BuildContext context, FusionNetworkDeviceViewModelState state) {
    if (state is FusionNetworkDeviceViewModelLoading || state is FusionNetworkDeviceViewModelInitial) {
      return Center(
        child: CircularProgressIndicator(color: context.colorScheme.primaryColor),
      );
    } else if (state is FusionNetworkDeviceViewModelError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FusionAppText(
              text: 'Failed to load devices',
              style: context.textTheme.labelMedium!.copyWith(
                color: context.colorScheme.errorText,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
                if (vip != null) {
                  context.read<FusionNetworkDeviceViewModel>().getFusionNetworkDevice(vip: vip);
                }
              },
              icon: Icon(Icons.refresh, color: context.colorScheme.primaryColor),
              label: FusionAppText(
                text: 'Retry',
                style: context.textTheme.labelMedium!.copyWith(
                  color: context.colorScheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (networkDevices.isEmpty) {
      return Center(
        child: Text(
          "No hardware devices found on the network.",
          style: TextStyle(color: context.colorScheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: networkDevices.length,
      itemBuilder: (BuildContext context, int index) {
        final FusionNetworkDevice hw = networkDevices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HardwareCard(
            hardware: hw,
            onDragStarted: () => onDragStarted(hw.id),
            onDragEnd: onDragEnded,
          ),
        );
      },
    );
  }
}
