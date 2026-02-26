import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../../core/router/routes.dart';
import '../../../../../../core/service_locator.dart';
import '../../../../../authentication/launcher_sign_in_page.dart';
import '../../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../network_dropdown.dart';
import 'ptp_header.dart';

class PtpSettingsPage extends StatefulWidget {
  const PtpSettingsPage({super.key});

  @override
  State<PtpSettingsPage> createState() => _PtpSettingsPageState();
}

class _PtpSettingsPageState extends State<PtpSettingsPage> {
  bool _isDefault = true;

  final TextEditingController _syncIntervalController = TextEditingController(text: "1 secs");
  final TextEditingController _announceIntervalController = TextEditingController(text: "1 secs");

  @override
  void dispose() {
    _syncIntervalController.dispose();
    _announceIntervalController.dispose();
    super.dispose();
  }

  List<HardwareComponent> get _fusionDevices {
    // Combine DSPs, Amplifiers, and Controllers
    final List<HardwareComponent> dsp = serviceLocator<ProjectViewModel>().fusionDsps;
    final List<HardwareComponent> amplifiers = serviceLocator<ProjectViewModel>().amplifiers;
    final List<HardwareComponent> controllers = serviceLocator<ProjectViewModel>().fusionControllers;
    return <HardwareComponent>[...dsp, ...amplifiers, ...controllers];
  }

  final Map<String, String> _deviceModes = <String, String>{};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          PtpSettingsHeader(
            isDefault: _isDefault,
            onDefaultChanged: (bool v) => setState(() => _isDefault = v),
          ),

          const SizedBox(
            height: 20,
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SettingsItemRow(
                label: "Sync Interval",
                child: Row(
                  children: <Widget>[
                    NeumorphicDarkTextField(
                      controller: _syncIntervalController,
                      height: 30,
                      width: 300,
                      borderRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SettingsItemRow(
                label: "Announce Interval",
                child: Row(
                  children: <Widget>[
                    NeumorphicDarkTextField(
                      controller: _announceIntervalController,
                      height: 30,
                      width: 300,
                      borderRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          //Device table
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 0.6 * MediaQuery.of(context).size.width,
              ),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildDeviceTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTable() {
    return FusionTable(
      columns: const <FusionTableColumn>[
        FusionTableColumn(key: 'status', header: 'STATUS', flex: 1),
        FusionTableColumn(key: 'deviceName', header: 'DEVICE NAME', flex: 3),
        FusionTableColumn(key: 'priority1', header: 'Priority 1', flex: 2),
        FusionTableColumn(key: 'priority2', header: 'Priority 2', flex: 2),
        FusionTableColumn(key: 'mode', header: 'Mode', flex: 4),
      ],
      rows: _fusionDevices.map((HardwareComponent device) => _buildDeviceRow(device)).toList(),
    );
  }

  FusionTableRow _buildDeviceRow(HardwareComponent device) {
    final TextStyle cellStyle = TextStyle(
      color: context.colorScheme.textPrimary,
      fontSize: 13,
      overflow: TextOverflow.ellipsis,
    );

    final TextStyle greenLinkStyle = const TextStyle(
      color: Color(0xFF4CAF50),
      fontSize: 13,
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF4CAF50),
      overflow: TextOverflow.ellipsis,
    );

    final List<String> ptpModes = <String>[
      'Master',
      'Follower',
    ];

    return FusionTableRow(
      key: device.id,
      cells: <String, FusionTableCell>{
        'status': FusionTableCell(
          value: 1,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colorScheme.green,
            ),
          ),
        ),
        'deviceName': FusionTableCell(
          value: device.name,
          child: InkWell(
            onTap: () {
              if (device is! Amplifier || !device.hardwareName.toLowerCase().startsWith("pp")) {
                Navigator.pushNamed(
                  context,
                  Routes.deviceDetails,
                  arguments: device.id,
                );
              }
            },
            child: FusionAppText(text: device.name, style: greenLinkStyle, maxLine: 1),
          ),
        ),
        'priority1': FusionTableCell(
          value: "128",
          child: FusionAppText(text: "128", style: cellStyle, maxLine: 1),
        ),
        'priority2': FusionTableCell(
          value: "128",
          child: FusionAppText(text: "128", style: cellStyle, maxLine: 1),
        ),
        'mode': FusionTableCell(
          value: _deviceModes[device.id] ?? '--',
          child: NetworkDropdown<String>(
            items: ptpModes,
            selectedValue: _deviceModes[device.id],
            labelBuilder: (String s) => s,
            onChanged: (String? v) {
              if (v != null) {
                setState(() {
                  _deviceModes[device.id] = v;
                });
              }
            },
          ),
        ),
      },
      // DRAG & DROP LOGIC
    );
  }
}
