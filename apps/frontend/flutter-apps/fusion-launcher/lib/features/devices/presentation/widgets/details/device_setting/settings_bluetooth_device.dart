import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../settings/settings_item_row.dart';

class SettingsBluetoothDevice extends StatelessWidget {
  final String name;

  const SettingsBluetoothDevice({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: SettingsItemRow(
        label: name,
        labelFlex: 3,
        child: Container(
          height: 40,
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colorScheme.elevation2),
            color: context.colorScheme.elevation2,
          ),
          child: Center(
            child: FusionAppText(
              text: "Not Connected",
              style: context.textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }
}
