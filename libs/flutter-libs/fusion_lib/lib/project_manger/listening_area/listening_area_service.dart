import 'package:flutter/material.dart';

import '../../fusion_lib.dart';

extension ListeningAreaService on ProjectService {
  /// Add a listening area and link it to exactly one floor.
  /// Throws if:
  ///  - the listening area already exists in the repo, OR
  ///  - the floor does not exist, OR
  ///  - the listening area is already linked to a floor (prevents multi-floor).
  void addListeningArea(ListeningArea area, String floorId, {bool overwriteIfLinked = false}) {
    // Validate floor exists
    if (!floors.exists(floorId)) {
      throw Exception('Floor $floorId not found');
    }

    // If area exists as repo entry, you may want to throw or update. We throw here.
    if (listeningAreas.exists(area.id)) {
      throw Exception('ListeningArea ${area.id} already exists in repository');
    }

    // If the area is already linked to a floor (shouldn't be since we didn't store it yet),
    // guard against external data cases (e.g., when loading pre-linked objects).
    final existingFloor = relationships.getParent(RelationshipType.floorAreas, area.id);

    if (existingFloor != null) {
      if (!overwriteIfLinked) {
        throw Exception('ListeningArea ${area.id} is already linked to floor $existingFloor');
      } else {
        // unlink previous relationship (move)
        relationships.unlink(RelationshipType.floorAreas, existingFloor, area.id);
      }
    }

    // Add to repo and create the single floor relationship
    listeningAreas.add(area.id, area);

    relationships.link(RelationshipType.floorAreas, floorId, area.id);
  }

  /// Remove a listening area and keep everything consistent.
  ///
  /// - Reads referencing parents BEFORE removing the repo entry.
  /// - Iterates copies of relationship sets to avoid concurrent modification issues.
  /// - Unlinks relationships explicitly for each parent.
  /// - Updates FloorModel.listeningAreasId, Zone.listeningAreasIds, and Hardware.locationEntity
  ///   (handles both mutable and immutable hardware by replacing repo entries).
  /// - Finally removes remaining relationships defensively and removes the repo item.
  ///
  /// Behavior:
  /// - No-op if id doesn't exist (change to throw if you prefer).
  void removeListeningArea(
    String listeningAreaId, {
    bool throwOnMissing = false,
  }) {
    // 0) Early checks: must exist
    if (!listeningAreas.exists(listeningAreaId)) {
      if (throwOnMissing) {
        throw Exception('ListeningArea $listeningAreaId not found');
      }
      return; // idempotent no-op
    }

    // 1) Capture current parents BEFORE mutating relationships or deleting repo entry
    final floorParentId = relationships.getParent(RelationshipType.floorAreas, listeningAreaId);

    // copy zone parents into a list (avoid iterating underlying Set while mutating)
    final zoneParentId = relationships.getParent(RelationshipType.zoneAreas, listeningAreaId);

    // copy hardware children
    final hardwareChildren = relationships.getChildren(RelationshipType.hardwareLocation, listeningAreaId).toList();

    // 2) Update the floor model (there is at most one floor per your constraint)
    if (floorParentId != null) {
      // unlink this relationship explicitly
      relationships.unlink(RelationshipType.floorAreas, floorParentId, listeningAreaId);
    }

    // 3) Update each zone that referenced this listening area
    if (zoneParentId != null) {
      // explicitly unlink in RelationshipManager
      relationships.unlink(RelationshipType.zoneAreas, zoneParentId, listeningAreaId);
    }

    // 4) Remove hardware components that referenced this listening area
    for (final hwId in hardwareChildren) {
      // If need to also remove hardware entirely on delete of Listening area, uncomment:
      removeHardware(hwId);
    }

    // 5) Defensive cleanup: remove any other relationships that mention this entity
    relationships.removeAllRelationships(listeningAreaId);

    // 6) Finally remove the listening area from the repository
    listeningAreas.remove(listeningAreaId);
  }

  /// update listening area
  void updateListeningArea(ListeningArea area) {
    if (!listeningAreas.exists(area.id)) {
      throw Exception('ListeningArea with id ${area.id} does not exist');
    }
    listeningAreas.add(area.id, area);
  }

  /// Return all ListeningArea objects that belong to the given floorId.
  /// Uses RelationshipManager as the canonical index (fast, no full-scan).
  List<ListeningArea> getListeningAreasForFloor(String floorId) {
    // Optional: guard if floor doesn't exist
    if (!floors.exists(floorId)) return [];

    // get children IDs from relationship manager (O(1) for lookup of the parent entry)
    final areaIds = relationships.getChildren(RelationshipType.floorAreas, floorId);

    // resolve ids into objects, filter missing ones
    final areas = areaIds.map((id) => listeningAreas.get(id)).whereType<ListeningArea>().toList();

    return areas;
  }

  /// Assign a listening area to a zone.
  /// If the listening area is already part of some other zone(s), they will be removed first.
  /// This updates:
  ///  - RelationshipManager (zoneListening links),
  ///  - Zone.listeningAreasIds lists,
  ///  - Hardware.locationEntity.zoneId and hardwareLocation links (remove old zone links, add new).
  /// Add ListeningArea to Zone with full validation + circuit + cleanup support
  void addListeningAreaToZone(String listeningAreaId, String zoneId) {
    if (!listeningAreas.exists(listeningAreaId)) {
      throw Exception('ListeningArea $listeningAreaId not found');
    }
    if (!zones.exists(zoneId)) {
      throw Exception('Zone $zoneId not found');
    }

    final currentAreas = relationships.getChildren(RelationshipType.zoneAreas, zoneId);
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
      removeListeningAreaFromZone(listeningAreaId, oldZoneId);
    }

    relationships.link(RelationshipType.zoneAreas, zoneId, listeningAreaId);
  }

  /// Remove ListeningArea from Zone, cleaning circuits + hardware references
  void removeListeningAreaFromZone(String listeningAreaId, String zoneId) {
    if (!listeningAreas.exists(listeningAreaId)) return;
    if (!zones.exists(zoneId)) return;

    final zoneAreas = relationships.getChildren(RelationshipType.zoneAreas, zoneId);

    //If the zone doesn’t actually include this LA, skip
    if (!zoneAreas.contains(listeningAreaId)) return;

    final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, zoneId);

    List<String> circuitIdToRemove = [];

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
        circuitIdToRemove.add(cId);
      }
    }
    // Remove empty circuits
    for (final cId in circuitIdToRemove) {
      removeCircuit(cId);
    }

    // Unlink listening area from zone
    relationships.unlink(RelationshipType.zoneAreas, zoneId, listeningAreaId);

    final subZoneIds = relationships.getChildren(RelationshipType.zoneSubZones, zoneId);

    // Also remove from any subzones under this zone
    final subZoneIdsCopy = List<String>.from(subZoneIds);
    for (final subZoneId in subZoneIdsCopy) {
      removeListeningAreaFromSubZone(listeningAreaId, subZoneId);
    }
  }

  FloorModel? getFloorForListeningArea(String listeningAreaId) {
    final floorId = relationships.getParent(RelationshipType.floorAreas, listeningAreaId);
    return floorId != null ? floors.get(floorId) : null;
  }

  List<Zone> getZonesForListeningArea(String listeningAreaId) {
    final zoneIds = relationships.getParents(RelationshipType.zoneAreas, listeningAreaId);
    return zoneIds.map((id) => zones.get(id)).where((z) => z != null).cast<Zone>().toList();
  }

  //Get All Listening Areas in the project
  List<ListeningArea> getAllListeningAreas() {
    return listeningAreas.getAll();
  }

  // Get Listening Area by ID
  ListeningArea? getListeningAreaById(String areaId) {
    return listeningAreas.get(areaId);
  }

  //get Listing area available for zone, (ignore all listening area already assigned to other zones)
  List<ListeningArea> getAvailableListeningAreasForZone(String? zoneId) {
    Set<String> zoneAreas = {};

    if (zoneId != null) {
      zoneAreas = relationships.getChildren(RelationshipType.zoneAreas, zoneId).toSet();
    }

    //get all listening areas which are not added to any of zoneListening, (listening areas with empty parents )
    final availableAreas = listeningAreas.getAll().where((la) {
      final parentZones = relationships.getParents(RelationshipType.zoneAreas, la.id);
      return parentZones.isEmpty;
    }).toList();

    //return both zoneAreas and availableAreas
    return [
      ...zoneAreas.map((id) => listeningAreas.get(id)).whereType<ListeningArea>(),
      ...availableAreas,
    ];
  }

  //get Listing area available for zone, (ignore all listening area already assigned to other zones)
  List<ListeningArea> getAvailableListeningAreasForSubZone({String? subZoneId, required String parentZone}) {
    final zoneAreas = relationships.getChildren(RelationshipType.zoneAreas, parentZone).toSet();

    Set<String> subZoneAreas = {};
    if (subZoneId != null) {
      subZoneAreas = relationships.getChildren(RelationshipType.zoneAreas, subZoneId).toSet();
    }

    //get all listening areas which are not added to any of zones sub zones, (listening areas with only parent zone  )
    final availableAreas = zoneAreas.where((la) {
      final parentZones = relationships.getParents(RelationshipType.zoneAreas, la);
      //check if parentZones contains only main parentZone
      return parentZones.length == 1 && parentZones.contains(parentZone);
    }).toList();

    final allAreas = [
      ...subZoneAreas,
      ...availableAreas,
    ];

    //return both zoneAreas and availableAreas
    return [
      ...allAreas.map((id) => listeningAreas.get(id)).whereType<ListeningArea>(),
    ];
  }
}
