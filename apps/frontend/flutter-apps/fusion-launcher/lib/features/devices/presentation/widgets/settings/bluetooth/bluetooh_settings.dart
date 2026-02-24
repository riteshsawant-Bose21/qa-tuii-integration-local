import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_settings_header.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'fusion_checkbox.dart' as localCheckBox;
import 'fusion_radio_button.dart';
import 'passcode_input_field.dart';

class BluetoothSettingsPage extends StatefulWidget {
  const BluetoothSettingsPage({super.key});

  @override
  State<BluetoothSettingsPage> createState() => _BluetoothSettingsPageState();
}

class _BluetoothSettingsPageState extends State<BluetoothSettingsPage> {
  // State 0: Security Level (0 = Open, 1 = Secured)
  int _securityLevel = 0;

  // State 1: Is a passcode currently saved?
  bool _isPasscodeSet = false;

  // State 2: Is the user currently trying to change the passcode?
  bool _isChangingPasscode = false;

  // State 3: Bottom Checkbox
  bool _turnOffBluetooth = true;

  // Controllers
  final TextEditingController _setupController = TextEditingController();
  final TextEditingController _currentPasscodeController = TextEditingController(text: "676767"); // Mocked existing
  final TextEditingController _newPasscodeController = TextEditingController();
  final TextEditingController _confirmPasscodeController = TextEditingController();

  @override
  void dispose() {
    _setupController.dispose();
    _currentPasscodeController.dispose();
    _newPasscodeController.dispose();
    _confirmPasscodeController.dispose();
    super.dispose();
  }

  void _handleSaveNewPasscode() {
    // Logic to save would go here
    setState(() {
      _isPasscodeSet = true;
      _isChangingPasscode = false; // Close the change menu
      _currentPasscodeController.text = _newPasscodeController.text; // Update mock
      _newPasscodeController.clear();
      _confirmPasscodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          const NetworkSettingsHeader(title: "BLUETOOTH"),

          // --- Row 1: Security Level Radio Buttons ---
          SettingsItemRow(
            label: "Security Level",
            child: Row(
              children: <Widget>[
                FusionRadioButton<int>(
                  value: 0,
                  groupValue: _securityLevel,
                  label: "Open",
                  onChanged: (int? val) {
                    if (val != null) setState(() => _securityLevel = val);
                  },
                ),
                const SizedBox(width: 24),
                FusionRadioButton<int>(
                  value: 1,
                  groupValue: _securityLevel,
                  label: "Secured",
                  onChanged: (int? val) {
                    if (val != null) setState(() => _securityLevel = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- Logic Block: Passcode UI ---
          // Only show if "Secured" is selected
          if (_securityLevel == 1) ...<Widget>[
            // Case A: First time setup (No passcode set yet)
            if (!_isPasscodeSet)
              SettingsItemRow(
                label: "Setup a passcode",
                child: Row(
                  children: <Widget>[
                    PasscodeInputField(
                      controller: _setupController,
                      hintText: "Enter passcode",
                    ),
                    const SizedBox(width: 16),
                    FusionNeumorphicButton(
                      borderRadius: 6,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: EdgeInsets.zero,
                      text: "Save Passcode",
                      onTap: () {
                        setState(() {
                          _isPasscodeSet = true;
                          _currentPasscodeController.text = _setupController.text;
                        });
                      },
                      textStyle: context.textTheme.labelMedium!.copyWith(
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            // Case B: Passcode is already set (View Mode)
            else
              SettingsItemRow(
                label: "Passcode",
                child: Row(
                  children: <Widget>[
                    PasscodeInputField(
                      controller: _currentPasscodeController,
                      enabled: false, // Readonly
                    ),
                    const SizedBox(width: 16),
                    // "Change passcode" link
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isChangingPasscode = !_isChangingPasscode;
                        });
                      },
                      child: FusionAppText(
                        text: "Change passcode",
                        style: context.textTheme.labelMedium!.copyWith(
                          color: context.colorScheme.textDisabled,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Case C: Change Passcode Flow (Expanded Rows)
            if (_isPasscodeSet && _isChangingPasscode) ...<Widget>[
              const SizedBox(height: 10),
              SettingsItemRow(
                label: "Enter a new passcode",
                child: Row(
                  children: <Widget>[
                    PasscodeInputField(controller: _newPasscodeController),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SettingsItemRow(
                label: "confirm passcode",
                child: Row(
                  children: <Widget>[
                    PasscodeInputField(controller: _confirmPasscodeController),
                    const SizedBox(width: 16),
                    FusionNeumorphicButton(
                      borderRadius: 6,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      margin: EdgeInsets.zero,
                      text: "Save",
                      onTap: _handleSaveNewPasscode,
                      textStyle: context.textTheme.labelMedium!.copyWith(
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),

          // --- Bottom Checkbox ---
          localCheckBox.FusionCheckbox(
            label: "Turn off Bluetooth once Wifi or Ethernet is connected.",
            value: _turnOffBluetooth,
            onChanged: (bool val) => setState(() => _turnOffBluetooth = val),
          ),
        ],
      ),
    );
  }
}
