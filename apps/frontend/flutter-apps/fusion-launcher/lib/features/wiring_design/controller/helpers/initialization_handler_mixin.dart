import 'package:fusion_launcher/features/wiring_design/dto/component_data.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../circuit_controller.dart';

extension InitializationHandlerMixin on CircuitController {
  void initialize() {
    final List<Zone> zones = projectManager.getAllZones();

    final Map<String, CircuitComponent> zoneComponent =
        <String, CircuitComponent>{};
    final Map<HardwareComponent, Zone> zoneMapping =
        <HardwareComponent, Zone>{};
    for (int i = 0; i < zones.length; i++) {
      final Zone zone = zones[i];
      final CircuitComponent component = CircuitComponent.from(
        _getZoneComponent(zone),
        null,
      );
      zoneComponent[zone.id] = component;
      addComponent(component);
      final List<HardwareComponent> hardwares = projectManager
          .getHardwareInZone(zone.id);
      for (final HardwareComponent element in hardwares) {
        zoneMapping[element] = zone;
      }
    }

    final List<HardwareComponent> components =
        projectManager.getAllHardwareComponents();

    for (int i = 0; i < components.length; i++) {
      final HardwareComponent component = components[i];
      CircuitComponent? parent;
      if (component is Speaker) {
        final Zone? zone = zoneMapping[component];
        parent = zoneComponent[zone?.id];
      }
      final CircuitComponent from = CircuitComponent.from(
        _getComponent(component),
        parent,
      );
      if (parent != null) {
        from.parent = parent;
        parent.children.add(from);
      }
      addComponent(
        from,
      );
    }
  }

  ComponentData _getComponent(HardwareComponent hardwareComponent) {
    return switch (hardwareComponent) {
      Speaker() => SpeakerComponentData.from(hardwareComponent),
      Source() => SourceComponentData.from(hardwareComponent),
      _ => DeviceSchematicComponentData.from(hardwareComponent),
    };
  }

  ZoneComponentData _getZoneComponent(Zone zone) {
    return ZoneComponentData.from(zone);
  }
}
