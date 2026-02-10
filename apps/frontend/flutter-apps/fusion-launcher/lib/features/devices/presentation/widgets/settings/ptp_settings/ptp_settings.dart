import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_dropdown.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../authentication/launcher_sign_in_page.dart';
import 'ptp_header.dart';

class PtpSettingsPage extends StatefulWidget {
  const PtpSettingsPage({super.key});

  @override
  State<PtpSettingsPage> createState() => _PtpSettingsPageState();
}

class _PtpSettingsPageState extends State<PtpSettingsPage> {
  bool _isDefault = true;
  String _selectedMode = "Automatic";

  final List<String> _ptpModes = <String>[
    "Automatic",
    "Master",
    "Follower/Slave",
    "Disabled",
  ];

  final TextEditingController _priority1Controller = TextEditingController(text: "128");
  final TextEditingController _priority2Controller = TextEditingController(text: "128");
  final TextEditingController _syncIntervalController = TextEditingController(text: "1 secs");
  final TextEditingController _announceIntervalController = TextEditingController(text: "1 secs");

  @override
  void dispose() {
    _priority1Controller.dispose();
    _priority2Controller.dispose();
    _syncIntervalController.dispose();
    _announceIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          PtpSettingsHeader(
            isDefault: _isDefault,
            onDefaultChanged: (bool v) => setState(() => _isDefault = v),
          ),

          // Row 1: Mode Dropdown (Spans full width relative to its column)
          // Since "Mode" is above the columns in the image, we treat it as a full row
          // BUT looking closely at image dcd046.png, "Mode" is part of the LEFT column logic visually.
          // However, the vertical divider starts *after* the header line.
          // Let's create the two-column structure now.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- LEFT COLUMN ---
              Expanded(
                child: Column(
                  children: <Widget>[
                    SettingsItemRow(
                      label: "Mode",
                      child: NetworkDropdown<String>(
                        items: _ptpModes,
                        selectedValue: _selectedMode,
                        labelBuilder: (String s) => s,
                        onChanged: (String? v) {
                          if (v != null) setState(() => _selectedMode = v);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsItemRow(
                      label: "Priority 1",
                      child: NeumorphicDarkTextField(
                        controller: _priority1Controller,
                        height: 30,
                        borderRadius: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsItemRow(
                      label: "Priority 2",
                      child: NeumorphicDarkTextField(
                        controller: _priority2Controller,
                        height: 30,
                        borderRadius: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // --- VERTICAL DIVIDER ---
              Container(
                height: 120, // Height to match roughly the 3 rows
                width: 1,
                color: context.colorScheme.elevation2,
              ),

              const SizedBox(width: 24),

              // --- RIGHT COLUMN ---
              Expanded(
                child: Column(
                  children: <Widget>[
                    // The right column starts aligned with Priority 1 visually,
                    // skipping the "Mode" row height.
                    // To align perfectly, we can add a sized box or just start the rows.
                    // Image shows "Sync Interval" aligned with "Priority 1".
                    const SizedBox(height: 48), // Spacer to offset "Mode" row height approx

                    SettingsItemRow(
                      label: "Sync Interval",
                      child: NeumorphicDarkTextField(
                        controller: _syncIntervalController,
                        height: 30,
                        borderRadius: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsItemRow(
                      label: "Announce Interval",
                      child: NeumorphicDarkTextField(
                        controller: _announceIntervalController,
                        height: 30,
                        borderRadius: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
