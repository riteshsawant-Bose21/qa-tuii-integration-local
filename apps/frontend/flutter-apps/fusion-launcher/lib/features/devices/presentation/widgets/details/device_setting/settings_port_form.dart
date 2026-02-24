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

  const SettingsPortForm({
    super.key,
    required this.isPrimary,
    required this.ipController,
    required this.subnetController,
    required this.gatewayController,
    required this.macController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SettingsItemRow(
          label: "Network Mode",
          labelFlex: 3,
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
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: ipController,
            height: 32,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "Subnet Mask",
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: subnetController,
            height: 32,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "Default Gateway",
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: gatewayController,
            height: 32,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "MAC Address",
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: macController,
            enabled: false,
            height: 32,
            borderRadius: 8,
            color: context.colorScheme.elevation2,
            textStyle: context.textTheme.labelMedium!.copyWith(
              color: context.colorScheme.textDisabled,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "VLAN",
          labelFlex: 3,
          child: LabeledSwitch(label: "", value: true, onChanged: (bool v) {}),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "ID",
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: TextEditingController(text: "1024"),
            height: 32,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "Priority",
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: TextEditingController(text: "1"),
            height: 32,
            borderRadius: 8,
          ),
        ),
      ],
    );
  }
}
