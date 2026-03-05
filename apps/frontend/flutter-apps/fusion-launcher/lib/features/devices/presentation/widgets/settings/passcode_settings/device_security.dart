import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../bluetooth/fusion_radio_button.dart';
import '../bluetooth/passcode_input_field.dart';

class SecuritySection extends StatefulWidget {
  final String? sectionTitle;
  final String radioLabel;
  final String passcodeLabel;

  const SecuritySection({
    super.key,
    this.sectionTitle,
    required this.radioLabel,
    required this.passcodeLabel,
  });

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  // State 0: Security Level (0 = Open, 1 = Secured)
  int _securityLevel = 0;

  // State 1: Is a passcode currently saved?
  bool _isPasscodeSet = false;

  // State 2: Is the user currently trying to change the passcode?
  bool _isChangingPasscode = false;

  // Controllers
  final TextEditingController _setupController = TextEditingController();
  final TextEditingController _currentPasscodeController = TextEditingController(text: "******");
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
    setState(() {
      _isPasscodeSet = true;
      _isChangingPasscode = false;
      _currentPasscodeController.text = "******"; // Reset to masked view
      _newPasscodeController.clear();
      _confirmPasscodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Optional Section Title (e.g., "Device Settings")
        if (widget.sectionTitle != null) ...<Widget>[
          FusionAppText(
            text: widget.sectionTitle!,
            style: context.textTheme.labelMedium!.copyWith(
              color: context.colorScheme.textBody,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // --- Row 1: Security Level Radio Buttons ---
        SettingsItemRow(
          label: widget.radioLabel,
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

        // --- Logic Block: Passcode UI ---
        if (_securityLevel == 1) ...<Widget>[
          const SizedBox(height: 10),

          // Case A: First time setup (No passcode set)
          if (!_isPasscodeSet)
            SettingsItemRow(
              label: "Setup passcode",
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
                    text: "Save",
                    onTap: () {
                      if (_setupController.text.isNotEmpty) {
                        setState(() {
                          _isPasscodeSet = true;
                        });
                      }
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
              label: widget.passcodeLabel,
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

          // Case C: Change Passcode Flow
          if (_isPasscodeSet && _isChangingPasscode) ...<Widget>[
            const SizedBox(height: 10),
            SettingsItemRow(
              label: "New passcode",
              child: Row(
                children: <Widget>[
                  PasscodeInputField(controller: _newPasscodeController),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SettingsItemRow(
              label: "Confirm passcode",
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
      ],
    );
  }
}
