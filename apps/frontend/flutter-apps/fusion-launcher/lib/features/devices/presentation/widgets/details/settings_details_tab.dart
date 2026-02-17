import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/bluetooth_settings_widget.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/general_settings_widget.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/network_settings_widget.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/wifi_settings_widget.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

class DeviceSettingsTab extends StatefulWidget {
  final HardwareComponent hardwareComponent;

  const DeviceSettingsTab({
    super.key,
    required this.hardwareComponent,
  });

  @override
  State<DeviceSettingsTab> createState() => _DeviceSettingsTabState();
}

class _DeviceSettingsTabState extends State<DeviceSettingsTab> {
  // General State
  bool _allowMaster = true;
  bool _poeEnabled = true;
  bool _bluetoothEnabled = false;

  bool get isAmplifier => widget.hardwareComponent is Amplifier;

  bool get isController => widget.hardwareComponent is FusionController;

  bool get isDsp => widget.hardwareComponent is FusionDsp;

  bool get showOnlyNetworkSettings => isAmplifier || isController;
  int _selectedIndex = 0;

  List<DeviceSettingsTabMenuItem> get _menuItems {
    final List<DeviceSettingsTabMenuItem> items = <DeviceSettingsTabMenuItem>[];

    // General (Hidden for Amps/Controllers)
    if (!showOnlyNetworkSettings) {
      items.add(
        DeviceSettingsTabMenuItem(
          title: "General",
          // Using generic icon if specific asset not imported/guaranteed, or could import AssetIcons
          icon: AssetIcons.webIcon,
          content: GeneralSettingsWidget(
            allowMaster: _allowMaster,
            onChanged: (bool v) => setState(() => _allowMaster = v),
          ),
        ),
      );
    }

    // Network (Always shown)
    items.add(
      DeviceSettingsTabMenuItem(
        title: "Network (Ethernet)",
        icon: AssetIcons.networkIcon,
        content: NetworkSettingsWidget(
          showOnlyNetworkSettings: showOnlyNetworkSettings,
          poeEnabled: _poeEnabled,
          onPoeChanged: (bool v) => setState(() => _poeEnabled = v),
        ),
      ),
    );

    // Wifi (Hidden for Amps/Controllers)
    if (!showOnlyNetworkSettings) {
      items.add(
        DeviceSettingsTabMenuItem(
          title: "Wifi",
          icon: AssetIcons.wifiIcon,
          content: const WifiSettingsWidget(),
        ),
      );
    }

    // Bluetooth (Hidden for Amps/Controllers)
    if (!showOnlyNetworkSettings) {
      items.add(
        DeviceSettingsTabMenuItem(
          title: "Bluetooth",
          icon: AssetIcons.bluetooth,
          content: BluetoothSettingsWidget(
            bluetoothEnabled: _bluetoothEnabled,
            onChanged: (bool v) => setState(() => _bluetoothEnabled = v),
          ),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    // print("DeviceSettingsTab build. isController: $isController, showOnlyNetworkSettings: $showOnlyNetworkSettings");
    final List<DeviceSettingsTabMenuItem> items = _menuItems;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // --- LEFT SIDEBAR ---
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final bool isSelected = _selectedIndex == index;
                  final DeviceSettingsTabMenuItem item = items[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? context.colorScheme.elevation2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _selectedIndex = index),
                      leading: FusionImage.asset(
                        item.icon,
                        assetColor: context.colorScheme.iconWhite,
                        height: 16,
                      ),
                      title: FusionAppText(
                        text: item.title,
                        style: context.textTheme.bodySmall!.copyWith(
                          color: context.colorScheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
              ),
            ),
          ),

          VerticalDivider(
            thickness: 1,
            color: context.colorScheme.strokeLight,
          ),

          // --- RIGHT CONTENT ---
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: items[_selectedIndex].content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceSettingsTabMenuItem {
  final String title;
  final String icon;
  final Widget content;

  DeviceSettingsTabMenuItem({
    required this.title,
    required this.icon,
    required this.content,
  });
}
