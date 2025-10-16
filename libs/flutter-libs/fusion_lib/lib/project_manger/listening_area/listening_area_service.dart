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
    final existingFloor = relationships.getParent(RelationshipType.floorListening, area.id);

    if (existingFloor != null) {
      if (!overwriteIfLinked) {
        throw Exception('ListeningArea ${area.id} is already linked to floor $existingFloor');
      } else {
        // unlink previous relationship (move)
        relationships.unlink(RelationshipType.floorListening, existingFloor, area.id);
      }
    }

    // Add to repo and create the single floor relationship
    listeningAreas.add(area.id, area);

    final floor = floors.get(floorId);

    if (floor != null) {
      // remove id if present
      floor.listeningAreaIds.add(area.id);
    }
    relationships.link(RelationshipType.floorListening, floorId, area.id);
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
    final floorParentId = relationships.getParent(RelationshipType.floorListening, listeningAreaId);

    // copy zone parents into a list (avoid iterating underlying Set while mutating)
    final zoneParentId = relationships.getParent(RelationshipType.zoneListening, listeningAreaId);

    // copy hardware children
    final hardwareChildren = relationships.getChildren(RelationshipType.hardwareLocation, listeningAreaId).toList();

    // 2) Update the floor model (there is at most one floor per your constraint)
    if (floorParentId != null) {
      final floor = floors.get(floorParentId);
      if (floor != null) {
        // remove id if present
        floor.listeningAreaIds.remove(listeningAreaId);
      }
      // unlink this relationship explicitly
      relationships.unlink(RelationshipType.floorListening, floorParentId, listeningAreaId);
    }

    // 3) Update each zone that referenced this listening area
    if (zoneParentId != null) {
      final zone = zones.get(zoneParentId);
      if (zone != null) {
        zone.listeningAreasIds.remove(listeningAreaId);
      }
      // explicitly unlink in RelationshipManager
      relationships.unlink(RelationshipType.zoneListening, zoneParentId, listeningAreaId);
    }

    // 4) Update hardware components that referenced this listening area
    for (final hwId in hardwareChildren) {
      debugPrint("Removing ListeningArea $listeningAreaId from Hardware $hwId");
      final hw = hardware.get(hwId);
      if (hw != null) {
        // create a replacement HardwareComponent with cleared locationEntity
        final newLocation = hw.locationEntity.clearListeningArea();

        final newHw = hw.copyWith(
          locationEntity: newLocation,
        );
        // replace in repo
        hardware.add(newHw.id, newHw);
      }
      // unlink hardware relation
      relationships.unlink(RelationshipType.hardwareLocation, hwId, listeningAreaId);

      // If need to also remove hardware entirely on delete of Listening area, uncomment:
      // removeHardware(hwId);
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
    final areaIds = relationships.getChildren(RelationshipType.floorListening, floorId);

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

    final zone = zones.get(zoneId)!;

    // 1️⃣ Find current zones where this ListeningArea exists
    final currentZones = relationships
        .getParents(
          RelationshipType.zoneListening,
          listeningAreaId,
        )
        .toList();

    // 2️⃣ If already in the same zone, ensure model is updated and return
    if (currentZones.contains(zoneId)) {
      return;
    }

    // 3️⃣ Remove from any old zones first (cleanup old zone links)
    for (final oldZoneId in currentZones) {
      removeListeningAreaFromZone(listeningAreaId, oldZoneId);
    }

    // 5️⃣ Update target zone model
    if (!zone.listeningAreasIds.contains(listeningAreaId)) {
      zone.listeningAreasIds.add(listeningAreaId);
    }
    zones.add(zone.id, zone);

    relationships.link(RelationshipType.zoneListening, zoneId, listeningAreaId);
  }

  /// Remove ListeningArea from Zone, cleaning circuits + hardware references
  void removeListeningAreaFromZone(String listeningAreaId, String zoneId) {
    if (!listeningAreas.exists(listeningAreaId)) return;
    if (!zones.exists(zoneId)) return;

    final zone = zones.get(zoneId)!;

    // 1️⃣ If the zone doesn’t actually include this LA, skip
    if (!zone.listeningAreasIds.contains(listeningAreaId)) return;

    final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, zoneId);

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
        removeCircuitFromZone(cId, zoneId);
      }
    }

    // 3️⃣ Unlink listening area from zone
    relationships.unlink(RelationshipType.zoneListening, zoneId, listeningAreaId);

    // 4️⃣ Update zone model
    zone.listeningAreasIds.remove(listeningAreaId);
    zones.add(zone.id, zone);
  }

  FloorModel? getFloorForListeningArea(String listeningAreaId) {
    final floorId = relationships.getParent(RelationshipType.floorListening, listeningAreaId);
    return floorId != null ? floors.get(floorId) : null;
  }

  List<Zone> getZonesForListeningArea(String listeningAreaId) {
    final zoneIds = relationships.getParents(RelationshipType.zoneListening, listeningAreaId);
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
}
