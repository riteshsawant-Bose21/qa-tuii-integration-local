import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_settings_header.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../authentication/launcher_sign_in_page.dart';

class Aes70SettingsPage extends StatefulWidget {
  const Aes70SettingsPage({super.key});

  @override
  State<Aes70SettingsPage> createState() => _Aes70SettingsPageState();
}

class _Aes70SettingsPageState extends State<Aes70SettingsPage> {
  bool _isEnabled = true;
  final TextEditingController _portController = TextEditingController(
    text: "12345",
  );

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header
            const NetworkSettingsHeader(title: "AES70"),

            // --- Row 1: Enable Switch ---
            SettingsItemRow(
              label: "Enable",
              child: Row(
                children: <Widget>[
                  FusionSwitch(
                    height: 22,
                    width: 36,
                    value: _isEnabled,
                    onChanged: (bool v) => setState(() => _isEnabled = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- Row 2: Port Number & Save ---
            SettingsItemRow(
              label: "Port number",
              child: Row(
                children: <Widget>[
                  NeumorphicDarkTextField(
                    width: 300,
                    height: 35,
                    borderRadius: 6,
                    controller: _portController,
                    enabled: _isEnabled, // Disable input if main switch is off
                  ),
                  const SizedBox(width: 16),
                  FusionNeumorphicButton(
                    semanticId: 'aes_settings_save_button',
                    borderRadius: 6,
                    height: 35,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                    ),
                    margin: EdgeInsets.zero,
                    text: "Save",
                    // Disable button logic if switch is off
                    onTap: () {},
                    enabled: _isEnabled,
                    textStyle: context.textTheme.labelMedium!.copyWith(
                      color:
                          _isEnabled
                              ? context.colorScheme.textPrimary
                              : context.colorScheme.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
