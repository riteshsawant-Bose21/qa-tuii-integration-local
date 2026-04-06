import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/view_model/devices/fusion_network_device_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';
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

    final FusionNetworkDeviceViewModel fusionNetworkDeviceViewModel = context.read<FusionNetworkDeviceViewModel>();

    try {
      for (final FusionNetworkDevice hw in _networkDevices.where((FusionNetworkDevice h) => h.id == device.id)) {
        final String newId = const Uuid().v4();
        if (!mounted) return;
        await fusionNetworkDeviceViewModel.updateDeviceDetails(
          currentDeviceId: hw.id,
          newDeviceId: newId,
          name: "Fusion ${FusionUtils.shortStringUUID()}",
          location: "",
        );
      }

      if (hardware != null) {
        final String equipmentLocation = serviceLocator<ProjectViewModel>().getEquipLocationForHardware(hardwareId: device.id)?.name ?? "";

        if (!mounted) return;
        await fusionNetworkDeviceViewModel.updateDeviceDetails(
          currentDeviceId: hardware.id,
          newDeviceId: device.id,
          name: "${device.name} ${Random().nextInt(100)}",
          location: equipmentLocation,
        );
      }

      final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
      if (vip != null && mounted) {
        fusionNetworkDeviceViewModel.getFusionNetworkDevice(vip: vip);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assignment failed: $e')));
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
                      // onRecommission: _onRecommissionNetwork,
                      onRecommission: () => showUnregisteredDevicesClaimDialog(context, widget.devices),
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

/// Opens a dialog that checks the cloud registration status of [hardwareDevices]
/// (via GET /devices) and lists devices that are not yet registered.
/// On confirmation it bulk-registers them then claims each one individually.
void showUnregisteredDevicesClaimDialog(BuildContext context, List<HardwareComponent> hardwareDevices) {
  if (hardwareDevices.isEmpty) return;

  final FusionNetworkDeviceViewModel vm = context.read<FusionNetworkDeviceViewModel>();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return BlocProvider<FusionNetworkDeviceViewModel>.value(
        value: vm,
        child: _UnregisteredDevicesDialog(hardwareDevices: hardwareDevices),
      );
    },
  );
}

class _UnregisteredDevicesDialog extends StatefulWidget {
  final List<HardwareComponent> hardwareDevices;

  const _UnregisteredDevicesDialog({required this.hardwareDevices});

  @override
  State<_UnregisteredDevicesDialog> createState() => _UnregisteredDevicesDialogState();
}

class _UnregisteredDevicesDialogState extends State<_UnregisteredDevicesDialog> {
  // Three phases: checking → listing → registering
  bool _isChecking = true;
  bool _isRegistering = false;
  String? _errorMessage;
  List<HardwareComponent> _unregisteredDevices = <HardwareComponent>[];

  @override
  void initState() {
    super.initState();
    _checkCloudStatus();
  }

  FusionNetworkDeviceViewModel get fusionNetworkDeviceViewModel => context.read<FusionNetworkDeviceViewModel>();
  String get projectId => serviceLocator<ProjectViewModel>().projectId;

  Future<void> _checkCloudStatus() async {
    try {
      final List<HardwareComponent> unregistered = await fusionNetworkDeviceViewModel.getUnregisteredHardware(
        hardwares: widget.hardwareDevices,
        projectId: projectId,
      );

      if (!mounted) return;

      if (unregistered.isEmpty) {
        Navigator.of(context).pop();
        FusionToast.success(context, message: 'All devices are already registered in the cloud.');
        return;
      }

      setState(() {
        _isChecking = false;
        _unregisteredDevices = unregistered;
      });
    } catch (_) {
      if (!mounted) return;
      // On error fall back to showing all hardware so the user can still act.
      setState(() {
        _isChecking = false;
        _unregisteredDevices = widget.hardwareDevices;
      });
    }
  }

  Future<void> _onRegisterAndClaimTap() async {
    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });

    try {
      await fusionNetworkDeviceViewModel.registerAndClaimHardwares(hardwares: _unregisteredDevices, projectId: projectId);

      final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
      if (vip != null && mounted) await fusionNetworkDeviceViewModel.getFusionNetworkDevice(vip: vip);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRegistering = false;
          _errorMessage = 'Registration failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int count = _unregisteredDevices.length;
    final String deviceWord = count == 1 ? 'device' : 'devices';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.elevation1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.colorScheme.strokeLight,
          ),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_isChecking) ...<Widget>[
                    const Spacer(),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Checking cloud registration status…',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withAlpha(160),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                  ] else ...<Widget>[
                    const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Unregistered Devices Found',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withAlpha(180),
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: '$count $deviceWord',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          TextSpan(
                            text: ' ${count == 1 ? 'is' : 'are'} not yet registered in the fusion cloud.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Do you want to register ${count == 1 ? 'it' : 'them'} now?',
                      style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // ── Device list ──
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colorScheme.elevation1,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.colorScheme.strokeLight),
                        ),
                        child: ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          itemCount: _unregisteredDevices.length,
                          itemBuilder: (BuildContext ctx, int index) {
                            final HardwareComponent hw = _unregisteredDevices[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.device_hub_rounded,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          hw.name,
                                          style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          hw.hardwareName,
                                          style: context.textTheme.labelSmall?.copyWith(
                                            color: context.colorScheme.onSurface.withAlpha(140),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Unregistered',
                                      style: context.textTheme.labelSmall?.copyWith(
                                        color: Colors.orange,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.errorText),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  GestureDetector(
                    onTap: (_isChecking || _isRegistering) ? null : () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text(
                        'Skip',
                        style: context.textTheme.l1Regular.copyWith(
                          color: context.colorScheme.textPrimary.withAlpha(160),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isChecking)
                    ElevatedButton(
                      onPressed: _isRegistering ? null : _onRegisterAndClaimTap,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(180, 45)),
                      child: Builder(
                        builder: (BuildContext context) {
                          if (_isRegistering) {
                            return const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          } else {
                            return const Text('Register & Claim Now');
                          }
                        },
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
