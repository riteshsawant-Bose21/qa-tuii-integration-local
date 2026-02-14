import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/labeled_switch.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_dropdown.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SettingsPortForm extends StatelessWidget {
  final bool isPrimary;
  final TextEditingController ipController;
  final TextEditingController subnetController;
  final TextEditingController gatewayController;
  final TextEditingController macController;
  final bool viewMoreNetwork;

  const SettingsPortForm({
    super.key,
    required this.isPrimary,
    required this.ipController,
    required this.subnetController,
    required this.gatewayController,
    required this.viewMoreNetwork,
    required this.macController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SettingsItemRow(
          label: "Network Mode",
          child: NetworkDropdown<String>(
            items: const <String>["DHCP", "Static"],
            selectedValue: "DHCP",
            labelBuilder: (String s) => s,
            onChanged: (String? v) {},
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "IP address",
          child: NeumorphicDarkTextField(controller: ipController),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "Subnet Mask",
          child: NeumorphicDarkTextField(controller: subnetController),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "Default Gateway",
          child: NeumorphicDarkTextField(controller: gatewayController),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "MAC Address",
          child: NeumorphicDarkTextField(
            controller: macController,
            enabled: false,
            color: context.colorScheme.elevation2,
          ),
        ),
        // EXPANDED DETAILS (Hidden by default)
        if (viewMoreNetwork) ...<Widget>[
          const SizedBox(height: 12),
          SettingsItemRow(
            label: "VLAN",
            child: LabeledSwitch(label: "", value: true, onChanged: (bool v) {}),
          ),
          const SizedBox(height: 12),
          SettingsItemRow(
            label: "ID",
            child: NeumorphicDarkTextField(
              controller: TextEditingController(text: "1024"),
            ),
          ),
          const SizedBox(height: 12),
          SettingsItemRow(
            label: "Priority",
            child: NeumorphicDarkTextField(
              controller: TextEditingController(text: "1"),
            ),
          ),
        ],
      ],
    );
  }
}
