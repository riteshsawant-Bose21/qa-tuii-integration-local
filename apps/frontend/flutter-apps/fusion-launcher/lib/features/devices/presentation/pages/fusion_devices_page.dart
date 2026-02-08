import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/device_global_settings_tab.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'device_listing_page.dart';

enum DeviceTabs {
  deviceList,
  updates,
  settings,
}

class FusionDevicesPage extends StatefulWidget {
  const FusionDevicesPage({super.key});

  @override
  State<FusionDevicesPage> createState() => _FusionDevicesPageState();
}

class _FusionDevicesPageState extends State<FusionDevicesPage> {
  DeviceTabs _selectedTab = DeviceTabs.deviceList; // Default Tab

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colorScheme.primaryBlack,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. TABS HEADER
          Row(
            children: <Widget>[
              _buildTab(
                'Device List',
                isActive: _selectedTab == DeviceTabs.deviceList,
                onTap: () => setState(() => _selectedTab = DeviceTabs.deviceList),
              ),
              const SizedBox(width: 32),
              _buildTab(
                'Updates',
                hasNotification: true,
                isActive: _selectedTab == DeviceTabs.updates,
                onTap: () => setState(() => _selectedTab = DeviceTabs.updates),
              ),
              const SizedBox(width: 32),
              _buildTab(
                'Settings',
                isActive: _selectedTab == DeviceTabs.settings,
                onTap: () => setState(() => _selectedTab = DeviceTabs.settings),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. TAB CONTENT
          Expanded(
            child: switch (_selectedTab) {
              DeviceTabs.deviceList => const DeviceListTab(),
              DeviceTabs.updates => _buildPlaceholderContent(),
              DeviceTabs.settings => const DeviceGlobalSettingsTab(),
            },
          ),
        ],
      ),
    );
  }

  // --- Tab Views ---

  Widget _buildPlaceholderContent() {
    return Center(
      child: Text(
        "$_selectedTab Page Content",
        style: TextStyle(color: Colors.grey[700], fontSize: 18),
      ),
    );
  }

  Widget _buildTab(String title, {bool hasNotification = false, bool isActive = false, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration:
                isActive
                    ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: context.colorScheme.primaryWhite, width: 2),
                      ),
                    )
                    : null,
            child: FusionAppText(
              text: title,
              style: context.textTheme.titleMedium!.copyWith(
                color: isActive ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (hasNotification)
            Positioned(
              right: -6,
              top: -2,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
