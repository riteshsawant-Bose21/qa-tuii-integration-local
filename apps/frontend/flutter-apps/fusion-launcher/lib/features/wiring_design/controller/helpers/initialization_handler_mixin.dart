import 'package:fusion_launcher/features/wiring_design/model/circuit_component.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/component_data.dart';
import '../../dto/factory.dart';
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
      final ZoneComponentData componentData = ComponentDataFactory.fromZone(
        zone,
      );
      final CircuitComponent component = CircuitComponent.from(
        componentData,
        null,
      );
      zoneComponent[zone.id] = component;

      componentDB.addComponent(component);
      componentDB.addComponentData(componentData);

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
      final ComponentData componentData = ComponentDataFactory.fromHardware(
        component,
      );
      final CircuitComponent from = CircuitComponent.from(
        componentData,
        parent,
      );

      if (parent != null) {
        from.parent = parent;
        parent.children.add(from);
      }

      componentDB.addComponent(from);
      componentDB.addComponentData(componentData);

      addComponent(
        from,
      );
    }
  }
}
