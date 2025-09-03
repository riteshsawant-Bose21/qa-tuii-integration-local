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
  void addListeningAreaToZone(String listeningAreaId, String zoneId) {
    if (!listeningAreas.exists(listeningAreaId)) {
      throw Exception('ListeningArea $listeningAreaId not found');
    }
    if (!zones.exists(zoneId)) {
      throw Exception('Zone $zoneId not found');
    }

    // 1) Find current parent zones (if any)
    final currentZones = relationships.getParents(RelationshipType.zoneListening, listeningAreaId).toList();

    // If already assigned exclusively to this zone and nothing else to remove, still ensure zone model contains it
    if (currentZones.length == 1 && currentZones.first == zoneId) {
      final targetZone = zones.get(zoneId);
      if (targetZone != null && !targetZone.listeningAreasIds.contains(listeningAreaId)) {
        targetZone.listeningAreasIds.add(listeningAreaId);
      }
      return; // already assigned — nothing else
    }

    // 2) Remove from any old zones (unlink relationships + update zone models, and fix hardware zone links)
    for (final oldZoneId in currentZones) {
      if (oldZoneId == zoneId) continue; // if same as target, skip removal
      // unlink relationship
      relationships.unlink(RelationshipType.zoneListening, oldZoneId, listeningAreaId);

      // update old zone model's listeningAreasIds
      final oldZone = zones.get(oldZoneId);
      if (oldZone != null) {
        oldZone.listeningAreasIds.remove(listeningAreaId);
      }

      // For hardware placed in this listening area, if their location's zoneId was oldZoneId,
      // clear it and remove the hardware-location link to the old zone.
      final hwIdsInLA = relationships.getChildren(RelationshipType.hardwareLocation, listeningAreaId);
      for (final hwId in hwIdsInLA) {
        final hw = hardware.get(hwId);
        if (hw != null && hw.locationEntity.zoneId == oldZoneId) {
          hw.locationEntity.zoneId = null;
          relationships.unlink(RelationshipType.hardwareLocation, oldZoneId, hwId);
        }
      }
    }

    // 3) Now link to the new zone (idempotent)
    relationships.link(RelationshipType.zoneListening, zoneId, listeningAreaId);

    // Update target zone model list
    final targetZone = zones.get(zoneId);
    if (targetZone != null && !targetZone.listeningAreasIds.contains(listeningAreaId)) {
      targetZone.listeningAreasIds.add(listeningAreaId);
    }

    // 4) Ensure hardware placed in this listening area are linked to the new zone and update their LocationModel.zoneId
    final hwIds = relationships.getChildren(RelationshipType.hardwareLocation, listeningAreaId);
    for (final hwId in hwIds) {
      final hw = hardware.get(hwId);
      if (hw == null) continue;

      // Set hw.locationEntity.zoneId to the new zone
      hw.locationEntity.zoneId = zoneId;

      // Link hardwareLocation: zone -> hardware
      relationships.link(RelationshipType.hardwareLocation, zoneId, hwId);
    }
  }

  /// Remove a listening area from a zone.
  /// Also clears hardware.zoneId and hardwareLocation link for hardware that were connected to this zone via that LA.
  void removeListeningAreaFromZone(String listeningAreaId, String zoneId) {
    if (!listeningAreas.exists(listeningAreaId)) return;
    if (!zones.exists(zoneId)) return;

    // If the relationship doesn't exist, nothing to do
    final children = relationships.getChildren(RelationshipType.zoneListening, zoneId);
    if (!children.contains(listeningAreaId)) return;

    // Unlink relationship and update zone model
    relationships.unlink(RelationshipType.zoneListening, zoneId, listeningAreaId);
    final zone = zones.get(zoneId);
    if (zone != null) {
      zone.listeningAreasIds.remove(listeningAreaId);
    }

    // For hardware located in this listening area, if their LocationModel.zoneId equals this zone,
    // clear it and unlink the hardwareLocation relationship between the zone and hardware.
    final hwIds = relationships.getChildren(RelationshipType.hardwareLocation, listeningAreaId);
    for (final hwId in hwIds) {
      final hw = hardware.get(hwId);
      if (hw == null) continue;
      if (hw.locationEntity.zoneId == zoneId) {
        hw.locationEntity.zoneId = null;
        relationships.unlink(RelationshipType.hardwareLocation, zoneId, hwId);
      }
    }

    // done (optionally call persistence/notification hook)
    // onChangeCallback?.call();
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
