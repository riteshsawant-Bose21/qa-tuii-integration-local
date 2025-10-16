import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ComponentDataFactory {
  static ComponentData fromHardware(HardwareComponent hardwareComponent) {
    return switch (hardwareComponent) {
      Speaker() => SpeakerComponentData.from(hardwareComponent),
      Source() => SourceComponentData.from(hardwareComponent),
      _ => DeviceSchematicComponentData.from(hardwareComponent),
    };
  }

  static ZoneComponentData fromZone(Zone zone) {
    return ZoneComponentData.from(zone);
  }
}
