import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/device_global_settings_tab.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'device_mapping_screen.dart';
import 'device_models.dart';

class DeviceMappingDialog extends StatefulWidget {
  const DeviceMappingDialog({super.key});

  //show dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const DeviceMappingDialog(),
    );
  }

  @override
  State<DeviceMappingDialog> createState() => _DeviceMappingDemoState();
}

class _DeviceMappingDemoState extends State<DeviceMappingDialog> {
  int _selectedTabIndex = 0;
  List<NetworkHardware> _networkHardware = <NetworkHardware>[];

  List<HardwareComponent> get _fusionDevices {
    // Combine DSPs, Amplifiers, and Controllers
    final List<HardwareComponent> dsp = serviceLocator<ProjectViewModel>().fusionDsps;
    final List<HardwareComponent> amplifiers = serviceLocator<ProjectViewModel>().amplifiers;
    final List<HardwareComponent> controllers = serviceLocator<ProjectViewModel>().fusionControllers;
    return <HardwareComponent>[...dsp, ...amplifiers, ...controllers];
  }

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock project devices

    // Mock network hardware
    _networkHardware = <NetworkHardware>[
      NetworkHardware(
        id: 'hw1',
        modelName: 'Fusion Mini FM6',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
        type: NetworkHardwareType.dsp,
      ),
      NetworkHardware(
        id: 'hw2',
        modelName: 'Fusion Mini FM6',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
        type: NetworkHardwareType.dsp,
      ),
      NetworkHardware(
        id: 'hw3',
        modelName: 'Control Pal LT',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
        type: NetworkHardwareType.controller,
      ),
      NetworkHardware(
        id: 'hw4',
        modelName: 'Control Pal Pro',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
        type: NetworkHardwareType.controller,
      ),
      NetworkHardware(
        id: 'hw5',
        modelName: 'Power Smart 8300',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
        type: NetworkHardwareType.amplifier,
      ),
    ];
  }

  void _handleAssignHardware(HardwareComponent device, NetworkHardware? hardware) {
    setState(() {
      // 1. Unassign: Find any hardware currently assigned to THIS device and clear it.
      // We iterate through the list to ensure we catch the specific hardware instance
      // that is currently holding this device's ID.
      for (final NetworkHardware hw in _networkHardware) {
        if (hw.assignedToDeviceId == device.id) {
          hw.assignedToDeviceId = null;
        }
      }

      // 2. Assign: If a new hardware is selected, link it to this device.
      if (hardware != null) {
        // We look up the hardware in the main list to ensure we are modifying the
        // source of truth (in case 'hardware' passed in is a copy).
        final NetworkHardware targetHw = _networkHardware.firstWhere((NetworkHardware hw) => hw.id == hardware.id);

        // Setting this automatically overwrites any previous device ID,
        // handling the case where we "steal" hardware from another device.
        targetHw.assignedToDeviceId = device.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.elevation1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.colorScheme.strokeLight,
          ),
        ),
        child: Column(
          children: <Widget>[
            _buildHeader(),
            Expanded(
              child:
                  _selectedTabIndex == 0
                      ? DeviceMappingScreen(
                        devices: _fusionDevices,
                        networkHardware: _networkHardware,
                        onAssignHardware: _handleAssignHardware,
                      )
                      : const DeviceGlobalSettingsTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.strokeLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: <Widget>[
          // Title
          SizedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FusionAppText(
                  text: 'CONFIGURE NETWORK',
                  style: context.textTheme.labelMedium,
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: context.colorScheme.iconWhite,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (serviceLocator<ProjectViewModel>().virtualIP == null) {
                      serviceLocator<ProjectViewModel>().toggleControlMode();
                    }
                  },
                ),
              ],
            ),
          ),
          // Tabs
          Row(
            children: <Widget>[
              _buildTab('Mapping', 0),
              const SizedBox(width: 32),
              _buildTab('Settings', 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final bool isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? context.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: FusionAppText(
          text: label,
          style: TextStyle(
            color: isSelected ? context.colorScheme.primary : const Color(0xFF77746E),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
