import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_settings_header.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/readonly_text_view.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

class WifiSettingsPage extends StatelessWidget {
  const WifiSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          const NetworkSettingsHeader(
            title: "WIFI",
          ),

          // Row 1: SSID with Configure Button
          SettingsItemRow(
            label: "SSID",
            child: Row(
              children: <Widget>[
                const ReadonlyTextView(value: "NamithGym"),
                const SizedBox(width: 16),
                FusionNeumorphicButton(
                  semanticId: 'wifi_settings_configure_button',
                  borderRadius: 6,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  margin: EdgeInsets.zero,
                  text: "Configure Wifi",
                  onTap: () {},
                  textStyle: context.textTheme.labelMedium!.copyWith(
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Row 2: Security
          const SettingsItemRow(
            label: "Security",
            child: ReadonlyTextView(value: "WPA2/WPA3 Personal"),
          ),

          const SizedBox(height: 10),

          // Row 3: Password (Obscured)
          const SettingsItemRow(
            label: "Password",
            child: ReadonlyTextView(value: "******"),
          ),
        ],
      ),
    );
  }
}
