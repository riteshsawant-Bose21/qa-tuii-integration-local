import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_bluetooth_device.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_header.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_port_form.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_section_container.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/labeled_switch.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import '../../../../authentication/launcher_sign_in_page.dart';
import '../settings/network_dropdown.dart';

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

  // View More State
  bool _viewMoreNetwork = false;

  // Mock Controllers
  final TextEditingController _ipPri = TextEditingController(text: "192.168.0.4");
  final TextEditingController _subPri = TextEditingController(text: "255.255.255.0");
  final TextEditingController _gwPri = TextEditingController(text: "192.168.0.1");
  final TextEditingController _ipSec = TextEditingController(text: "192.168.1.5");
  final TextEditingController _subSec = TextEditingController(text: "255.255.255.0");
  final TextEditingController _gwSec = TextEditingController(text: "192.168.0.1");

  final TextEditingController _macPri = TextEditingController(text: "12:1S:DN:67:26:33:23");
  final TextEditingController _macSec = TextEditingController(text: "12:1S:DN:67:26:33:24");

  final TextEditingController _macWifi = TextEditingController(text: "12:1S:DN:67:26:33:24");

  bool get isAmplifier => widget.hardwareComponent is Amplifier;

  bool get isController => widget.hardwareComponent is FusionController;

  bool get isDsp => widget.hardwareComponent is FusionDsp;

  bool get showOnlyNetworkSettings => isAmplifier || isController;
  @override
  Widget build(BuildContext context) {
    // For Amplifiers and Controllers, we hide most sections and only show Primary Port

    return Column(
      children: <Widget>[
        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // 1. General Section (Hidden for Amps/Controllers)
                if (!showOnlyNetworkSettings) ...<Widget>[
                  SettingsSectionContainer(
                    title: "GENERAL",
                    child: Row(
                      children: <Widget>[
                        FusionSwitch(
                          value: _allowMaster,
                          onChanged: (bool v) => setState(() => _allowMaster = v),
                          height: 24,
                          width: 44,
                        ),
                        const SizedBox(width: 12),
                        const FusionAppText(text: "Allow to become master"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Network (Ethernet) Section
                SettingsSectionContainer(
                  title: "NETWORK (ETHERNET)",
                  child: Column(
                    children: <Widget>[
                      // Top Row: Network Mode & POE (Hidden for simplified view?)
                      // User said: "return only the 'NETWORK (ETHERNET)' part that two only with primary port only"
                      // "that two" might refer to the network mode/poe row OR just the header + primary port.
                      // Given "primary port only no secondary port", I'll keep the top row for now as it's part of Network
                      // but if "that two" meant only 2 fields (IP/Subnet maybe?), it's ambiguous.
                      // Safest interpretation: Keep the Network Section structure but remove Secondary Port.
                      if (!showOnlyNetworkSettings) ...<Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: SettingsItemRow(
                                label: "Network Mode",
                                child: NetworkDropdown<String>(
                                  items: const <String>["Isolated", "Switched"],
                                  selectedValue: "Isolated",
                                  labelBuilder: (String s) => s,
                                  onChanged: (String? v) {},
                                ),
                              ),
                            ),

                            Expanded(
                              flex: 2,
                              child: LabeledSwitch(
                                label: "POE",
                                switchHeight: 24,
                                switchWidth: 44,
                                mainAxisAlignment: MainAxisAlignment.end,
                                value: _poeEnabled,
                                onChanged: (bool v) => setState(() => _poeEnabled = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Columns: Primary & Secondary Port
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // --- PRIMARY PORT ---
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SettingsHeader(title: "PRIMARY PORT"),
                                const SizedBox(height: 16),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: showOnlyNetworkSettings ? 500 : double.infinity,
                                  ),
                                  child: SettingsPortForm(
                                    isPrimary: true,
                                    ipController: _ipPri,
                                    subnetController: _subPri,
                                    gatewayController: _gwPri,
                                    viewMoreNetwork: _viewMoreNetwork,
                                    macController: _macPri,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (!showOnlyNetworkSettings) ...<Widget>[
                            const SizedBox(width: 24),
                            // --- VERTICAL DIVIDER ---
                            Container(width: 1, height: _viewMoreNetwork ? 400 : 200, color: context.colorScheme.elevation2),
                            const SizedBox(width: 24),
                            // --- SECONDARY PORT ---
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const SettingsHeader(title: "SECONDARY PORT"),
                                  const SizedBox(height: 16),
                                  SettingsPortForm(
                                    isPrimary: false,
                                    ipController: _ipSec,
                                    subnetController: _subSec,
                                    gatewayController: _gwSec,
                                    viewMoreNetwork: _viewMoreNetwork,
                                    macController: _macSec,
                                  ),
                                  // View More Toggle
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => setState(() => _viewMoreNetwork = !_viewMoreNetwork),
                                      child: Text(
                                        _viewMoreNetwork ? "View Less" : "View More",
                                        style: TextStyle(color: context.colorScheme.textSecondary, fontSize: 12, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                if (!showOnlyNetworkSettings) ...<Widget>[
                  const SizedBox(height: 16),

                  // 3. Wifi Section
                  SettingsSectionContainer(
                    title: "WIFI",
                    redirectText: "Global Wifi Settings",
                    onRedirectTap: () {},
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Collapsed/Expanded switch logic can be added here
                          SettingsItemRow(
                            label: "Network Mode",
                            child: NetworkDropdown<String>(
                              items: const <String>["DHCP"],
                              selectedValue: "DHCP",
                              labelBuilder: (String s) => s,
                              onChanged: (String? v) {},
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SettingsItemRow(
                            label: "IP address",
                            child: NeumorphicDarkTextField(),
                          ),
                          const SizedBox(height: 12),
                          const SettingsItemRow(
                            label: "Default Gateway",
                            child: NeumorphicDarkTextField(),
                          ),
                          const SizedBox(height: 12),
                          SettingsItemRow(
                            label: "MAC Address",
                            child: NeumorphicDarkTextField(
                              controller: _macWifi,
                              enabled: false,
                              color: context.colorScheme.elevation2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Bluetooth Section
                  SettingsSectionContainer(
                    title: "Bluetooth",
                    isSwitchHeader: true,
                    redirectText: "Global Bluetooth Settings",
                    onRedirectTap: () {},
                    switchValue: _bluetoothEnabled,
                    onSwitchChanged: (bool v) => setState(() => _bluetoothEnabled = v),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SettingsBluetoothDevice(name: "Dell X7282GH"),
                        SizedBox(height: 12),
                        SettingsBluetoothDevice(name: "LG Mini (8H:C6)"),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
