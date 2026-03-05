import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_bluetooth_device.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_section_container.dart';

class BluetoothSettingsWidget extends StatelessWidget {
  final bool bluetoothEnabled;
  final ValueChanged<bool> onChanged;

  const BluetoothSettingsWidget({
    super.key,
    required this.bluetoothEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionContainer(
      title: "Bluetooth",
      isSwitchHeader: true,
      redirectText: "Global Bluetooth Settings",
      onRedirectTap: () {},
      switchValue: bluetoothEnabled,
      onSwitchChanged: onChanged,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SettingsBluetoothDevice(name: "Dell X7282GH"),
          SizedBox(height: 12),
          SettingsBluetoothDevice(name: "LG Mini (8H:C6)"),
        ],
      ),
    );
  }
}
