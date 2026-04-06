import 'package:fusion_lib/fusion_lib.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';

class WiringZoneManager {
  final List<Zone> zones = <Zone>[];

  final Map<String, List<SubZone>> subZonesByZoneId = <String, List<SubZone>>{};

  final Map<String, List<CircuitModel>> zoneCircuits = <String, List<CircuitModel>>{};
  final Map<String, List<CircuitModel>> subZoneCircuits = <String, List<CircuitModel>>{};

  final Map<String, List<HardwareComponent>> hardwareComponentsByCircuitId = <String, List<HardwareComponent>>{};

  void syncWithProjectManager(ProjectViewModel projectManager) {
    final List<Zone> updatedZones = projectManager.getAllZones();
    zones
      ..clear()
      ..addAll(updatedZones);

    for (final Zone zone in zones) {
      final List<SubZone> subZones = projectManager.getSubZonesForZone(parentZoneId: zone.id);
      subZonesByZoneId[zone.id] = subZones;

      final List<CircuitModel> circuitsInZone = projectManager.getCircuitsInZone(zone.id);
      zoneCircuits[zone.id] = circuitsInZone;
      _cacheCircuitHardwareComponents(projectManager, circuitsInZone);

      for (final SubZone subZone in subZones) {
        final List<CircuitModel> circuitsInSubZone = projectManager.getCircuitsInSubZone(subZoneId: subZone.id);
        subZoneCircuits[subZone.id] = circuitsInSubZone;
        _cacheCircuitHardwareComponents(projectManager, circuitsInSubZone);
      }
    }
  }

  void _cacheCircuitHardwareComponents(ProjectViewModel projectManager, List<CircuitModel> circuits) {
    for (final CircuitModel circuit in circuits) {
      final List<HardwareComponent> hardwareComponents = projectManager.getHardwareForCircuit(circuitId: circuit.id);
      hardwareComponentsByCircuitId[circuit.id] = hardwareComponents;
    }
  }

  List<SubZone> getSubZonesForZone(String zoneId) {
    return subZonesByZoneId[zoneId] ?? <SubZone>[];
  }

  List<CircuitModel> getCircuitsInZone(String zoneId) {
    return zoneCircuits[zoneId] ?? <CircuitModel>[];
  }

  List<CircuitModel> getCircuitsInSubZone(String subZoneId) {
    return subZoneCircuits[subZoneId] ?? <CircuitModel>[];
  }

  List<HardwareComponent> getHardwareComponentsInCircuit(String circuitId) {
    return hardwareComponentsByCircuitId[circuitId] ?? <HardwareComponent>[];
  }
}
