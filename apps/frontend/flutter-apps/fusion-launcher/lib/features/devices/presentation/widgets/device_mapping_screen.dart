import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/view_model/devices/fusion_network_device_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import 'device/device_mapping_table.dart';
import 'device/network_hardware_panel.dart';

class DeviceMappingScreen extends StatelessWidget {
  const DeviceMappingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FusionNetworkDeviceViewModel>(
      create: (BuildContext context) {
        final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
        final FusionNetworkDeviceViewModel viewModel = FusionNetworkDeviceViewModel(
          serviceLocator<FusionDeviceService>(),
        );
        if (vip != null) {
          viewModel.getFusionNetworkDevice(vip: vip);
        }
        return viewModel;
      },
      child: const DeviceMappingScreenView(),
    );
  }
}

class DeviceMappingScreenView extends StatefulWidget {
  const DeviceMappingScreenView({
    super.key,
  });

  @override
  State<DeviceMappingScreenView> createState() => _DeviceMappingScreenViewState();
}

class _DeviceMappingScreenViewState extends State<DeviceMappingScreenView> {
  String? _draggedHardwareId;
  List<FusionNetworkDevice> _networkDevices = <FusionNetworkDevice>[];
  List<FusionNetworkController> _networkControllers = <FusionNetworkController>[];

  List<HardwareComponent> get fusionDevices {
    // Combine DSPs, Amplifiers, and Controllers
    final List<HardwareComponent> dsp = serviceLocator<ProjectViewModel>().fusionDsps;
    final List<HardwareComponent> amplifiers = serviceLocator<ProjectViewModel>().amplifiers;
    final List<HardwareComponent> controllers = serviceLocator<ProjectViewModel>().fusionControllers;
    final List<HardwareComponent> endpoints = serviceLocator<ProjectViewModel>().fusionEndpoints;
    return <HardwareComponent>[...dsp, ...amplifiers, ...controllers, ...endpoints];
  }

  FusionNetworkDeviceViewModel get _vm => context.read<FusionNetworkDeviceViewModel>();

  Future<void> _handleAssignHardware(HardwareComponent device, FusionNetworkDevice? hardware) async {
    try {
      await _vm.assignHardwareToDevice(device: device, hardware: hardware);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assignment failed: $e')));
      }
    }
  }

  Future<void> _handleAssignController(FusionController device, FusionNetworkController? controller) async {
    try {
      await _vm.assignControllerToDevice(device: device, controller: controller);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Controller assignment failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FusionNetworkDeviceViewModel, FusionNetworkDeviceViewModelState>(
      listener: (BuildContext context, FusionNetworkDeviceViewModelState state) {
        if (state is FusionNetworkDeviceViewModelLoaded) {
          setState(() {
            _networkDevices = List<FusionNetworkDevice>.from(state.devices);
            _networkControllers = List<FusionNetworkController>.from(state.controllers);
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
                        devices: fusionDevices,
                        networkDevices: _networkDevices,
                        networkControllers: _networkControllers,
                        draggedHardwareId: _draggedHardwareId,
                        onDragEnter: (String id) => setState(() => _draggedHardwareId = id),
                        onDragLeave: () => setState(() => _draggedHardwareId = null),
                        onAssignHardware: _handleAssignHardware,
                        onAssignController: _handleAssignController,
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

                  Expanded(
                    flex: 3,
                    child: NetworkHardwarePanel(
                      networkDevices: _networkDevices,
                      networkControllers: _networkControllers,
                      onDragStarted: (String id) => setState(() => _draggedHardwareId = id),
                      onDragEnded: () => setState(() => _draggedHardwareId = null),
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
