import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_header.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_port_form.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_section_container.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/labeled_switch.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_dropdown.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/settings_item_row.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../processing_block/view/processing_blocks/widgets/disabled_widget_wrapper.dart';

class NetworkSettingsWidget extends StatefulWidget {
  final bool showOnlyNetworkSettings;
  final bool poeEnabled;
  final ValueChanged<bool> onPoeChanged;
  final HardwareComponent device;

  const NetworkSettingsWidget({
    super.key,
    required this.showOnlyNetworkSettings,
    required this.poeEnabled,
    required this.onPoeChanged,
    required this.device,
  });

  @override
  State<NetworkSettingsWidget> createState() => _NetworkSettingsWidgetState();
}

class _NetworkSettingsWidgetState extends State<NetworkSettingsWidget> {
  late final TextEditingController _ipPri;
  late final TextEditingController _subPri;
  late final TextEditingController _gwPri;
  late final TextEditingController _macPri;
  late final TextEditingController _ipSec;
  late final TextEditingController _subSec;
  late final TextEditingController _gwSec;
  late final TextEditingController _macSec;

  @override
  void initState() {
    super.initState();
    _ipPri = TextEditingController(text: "192.168.0.4");
    _subPri = TextEditingController(text: "255.255.255.0");
    _gwPri = TextEditingController(text: "192.168.0.1");
    _macPri = TextEditingController(text: "12:1S:DN:67:26:33:23");
    _ipSec = TextEditingController(text: "192.168.1.5");
    _subSec = TextEditingController(text: "255.255.255.0");
    _gwSec = TextEditingController(text: "192.168.0.1");
    _macSec = TextEditingController(text: "12:1S:DN:67:26:33:24");
  }

  @override
  void dispose() {
    _ipPri.dispose();
    _subPri.dispose();
    _gwPri.dispose();
    _macPri.dispose();
    _ipSec.dispose();
    _subSec.dispose();
    _gwSec.dispose();
    _macSec.dispose();
    super.dispose();
  }

  String selectedNetworkMode = "Isolated";

  @override
  Widget build(BuildContext context) {
    return SettingsSectionContainer(
      title: "NETWORK (ETHERNET)",
      child: Column(
        children: <Widget>[
          if (!widget.showOnlyNetworkSettings) ...<Widget>[
            SettingsItemRow(
              label: "Network Mode",
              labelFlex: 3,
              child: NetworkDropdown<String>(
                items: const <String>[
                  "Isolated",
                  "Switched",
                ],
                selectedValue: selectedNetworkMode,
                labelBuilder: (String s) => s,
                onChanged: (String? v) {
                  if (v != null) {
                    setState(() => selectedNetworkMode = v);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Columns: Primary & Secondary Port
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- PRIMARY PORT ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SettingsHeader(title: "PRIMARY PORT"),
                  const SizedBox(height: 16),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: widget.showOnlyNetworkSettings ? 500 : double.infinity,
                    ),
                    child: SettingsPortForm(
                      isPrimary: true,
                      ipController: _ipPri,
                      subnetController: _subPri,
                      gatewayController: _gwPri,
                      macController: _macPri,
                      device: widget.device,
                    ),
                  ),
                ],
              ),

              if (!widget.showOnlyNetworkSettings) ...<Widget>[
                const SizedBox(height: 24),
                Divider(
                  color: context.colorScheme.elevation2,
                  thickness: 1,
                ),

                // --- SECONDARY PORT ---
                const SettingsHeader(title: "SECONDARY PORT"),
                const SizedBox(height: 10),
                SettingsItemRow(
                  label: "",
                  labelFlex: 3,
                  child: LabeledSwitch(
                    label: "POE",
                    switchHeight: 24,
                    switchWidth: 44,
                    value: widget.poeEnabled,
                    onChanged: widget.onPoeChanged,
                  ),
                ),

                const SizedBox(height: 10),
                DisabledWidgetWrapper(
                  isDisabled: selectedNetworkMode == "Switched",
                  child: SettingsPortForm(
                    isPrimary: false,
                    ipController: _ipSec,
                    subnetController: _subSec,
                    gatewayController: _gwSec,
                    macController: _macSec,
                    device: widget.device,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
