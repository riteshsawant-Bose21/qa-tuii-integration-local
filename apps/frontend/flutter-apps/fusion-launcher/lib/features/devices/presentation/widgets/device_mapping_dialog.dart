import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/dro/dro_config_screen.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/device_global_settings_tab.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'device_mapping_screen.dart';

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

  List<HardwareComponent> get _fusionDevices {
    // Combine DSPs, Amplifiers, and Controllers
    final List<HardwareComponent> dsp = serviceLocator<ProjectViewModel>().fusionDsps;
    final List<HardwareComponent> amplifiers = serviceLocator<ProjectViewModel>().amplifiers;
    final List<HardwareComponent> controllers = serviceLocator<ProjectViewModel>().fusionControllers;
    final List<HardwareComponent> endpoints = serviceLocator<ProjectViewModel>().fusionEndpoints;
    return <HardwareComponent>[...dsp, ...amplifiers, ...controllers, ...endpoints];
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
            _buildHeader(context),
            Expanded(
              child:
                  _selectedTabIndex == 0
                      ? DeviceMappingScreen(
                        devices: _fusionDevices,
                      )
                      : _selectedTabIndex == 1
                      ? const DeviceGlobalSettingsTab()
                      : const DroConfigScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
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
                InkWell(
                  child: Icon(
                    Icons.close,
                    color: context.colorScheme.iconWhite,
                  ),
                  onTap: () {
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
              _buildTab(context, 'Mapping', 0),
              const SizedBox(width: 32),
              _buildTab(context, 'Settings', 1),
              const SizedBox(width: 32),
              _buildTab(context, "Dro config", 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, int index) {
    final bool isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
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
            color: isSelected ? context.colorScheme.textPrimary : context.colorScheme.iconDefault,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w200,
          ),
        ),
      ),
    );
  }
}
