import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'gpio_usage_row.dart';
import 'section_divider.dart';

class ControlIOSection extends StatelessWidget {
  final HardwareComponent hardwareComponent;

  const ControlIOSection({
    super.key,
    required this.hardwareComponent,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        GpioUsageRow(name: "GPIO 1", isActive: true, type: "In"),
        SectionDivider(),
        GpioUsageRow(name: "GPIO 2", isActive: true, type: "In"),
        SectionDivider(),
        GpioUsageRow(name: "GPIO 4", isActive: true, type: "Out"),
        SectionDivider(),
        GpioUsageRow(name: "GPIO 3", isActive: false, type: "In"),
      ],
    );
  }
}
