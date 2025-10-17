import 'package:fusion_lib/fusion_lib.dart';

extension SubZoneService on ProjectService {
  void addSubZone(SubZone subZone) {
    if (subZones.exists(subZone.id)) {
      throw Exception('SubZone with id ${subZone.id} already exists');
    }

    subZones.add(subZone.id, subZone);
  }

  SubZone? getSubZoneById(String id) {
    return subZones.get(id);
  }

  void removeSubZone(String subZoneId) {
    if (!subZones.exists(subZoneId)) {
      throw Exception('SubZone with id $subZoneId does not exist');
    }
    // Remove all relationships
    relationships.removeAllRelationships(subZoneId);
    // Remove the subzone
    subZones.remove(subZoneId);
  }

  void updateSubZone(SubZone subZone) {
    if (!subZones.exists(subZone.id)) {
      throw Exception('SubZone with id ${subZone.id} does not exist');
    }

    // Update the subzone
    subZones.add(subZone.id, subZone);
  }

  List<SubZone> getAllSubZones() {
    return subZones.getAll();
  }

  List<HardwareComponent> getHardwareForSubZone(String subZoneId) {
    if (!subZones.exists(subZoneId)) {
      throw Exception('SubZone with id $subZoneId does not exist');
    }
    final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, subZoneId);
    final hardwareIds = <String>{};
    for (final cId in circuitIds) {
      hardwareIds.addAll(relationships.getChildren(RelationshipType.circuitHardware, cId));
    }
    return hardwareIds.map((id) => hardware.get(id)).whereType<HardwareComponent>().toList();
  }

  //add sub zone
  void addSubZoneToZone(String zoneId, String subZoneId) {
    if (!zones.exists(zoneId)) throw Exception('Zone $zoneId not found');
    if (!subZones.exists(subZoneId)) throw Exception('Sub Zone $subZoneId not found');

    final zone = zones.get(zoneId)!;
    if (!zone.subZones.contains(subZoneId)) {
      zone.subZones.add(subZoneId);
    }

    // Update relationship graph (idempotent)
    relationships.link(RelationshipType.zoneSubZones, zoneId, subZoneId);
  }

  //remove sub zone
  void removeSubZoneFromZone(String zoneId, String subZoneId) {
    if (!zones.exists(zoneId)) return;

    final zone = zones.get(zoneId)!;
    zone.subZones.remove(subZoneId);
    zones.add(zone.id, zone);

    relationships.unlink(RelationshipType.zoneSubZones, zoneId, subZoneId);
  }

  /// returns all the SubZones linked to the given zoneId
  List<SubZone> getSubZones(String zoneId) {
    final subZoneIds = relationships.getChildren(RelationshipType.zoneSubZones, zoneId);
    return subZoneIds.map((id) => subZones.get(id)).where((m) => m != null).cast<SubZone>().toList();
  }

  void addCircuitToSubZone(String subZoneId, String circuitId) {
    if (!subZones.exists(subZoneId)) throw Exception('Sub Zone $subZoneId not found');
    if (!circuits.exists(circuitId)) throw Exception('Circuit $circuitId not found');

    final subZone = subZones.get(subZoneId)!;
    if (!subZone.circuits.contains(circuitId)) {
      subZone.circuits.add(circuitId);
    }

    // Update relationship graph (idempotent)
    relationships.link(RelationshipType.zoneCircuits, subZoneId, circuitId);
  }

  void removeCircuitFromSubZone(String subZoneId, String circuitId) {
    if (!subZones.exists(subZoneId)) return;

    final subZone = subZones.get(subZoneId)!;
    subZone.circuits.remove(circuitId);
    subZones.add(subZone.id, subZone);

    relationships.unlink(RelationshipType.zoneCircuits, subZoneId, circuitId);
  }
}
