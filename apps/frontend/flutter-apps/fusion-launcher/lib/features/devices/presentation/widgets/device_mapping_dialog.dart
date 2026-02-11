import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
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
  List<ProjectDevice> _projectDevices = <ProjectDevice>[];
  List<NetworkHardware> _networkHardware = <NetworkHardware>[];

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock project devices
    _projectDevices = <ProjectDevice>[
      ProjectDevice(
        id: '1',
        name: 'FM6-1',
        location: 'Zone 1',
      ),
      ProjectDevice(
        id: '2',
        name: 'PSM8300-1',
        location: 'Zone 1',
      ),
      ProjectDevice(
        id: '3',
        name: 'CPLT-1',
        location: 'Zone 2',
      ),
      ProjectDevice(
        id: '4',
        name: 'CPLT-2',
        location: 'Zone 2',
      ),
      ProjectDevice(
        id: '5',
        name: 'CPLT-2',
        location: 'Zone 2',
      ),
    ];

    // Mock network hardware
    _networkHardware = <NetworkHardware>[
      NetworkHardware(
        id: 'hw1',
        modelName: 'Fusion Mini FM6',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
      ),
      NetworkHardware(
        id: 'hw2',
        modelName: 'Fusion Mini FM6',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
      ),
      NetworkHardware(
        id: 'hw3',
        modelName: 'Control Pal LT',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
      ),
      NetworkHardware(
        id: 'hw4',
        modelName: 'Control Pal Pro',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
      ),
      NetworkHardware(
        id: 'hw5',
        modelName: 'Power Smart 8300',
        ipAddress: '192.168.50.100',
        firmware: 'v1.1.0',
      ),
    ];
  }

  void _handleAssignHardware(ProjectDevice device, NetworkHardware? hardware) {
    setState(() {
      // Unassign previous hardware if any
      if (device.assignedHardwareId != null) {
        final NetworkHardware prevHardware = _networkHardware.firstWhere(
          (NetworkHardware hw) => hw.id == device.assignedHardwareId,
        );
        prevHardware.assignedToDeviceId = null;
      }

      // Assign new hardware
      if (hardware != null) {
        device.assignedHardwareId = hardware.id;
        hardware.assignedToDeviceId = device.id;
      } else {
        device.assignedHardwareId = null;
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
                        projectDevices: _projectDevices,
                        networkHardware: _networkHardware,
                        onAssignHardware: _handleAssignHardware,
                      )
                      : const Center(
                        child: FusionAppText(
                          text: 'Settings tab - Coming soon',
                          style: TextStyle(
                            color: Color(0xFFB4AFA6),
                            fontSize: 16,
                          ),
                        ),
                      ),
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
                    serviceLocator<ProjectViewModel>().toggleControlMode();
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
