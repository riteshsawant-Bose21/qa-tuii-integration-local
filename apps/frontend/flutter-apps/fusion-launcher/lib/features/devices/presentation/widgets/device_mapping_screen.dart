import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/devices/view_model/devices/fusion_network_device_vm.dart';
import 'package:uuid/uuid.dart';

import 'device/device_mapping_table.dart';
import 'device/network_hardware_panel.dart';

class DeviceMappingScreen extends StatelessWidget {
  final List<HardwareComponent> devices;

  const DeviceMappingScreen({
    super.key,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FusionNetworkDeviceViewModel>(
      create: (BuildContext context) {
        final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
        final FusionNetworkDeviceViewModel viewModel = FusionNetworkDeviceViewModel(serviceLocator<FusionDeviceService>());
        if (vip != null) {
          viewModel.getFusionNetworkDevice(vip: vip);
        }
        return viewModel;
      },
      child: DeviceMappingScreenView(devices: devices),
    );
  }
}

class DeviceMappingScreenView extends StatefulWidget {
  final List<HardwareComponent> devices;

  const DeviceMappingScreenView({
    super.key,
    required this.devices,
  });

  @override
  State<DeviceMappingScreenView> createState() => _DeviceMappingScreenViewState();
}

class _DeviceMappingScreenViewState extends State<DeviceMappingScreenView> {
  String? _draggedHardwareId;
  List<FusionNetworkDevice> _networkDevices = <FusionNetworkDevice>[];

  Future<void> _handleAssignHardware(HardwareComponent device, FusionNetworkDevice? hardware) async {
    if (hardware != null && hardware.id == device.id) return;

    try {
      for (final FusionNetworkDevice hw in _networkDevices.where((FusionNetworkDevice h) => h.id == device.id)) {
        final String newId = const Uuid().v4();
        if (!mounted) return;
        await context.read<FusionNetworkDeviceViewModel>().updateDeviceDetails(
          currentDeviceId: hw.id,
          newDeviceId: newId,
          name: "Fusion ${FusionUtils.shortStringUUID()}",
          location: "",
        );
      }

      if (hardware != null) {
        final String equipmentLocation = serviceLocator<ProjectViewModel>().getEquipLocationForHardware(hardwareId: device.id)?.name ?? "";

        if (!mounted) return;
        await context.read<FusionNetworkDeviceViewModel>().updateDeviceDetails(
          currentDeviceId: hardware.id,
          newDeviceId: device.id,
          name: "${device.name} ${Random().nextInt(100)}",
          location: equipmentLocation,
        );
      }

      final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
      if (vip != null && mounted) {
        context.read<FusionNetworkDeviceViewModel>().getFusionNetworkDevice(vip: vip);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assignment failed: $e')));
      }
    }
  }

  void _onRecommissionNetwork() {
    Navigator.pop(context);
    serviceLocator<ProjectViewModel>().setVirtualIP(ip: null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FusionNetworkDeviceViewModel, FusionNetworkDeviceViewModelState>(
      listener: (BuildContext context, FusionNetworkDeviceViewModelState state) {
        if (state is FusionNetworkDeviceViewModelLoaded) {
          setState(() {
            _networkDevices = List<FusionNetworkDevice>.from(state.devices);
          });
        } else if (state is FusionNetworkDeviceViewModelError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading network devices: ${state.message}'),
              backgroundColor: context.colorScheme.errorText,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // TABLE SECTION
                  Expanded(
                    flex: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colorScheme.elevation1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: DeviceMappingTable(
                        devices: widget.devices,
                        networkDevices: _networkDevices,
                        draggedHardwareId: _draggedHardwareId,
                        onDragEnter: (String id) => setState(() => _draggedHardwareId = id),
                        onDragLeave: () => setState(() => _draggedHardwareId = null),
                        onAssignHardware: _handleAssignHardware,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // DIVIDER
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: context.colorScheme.strokeLight,
                  ),
                  const SizedBox(width: 16),
                  // PANEL SECTION
                  Expanded(
                    flex: 3,
                    child: NetworkHardwarePanel(
                      networkDevices: _networkDevices,
                      onDragStarted: (String id) => setState(() => _draggedHardwareId = id),
                      onDragEnded: () => setState(() => _draggedHardwareId = null),
                      onRecommission: _onRecommissionNetwork,
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
