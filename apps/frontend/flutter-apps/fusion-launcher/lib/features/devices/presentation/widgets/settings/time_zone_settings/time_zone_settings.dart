import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_settings_header.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:intl/intl.dart';

import '../../../../../authentication/launcher_sign_in_page.dart';
import '../network_dropdown.dart';

class TimezoneSettingsPage extends StatefulWidget {
  const TimezoneSettingsPage({super.key});

  @override
  State<TimezoneSettingsPage> createState() => _TimezoneSettingsPageState();
}

class _TimezoneSettingsPageState extends State<TimezoneSettingsPage> {
  // State variables
  final bool _isDaylightSaving = true;
  final TextEditingController _serverController = TextEditingController(text: "com.server.time.org");
  final TextEditingController _dateAndTimeController = TextEditingController(text: "");

  @override
  void dispose() {
    _serverController.dispose();
    _dateAndTimeController.dispose();
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

          SettingsItemRow(
            label: "Set date and time automatically",
            child: FusionSwitch(
              height: 22,
              width: 36,
              value: false,
              onChanged: (bool value) {},
            ),
          ),
          const SizedBox(height: 10),

          SettingsItemRow(
            label: "Source",
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 300,
                  child: NeumorphicDarkTextField(
                    hintText: 'http://com.server.time.org',
                    controller: _serverController,
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
                  textStyle: context.textTheme.labelMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
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
              ],
            ),
          ),

          const SizedBox(height: 10),

          SettingsItemRow(
            label: "Date and Time",
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 300,
                  child: InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null && context.mounted) {
                        // Time Picker
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          final DateTime finalDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );

                          //format the dat to the format "Feb 9, 2026; 7:20PM"
                          _dateAndTimeController.text = DateFormat('MMM d, yyyy; h:mm a').format(finalDateTime);
                        }
                      }
                    },
                    child: NeumorphicDarkTextField(
                      hintText: 'Feb 9, 2026; 7:20PM',
                      controller: _dateAndTimeController,
                      enabled: false,
                      borderRadius: 8,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FusionNeumorphicButton(
                  borderRadius: 6,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                  margin: EdgeInsets.zero,
                  text: "Set",
                  onTap: () {},
                  enabled: _dateAndTimeController.text.isNotEmpty,
                  textStyle: context.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
