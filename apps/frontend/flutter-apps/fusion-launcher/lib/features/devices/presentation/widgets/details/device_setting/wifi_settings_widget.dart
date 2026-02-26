import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_section_container.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_dropdown.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../authentication/launcher_sign_in_page.dart';

class WifiSettingsWidget extends StatefulWidget {
  const WifiSettingsWidget({super.key});

  @override
  State<WifiSettingsWidget> createState() => _WifiSettingsWidgetState();
}

class _WifiSettingsWidgetState extends State<WifiSettingsWidget> {
  late final TextEditingController _macAddressController;

  @override
  void initState() {
    super.initState();
    _macAddressController = TextEditingController(text: "12:1S:DN:67:26:33:24");
  }

  @override
  void dispose() {
    _macAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionContainer(
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
              labelFlex: 3,
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
              labelFlex: 3,
              child: NeumorphicDarkTextField(
                height: 32,
                borderRadius: 8,
              ),
            ),
            const SizedBox(height: 12),
            const SettingsItemRow(
              label: "Default Gateway",
              labelFlex: 3,
              child: NeumorphicDarkTextField(
                height: 32,
                borderRadius: 8,
              ),
            ),
            const SizedBox(height: 12),
            SettingsItemRow(
              label: "MAC Address",
              labelFlex: 3,
              child: NeumorphicDarkTextField(
                controller: _macAddressController,
                enabled: false,
                height: 32,
                borderRadius: 8,
                color: context.colorScheme.elevation2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
