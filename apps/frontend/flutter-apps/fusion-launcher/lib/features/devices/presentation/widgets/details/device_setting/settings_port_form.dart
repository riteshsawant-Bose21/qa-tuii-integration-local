import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/labeled_switch.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_dropdown.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SettingsPortForm extends StatefulWidget {
  final bool isPrimary;
  final TextEditingController ipController;
  final TextEditingController subnetController;
  final TextEditingController gatewayController;
  final TextEditingController macController;
  final HardwareComponent device;

  const SettingsPortForm({
    super.key,
    required this.isPrimary,
    required this.ipController,
    required this.subnetController,
    required this.gatewayController,
    required this.macController,
    required this.device,
  });

  @override
  State<SettingsPortForm> createState() => _SettingsPortFormState();
}

class _SettingsPortFormState extends State<SettingsPortForm> {
  String selectedNetworkMode = "DHCP";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SettingsItemRow(
          label: "Network Mode",
          labelFlex: 3,
          child: NetworkDropdown<String>(
            items: const <String>["DHCP", "Static"],
            selectedValue: selectedNetworkMode,
            labelBuilder: (String s) => s,
            onChanged: (String? v) {
              if (v != null) {
                setState(() => selectedNetworkMode = v);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "IP address",
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: widget.ipController,
            enabled: selectedNetworkMode == "Static",
            height: 32,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "Subnet Mask",
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: widget.subnetController,
            enabled: selectedNetworkMode == "Static",
            height: 32,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "Default Gateway",
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: widget.gatewayController,
            enabled: selectedNetworkMode == "Static",
            height: 32,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 12),
        SettingsItemRow(
          label: "MAC Address",
          labelFlex: 3,
          child: NeumorphicDarkTextField(
            controller: widget.macController,
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
        if (widget.device is FusionDsp) ...<Widget>[
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
      ],
    );
  }
}
