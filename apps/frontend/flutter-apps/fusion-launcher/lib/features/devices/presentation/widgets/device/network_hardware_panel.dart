import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/device_registration/views/device_registraion_page.dart';
import 'package:fusion_launcher/features/devices/view_model/devices/fusion_network_device_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../hardware_card.dart';

class NetworkHardwarePanel extends StatelessWidget {
  final List<FusionNetworkDevice> networkDevices;
  final List<FusionNetworkController> networkControllers;
  final Function(String) onDragStarted;
  final VoidCallback onDragEnded;

  const NetworkHardwarePanel({
    super.key,
    required this.networkDevices,
    this.networkControllers = const <FusionNetworkController>[],
    required this.onDragStarted,
    required this.onDragEnded,
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
        Builder(
          builder: (BuildContext context) {
            final bool hasUnRegisteredDevices = context.watch<FusionNetworkDeviceViewModel>().hasUnRegisteredDevices;

            if (!hasUnRegisteredDevices) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 16),
                FusionNeumorphicButton(
                  semanticId: "register_devices_btn",
                  text: "Register devices",
                  height: 48,
                  onTap: () {
                    showUnregisteredDevicesClaimDialog(context).then(
                      (void value) {
                        if (!context.mounted) return;
                        // After the dialog is closed, refresh the device list to reflect any changes in registration status.
                        final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
                        if (vip != null) context.read<FusionNetworkDeviceViewModel>().getFusionNetworkDevice(vip: vip);
                        serviceLocator<ProjectViewModel>().isDevicesRegisteringNotifier.value = false;
                      },
                    );
                  },
                ),
              ],
            );
          },
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

    if (networkDevices.isEmpty && networkControllers.isEmpty) {
      return Center(
        child: Text(
          "No hardware devices found on the network.",
          style: TextStyle(color: context.colorScheme.textSecondary),
        ),
      );
    }

    final int totalCount = networkDevices.length + networkControllers.length;

    return ListView.builder(
      itemCount: totalCount,
      itemBuilder: (BuildContext context, int index) {
        if (index < networkDevices.length) {
          final FusionNetworkDevice hw = networkDevices[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HardwareCard(
              hardware: hw,
              onDragStarted: () => onDragStarted(hw.id),
              onDragEnd: onDragEnded,
            ),
          );
        }

        final FusionNetworkController c = networkControllers[index - networkDevices.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ControllerCard(
            controller: c,
            onDragStarted: () => onDragStarted(c.id),
            onDragEnd: onDragEnded,
          ),
        );
      },
    );
  }
}

/// Compact draggable card representing a [FusionNetworkController] in the right-hand
/// "Hardware on the network" panel. Drag payload is the controller's id (String) so that
/// table rows can resolve it from the controllers list.
class ControllerCard extends StatelessWidget {
  final FusionNetworkController controller;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const ControllerCard({
    super.key,
    required this.controller,
    this.onDragStarted,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: controller.id,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: SizedBox(width: 280, child: _buildContent(context, isDragging: true)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildContent(context)),
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd?.call(),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context, {bool isDragging = false}) {
    return Container(
      width: isDragging ? 280 : null,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool showText = constraints.maxWidth > 50 || isDragging;
          return Row(
            children: <Widget>[
              if (showText)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: FusionAppText(
                          text: controller.name,
                          style: context.textTheme.bodyMedium,
                          textOverflow: TextOverflow.ellipsis,
                          maxLine: 1,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: FusionAppText(
                          text: "IP: ${controller.address}",
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.textSecondary,
                          ),
                          textOverflow: TextOverflow.ellipsis,
                          maxLine: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              if (showText) const SizedBox(width: 8),
              Icon(
                Icons.settings_remote,
                size: 20,
                color: context.colorScheme.iconWhite,
              ),
            ],
          );
        },
      ),
    );
  }
}
