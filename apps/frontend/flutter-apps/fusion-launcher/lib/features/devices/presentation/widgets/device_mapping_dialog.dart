import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/dro/dro_config_screen.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/device_global_settings_tab.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../firmware_update/views/firmware_update_page.dart';
import 'device_mapping_screen.dart';

enum DeviceMappingDialogTab {
  mapping("Mapping"),
  settings("Settings"),
  droConfig("Dro config"),
  updates("Updates");

  final String displayName;
  const DeviceMappingDialogTab(this.displayName);
}

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
  DeviceMappingDialogTab _selectedTab = DeviceMappingDialogTab.mapping;
  int _updatesRefreshToken = 0;

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
              child: Builder(
                builder: (BuildContext context) {
                  switch (_selectedTab) {
                    case DeviceMappingDialogTab.mapping:
                      return const DeviceMappingScreen();
                    case DeviceMappingDialogTab.settings:
                      return const DeviceGlobalSettingsTab();
                    case DeviceMappingDialogTab.droConfig:
                      return const DroConfigScreen();
                    case DeviceMappingDialogTab.updates:
                      return FirmwareUpdatesTab(refreshToken: _updatesRefreshToken);
                  }
                },
              ),
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
                ValueListenableBuilder<bool>(
                  valueListenable: serviceLocator<ProjectViewModel>().isDevicesRegisteringNotifier,
                  builder: (BuildContext context, bool value, Widget? child) {
                    if (value) return const SizedBox(); // Hide close button when devices are being registered

                    return InkWell(
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
                    );
                  },
                ),
              ],
            ),
          ),
          // Tabs
          Row(
            children: <Widget>[
              _buildTab(context, DeviceMappingDialogTab.mapping),
              const SizedBox(width: 32),
              _buildTab(context, DeviceMappingDialogTab.settings),
              const SizedBox(width: 32),
              _buildTab(context, DeviceMappingDialogTab.droConfig),
              const SizedBox(width: 32),
              _buildTab(context, DeviceMappingDialogTab.updates),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, DeviceMappingDialogTab tab) {
    final bool isSelected = _selectedTab == tab;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tab;
          if (tab == DeviceMappingDialogTab.updates) {
            _updatesRefreshToken++;
          }
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
          text: tab.displayName,
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
