import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

class SchematicHardwareComponent<T extends HardwareComponent> {
  final T hardware;
  final String? zoneName;
  final Color? zoneColor;
  final String? locationName;
  final String? equipmentLocationName;
  SchematicHardwareComponent({
    required this.hardware,
    this.zoneName,
    this.zoneColor,
    this.locationName,
    this.equipmentLocationName,
  });
}
