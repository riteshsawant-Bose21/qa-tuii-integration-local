import '../../fusion_lib.dart';

extension ListeningAreaService on ProjectService {
  /// add a new Listening area
  void addListeningAreaToFloor(ListeningArea area, String floorId) {
    if (!floors.exists(floorId)) {
      throw Exception('Floor with id $floorId does not exist');
    }
    if (listeningAreas.exists(area.id)) {
      throw Exception('ListeningArea with id ${area.id} already exists');
    }
    listeningAreas.add(area.id, area);
    relationships.link(RelationshipType.floorListening, floorId, area.id);
  }

  /// remove listening area
  void removeListeningArea(String listeningAreaId) {
    if (!listeningAreas.exists(listeningAreaId)) {
      throw Exception('ListeningArea with id $listeningAreaId does not exist');
    }
    listeningAreas.remove(listeningAreaId);
    relationships.removeAllRelationships(listeningAreaId);
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
