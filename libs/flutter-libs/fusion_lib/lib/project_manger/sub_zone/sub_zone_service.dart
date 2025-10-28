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

    //remove all the circuits in the subzone
    final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, subZoneId);

    // Create a copy to avoid concurrent modification during iteration
    final circuitIdsCopy = List<String>.from(circuitIds);
    for (final cId in circuitIdsCopy) {
      removeCircuit(cId);
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
  void addSubZoneToZone(String subZoneId, String zoneId) {
    if (!zones.exists(zoneId)) throw Exception('Zone $zoneId not found');
    if (!subZones.exists(subZoneId)) throw Exception('Sub Zone $subZoneId not found');

    // Update relationship graph (idempotent)
    relationships.link(RelationshipType.zoneSubZones, zoneId, subZoneId);
  }

  //remove sub zone
  void removeSubZoneFromZone(String subZoneId, String zoneId) {
    if (!zones.exists(zoneId)) return;

    //On remove we will directly delete the subzone now
    removeSubZone(subZoneId);

    // if we want to keep the subzone but just unlink it from the zone

    // relationships.unlink(RelationshipType.zoneSubZones, zoneId, subZoneId);
  }

  /// returns all the SubZones linked to the given zoneId
  List<SubZone> getSubZones(String zoneId) {
    final subZoneIds = relationships.getChildren(RelationshipType.zoneSubZones, zoneId);
    return subZoneIds.map((id) => subZones.get(id)).where((m) => m != null).cast<SubZone>().toList();
  }

  void addCircuitToSubZone(String subZoneId, String circuitId) {
    if (!subZones.exists(subZoneId)) throw Exception('Sub Zone $subZoneId not found');
    if (!circuits.exists(circuitId)) throw Exception('Circuit $circuitId not found');

    // Update relationship graph (idempotent)
    relationships.link(RelationshipType.zoneCircuits, subZoneId, circuitId);
  }

  void removeCircuitFromSubZone(String subZoneId, String circuitId) {
    if (!subZones.exists(subZoneId)) return;

    relationships.unlink(RelationshipType.zoneCircuits, subZoneId, circuitId);
  }

  //add Listening area to sub zone
  void addListeningAreaToSubZone(String listeningAreaId, String subZoneId) {
    //check if subzone exists
    if (!subZones.exists(subZoneId)) {
      throw Exception('SubZone $subZoneId not found');
    }

    //check if listening area exists
    if (!listeningAreas.exists(listeningAreaId)) {
      throw Exception('ListeningArea $listeningAreaId not found');
    }

    final currentAreas = relationships.getChildren(RelationshipType.zoneAreas, subZoneId);
    if (currentAreas.contains(listeningAreaId)) {
      // Already linked; no-op
      return;
    }

    // Find current zones where this ListeningArea exists
    final currentZone = relationships
        .getParents(
          RelationshipType.zoneAreas,
          listeningAreaId,
        )
        .toList();

    //  Remove from any old zones first (cleanup old zone links)
    final currentZoneCopy = List<String>.from(currentZone);
    for (final oldZoneId in currentZoneCopy) {
      //check if its a zone or subzone
      if (zones.exists(oldZoneId)) {
        removeListeningAreaFromZone(listeningAreaId, oldZoneId);
      } else if (subZones.exists(oldZoneId)) {
        removeListeningAreaFromSubZone(listeningAreaId, oldZoneId);
      }
    }

    relationships.link(RelationshipType.zoneAreas, subZoneId, listeningAreaId);
  }

  //remove Listening area from sub zone
  void removeListeningAreaFromSubZone(String listeningAreaId, String subZoneId) {
    //check if subzone exists
    if (!subZones.exists(subZoneId)) {
      throw Exception('SubZone $subZoneId not found');
    }

    //check if listening area exists
    if (!listeningAreas.exists(listeningAreaId)) {
      throw Exception('ListeningArea $listeningAreaId not found');
    }

    final subZoneListeningAreas = relationships.getChildren(RelationshipType.zoneAreas, subZoneId);

    //if listening area id is not in subzone listening areas, return
    if (!subZoneListeningAreas.contains(listeningAreaId)) {
      return;
    }

    final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, subZoneId);

    List<String> circuitIdsToRemove = [];

    for (final cId in circuitIds) {
      final hardwareInCircuit = relationships.getChildren(RelationshipType.circuitHardware, cId);

      final hardwareInArea = hardwareInCircuit
          .map((hwId) => hardware.get(hwId))
          .whereType<HardwareComponent>()
          .where((hw) => hw.locationEntity.listeningAreaId == listeningAreaId)
          .toList();

      // Unlink hardware
      for (final hw in hardwareInArea) {
        relationships.unlink(RelationshipType.circuitHardware, cId, hw.id);
      }

      // If the circuit now has no hardware or LAs, delete it
      final remainingHW = relationships.getChildren(RelationshipType.circuitHardware, cId);
      if (remainingHW.isEmpty) {
        circuitIdsToRemove.add(cId);
      }
    }

    //remove empty circuits
    for (final cId in circuitIdsToRemove) {
      removeCircuit(cId);
    }

    //unlink relationship
    relationships.unlink(RelationshipType.zoneAreas, subZoneId, listeningAreaId);
  }

  List<ListeningArea> getListeningAreasInSubZone(String subZoneId) {
    if (!subZones.exists(subZoneId)) {
      throw Exception('SubZone with id $subZoneId does not exist');
    }
    final areaIds = relationships.getChildren(RelationshipType.zoneAreas, subZoneId);
    final areas = areaIds.map((id) => listeningAreas.get(id)).whereType<ListeningArea>().toList();
    return areas;
  }

  void reOrderSubZonesInZone(String parentId, int oldIndex, int newIndex) {
    final subZonesInZone = relationships.getChildren(RelationshipType.zoneSubZones, parentId).toList();

    final item = subZonesInZone.removeAt(oldIndex);
    subZonesInZone.insert(newIndex, item);

    relationships.reOrder(RelationshipType.zoneSubZones, parentId, subZonesInZone);
  }

  Zone getZoneForSubZone({required String subZoneId}) {
    final zoneIds = relationships.getParent(RelationshipType.zoneSubZones, subZoneId);
    if (zoneIds == null) throw Exception('SubZone does not have parent zone');
    return zones.get(zoneIds)!;
  }
}
