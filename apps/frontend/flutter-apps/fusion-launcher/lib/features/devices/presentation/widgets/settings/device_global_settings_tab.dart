import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/ptp_settings/ptp_settings.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/wifi_settings/wifi_settings.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'aes_settings/aes_settings.dart';
import 'bluetooth/bluetooh_settings.dart';
import 'network_ip/network_settings.dart';
import 'passcode_settings/passcode_settings.dart';
import 'time_zone_settings/time_zone_settings.dart';

class DeviceGlobalSettingsTab extends StatelessWidget {
  const DeviceGlobalSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDashboard();
  }
}

// --- 1. Configuration & Data Models ---

// Define your menu items here.
// This makes it easy to add "Wifi", "Bluetooth" screens in the future.
class MenuItem {
  final String title;
  final String? icon;
  final Widget content;

  MenuItem({
    required this.title,
    this.icon,
    required this.content,
  });
}

// --- 2. Main Dashboard Layout ---

class SettingsDashboard extends StatefulWidget {
  const SettingsDashboard({super.key});

  @override
  State<SettingsDashboard> createState() => _SettingsDashboardState();
}

class _SettingsDashboardState extends State<SettingsDashboard> {
  // Track the currently selected page
  int _selectedIndex = 0;

  // Define the pages.
  // For now, only NetworkSettings is implemented fully.
  // Others use a placeholder.
  late final List<MenuItem> _menuItems;

  @override
  void initState() {
    super.initState();
    _menuItems = <MenuItem>[
      MenuItem(
        title: "Network & IP address",
        icon: AssetIcons.networkIcon,
        content: const NetworkSettingsPage(),
      ),
      MenuItem(
        title: "Timezone & Clocks",
        icon: AssetIcons.timeIcon,
        content: const TimezoneSettingsPage(),
      ),
      MenuItem(
        title: "Wifi",
        icon: AssetIcons.wifiIcon,
        content: const WifiSettingsPage(),
      ),
      MenuItem(
        title: "Bluetooth",
        icon: AssetIcons.bluetooth,
        content: const BluetoothSettingsPage(),
      ),
      MenuItem(
        title: "PTP",
        icon: null,
        content: const PtpSettingsPage(),
      ),
      MenuItem(
        title: "Passcode",
        icon: null,
        content: const PasscodeSettingsPage(),
      ),
      MenuItem(
        title: "AES70",
        icon: null,
        content: const Aes70SettingsPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
      ),
      child: Row(
        children: <Widget>[
          // --- LEFT SIDEBAR ---
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                children: <Widget>[
                  // Render the list of buttons dynamically
                  Expanded(
                    child: ListView.builder(
                      itemCount: _menuItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        final bool isSelected = _selectedIndex == index;
                        final MenuItem item = _menuItems[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            // The selected item has a lighter background
                            color: isSelected ? context.colorScheme.elevation2 : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            onTap: () => setState(() => _selectedIndex = index),
                            leading:
                                item.icon != null
                                    ? FusionImage.asset(
                                      item.icon,
                                      assetColor: context.colorScheme.iconWhite,
                                      height: 20,
                                      width: 20,
                                    )
                                    : const SizedBox(width: 20),
                            // Keep alignment if no icon
                            title: FusionAppText(
                              text: item.title,
                              style: context.textTheme.bodySmall!.copyWith(
                                color: context.colorScheme.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          //vertical divider
          Container(
            width: 1,
            color: context.colorScheme.strokeLight,
            margin: const EdgeInsets.symmetric(vertical: 20),
          ),

          // --- RIGHT CONTENT AREA ---
          Expanded(
            flex: 4,
            child: Container(
              // This is where the magic happens: switching the widget
              child: _menuItems[_selectedIndex].content,
            ),
          ),
        ],
      ),
    );
  }
}
