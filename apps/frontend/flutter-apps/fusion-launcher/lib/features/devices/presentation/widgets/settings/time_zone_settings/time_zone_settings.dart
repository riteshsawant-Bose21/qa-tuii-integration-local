import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/labeled_switch.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_settings_header.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../authentication/launcher_sign_in_page.dart';
import '../network_dropdown.dart';

class TimezoneSettingsPage extends StatefulWidget {
  const TimezoneSettingsPage({super.key});

  @override
  State<TimezoneSettingsPage> createState() => _TimezoneSettingsPageState();
}

class _TimezoneSettingsPageState extends State<TimezoneSettingsPage> {
  // State variables
  bool _isDaylightSaving = true;
  bool _isNtpEnabled = true;
  final TextEditingController _serverController = TextEditingController(text: "com.server.time.org");

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  List<TimeZoneModel> get timeZoneName {
    return TimeZoneModel.getAllTimeZones();
  }

  TimeZoneModel? _selectedTimeZone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          const NetworkSettingsHeader(
            title: "TIMEZONE & CLOCK",
          ),

          // Row 1: TimeZone Selection
          SettingsItemRow(
            label: "TimeZone",
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 300,
                  child: NetworkDropdown<TimeZoneModel>(
                    items: timeZoneName,
                    selectedValue: _selectedTimeZone,
                    placeholder: "Select Timezone",
                    labelBuilder: (TimeZoneModel tz) {
                      //conmobine tz name and offset
                      return tz.displayName;
                    },
                    onChanged: (TimeZoneModel? tz) {
                      setState(() {
                        _selectedTimeZone = tz;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 24),
                LabeledSwitch(
                  label: "Daylight saving",
                  value: _isDaylightSaving,
                  onChanged: (bool v) => setState(() => _isDaylightSaving = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Row 2: NTP Server Settings
          SettingsItemRow(
            label: "NTP Server",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // NTP Switch
                LabeledSwitch(
                  label: "NTP",
                  value: _isNtpEnabled,
                  onChanged: (bool v) => setState(() => _isNtpEnabled = v),
                ),

                const SizedBox(height: 12),

                // Server Input and Test Button
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 300,
                      child: NeumorphicDarkTextField(
                        hintText: 'http://com.server.time.org',
                        controller: _serverController,
                        enabled: _isNtpEnabled,
                        borderRadius: 8,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FusionNeumorphicButton(
                      borderRadius: 6,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                      margin: EdgeInsets.zero,
                      text: "Test",
                      onTap: () {},
                      enabled: _isNtpEnabled,
                      textStyle: context.textTheme.labelMedium?.copyWith(
                        color: _isNtpEnabled ? context.colorScheme.textPrimary : context.colorScheme.textDisabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
