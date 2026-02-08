import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/labeled_switch.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/readonly_text_view.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../network_settings_header.dart';

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({super.key});

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  // State for the toggle switches
  bool _logError = true;
  bool _logWarning = true;
  bool _logInfo = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          const NetworkSettingsHeader(
            title: "NETWORK AND IP ADDRESS",
          ),

          // Form Field 1: Virtual IP
          SettingsItemRow(
            label: "Virtual IP (IPv4)",
            child: Row(
              children: <Widget>[
                const ReadonlyTextView(value: "192.168.50.100"),
                const SizedBox(width: 16),
                FusionNeumorphicButton(
                  borderRadius: 6,
                  height: 35,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  margin: EdgeInsets.zero,
                  text: "Configure VIP",
                  onTap: () {},
                  textStyle: context.textTheme.labelMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Form Field 2: Current Leader
          const SettingsItemRow(
            label: "Current Leader",
            child: ReadonlyTextView(value: "Fusion Mini FM6"),
          ),

          const SizedBox(height: 10),

          // Form Field 3: Logging Switches
          SettingsItemRow(
            label: "Logging",
            child: Row(
              children: <Widget>[
                LabeledSwitch(
                  label: "Error",
                  value: _logError,
                  onChanged: (bool v) => setState(() => _logError = v),
                ),
                const SizedBox(width: 24),
                LabeledSwitch(
                  label: "Warning",
                  value: _logWarning,
                  onChanged: (bool v) => setState(() => _logWarning = v),
                ),
                const SizedBox(width: 24),
                LabeledSwitch(
                  label: "Info",
                  value: _logInfo,
                  onChanged: (bool v) => setState(() => _logInfo = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
