import 'package:fusion_lib/fusion_lib.dart';

extension HardwareService on ProjectService {
  /// Add hardware component into repo; create relationships based on its LocationModel.
  void addHardware(HardwareComponent hw) {
    if (hardware.exists(hw.id)) {
      throw Exception('Hardware ${hw.id} already exists');
    }

    hardware.add(hw.id, hw);

    // Link to the relevant parent(s). Use hardwareLocation relationship type.
    final loc = hw.locationEntity;
    if (loc.floorId != null) {
      relationships.link(RelationshipType.hardwareLocation, loc.floorId!, hw.id);
    }

    if (loc.listeningAreaId != null) {
      relationships.link(RelationshipType.hardwareLocation, loc.listeningAreaId!, hw.id);
    }
    // Optional persistence/notification hook
    // _onProjectChanged();
  }

  Zone? getZoneForHardware(String hardwareId) {
    final hw = hardware.get(hardwareId);
    if (hw == null) throw Exception('Hardware $hardwareId not found');
    final loc = hw.locationEntity;
    if (loc.listeningAreaId == null) {
      final laId = loc.listeningAreaId!;
      final parentZoneIds = relationships.getParents(RelationshipType.zoneListening, laId);
      if (parentZoneIds.isNotEmpty) {
        final zoneId = parentZoneIds.first;
        final zone = zones.get(zoneId);
        return zone;
      }
    }
    return null;
  }

  CircuitModel? getCircuitForHardware(String hardwareId) {
    final circuitIds = relationships.getParents(RelationshipType.circuitHardware, hardwareId);
    if (circuitIds.isNotEmpty) {
      final circuitId = circuitIds.first;
      final circuit = circuits.get(circuitId);
      return circuit;
    }
    return null;
  }

  /// Remove hardware and all relationships to/from it.
  void removeHardware(String hardwareId) {
    if (!hardware.exists(hardwareId)) return;

    // Remove relationship links
    relationships.removeAllRelationships(hardwareId);

    // Remove repo entry
    hardware.remove(hardwareId);

    // Optional persistence/notification hook
    // _onProjectChanged();
  }

  /// Update hardware component in repo.
  void updateHardware(HardwareComponent hw) {
    if (!hardware.exists(hw.id)) {
      throw Exception('Hardware ${hw.id} does not exist');
    }
    hardware.add(hw.id, hw);
  }

  /// Move hardware to a listening area or to a floor.
  ///
  /// If `listeningAreaId` is provided it will be used. If only `floorId` is provided,
  /// the hardware will be associated to the floor (no listening area / zone).
  ///
  /// Behavior:
  ///  - Removes existing hardwareLocation links (zone/LA/floor) for this hardware.
  ///  - Updates hardware.locationEntity.{zoneId, listeningAreaId, floorId}.
  ///  - Adds new hardwareLocation links for floor, listeningArea, and inferred zone (if any).
  //todo: Update this method to support Circuits
  void moveHardware(String hardwareId, {String? listeningAreaId, String? floorId}) {
    // Validation

    if (listeningAreaId == null && floorId == null) {
      throw ArgumentError('Either listeningAreaId or floorId must be provided');
    }

    final hw = hardware.get(hardwareId);
    if (hw == null) throw Exception('Hardware $hardwareId not found');

    if (hw.lockListeningArea) {
      throw Exception('Hardware $hardwareId is locked to its current listening area and cannot be moved.');
    }

    final loc = hw.locationEntity;

    // 1) Remove existing hardwareLocation links (move semantics)
    final prevParents = relationships.getParents(RelationshipType.hardwareLocation, hardwareId).toList();
    for (final parentId in prevParents) {
      relationships.unlink(RelationshipType.hardwareLocation, parentId, hardwareId);
    }

    // 2) Clear existing location fields (we will populate new ones)
    loc.listeningAreaId = null;
    loc.floorId = null;

    // 3) If moving to a listening area
    if (listeningAreaId != null) {
      if (!listeningAreas.exists(listeningAreaId)) {
        throw Exception('ListeningArea $listeningAreaId not found');
      }

      // assign listening area
      loc.listeningAreaId = listeningAreaId;

      // link LA -> hardware
      relationships.link(RelationshipType.hardwareLocation, listeningAreaId, hardwareId);

      // infer and set floor if possible
      final inferredFloorId = relationships.getParent(RelationshipType.floorListening, listeningAreaId);
      if (inferredFloorId != null) {
        loc.floorId = inferredFloorId;
        relationships.link(RelationshipType.hardwareLocation, inferredFloorId, hardwareId);
      }

      // // if the listening area belongs to any zone(s), attach to the first one
      // final parentZoneIds = relationships.getParents(RelationshipType.zoneListening, listeningAreaId);
      // if (parentZoneIds.isNotEmpty) {
      //   final chosenZoneId = parentZoneIds.first;
      //   if (zones.exists(chosenZoneId)) {
      //     loc.zoneId = chosenZoneId;
      //     relationships.link(RelationshipType.hardwareLocation, chosenZoneId, hardwareId);
      //   } else {
      //     // if zone doesn't exist in repo, just ignore (but remove any dangling relation)
      //     relationships.unlink(RelationshipType.zoneListening, chosenZoneId, listeningAreaId);
      //   }
      // }
    } else if (floorId != null) {
      // 4) Moving to a floor only (no listening area, no zone)
      if (!floors.exists(floorId)) {
        throw Exception('Floor $floorId not found');
      }

      loc.floorId = floorId;
      relationships.link(RelationshipType.hardwareLocation, floorId, hardwareId);

      // listeningAreaId and zoneId remain null
    }

    // Optional: If you maintain any zone->hardware lists inside the zone model itself,
    // make sure to update them here (not shown because in our design we keep relationships
    // as the canonical source). If you do keep zone.model.hardwareIds, update them:
    //
    //  - Remove hardwareId from all zone.model.hardwareIds that previously contained it
    //  - Add hardwareId to chosen zone.model.hardwareIds (if loc.zoneId != null)
    //
    // Finally: persist / notify if you have such a hook:
    // _onProjectChanged();
  }

  // returns hardware objects directly (if some IDs were removed, filters nulls)
  List<HardwareComponent> getHardwareForFloorDirect(String floorId) {
    final ids = relationships.getChildren(RelationshipType.hardwareLocation, floorId);
    return ids.map((id) => hardware.get(id)).whereType<HardwareComponent>().toList();
  }

  List<HardwareComponent> getHardwareForListeningArea(String laId) {
    final ids = relationships.getChildren(RelationshipType.hardwareLocation, laId);
    return ids.map((id) => hardware.get(id)).whereType<HardwareComponent>().toList();
  }

  List<HardwareComponent> getHardwareInZone(String zoneId) {
    final ids = relationships.getChildren(RelationshipType.hardwareLocation, zoneId);
    return ids.map((id) => hardware.get(id)).whereType<HardwareComponent>().toList();
  }

  List<HardwareComponent> getAllHardwareInFloor(String floorId) {
    final Set<String> resultIds = {};

    // hardware directly linked to the floor
    resultIds.addAll(relationships.getChildren(RelationshipType.hardwareLocation, floorId));

    // all listening areas on this floor
    final laIds = relationships.getChildren(RelationshipType.floorListening, floorId);
    for (final laId in laIds) {
      resultIds.addAll(relationships.getChildren(RelationshipType.hardwareLocation, laId));

      // zones that include this listening area
      final zoneIds = relationships.getParents(RelationshipType.zoneListening, laId);
      for (final zoneId in zoneIds) {
        resultIds.addAll(relationships.getChildren(RelationshipType.hardwareLocation, zoneId));
      }
    }

    return resultIds.map((id) => hardware.get(id)).whereType<HardwareComponent>().toList();
  }

  // get Hardware by id
  HardwareComponent? getHardwareById(String hardwareId) {
    return hardware.get(hardwareId);
  }

  //Update location model
  void updateHardwareLocation(String hardwareId, LocationModel newLocation) {
    final hw = hardware.get(hardwareId);
    if (hw == null) throw Exception('Hardware $hardwareId not found');

    if (newLocation.listeningAreaId != null || newLocation.floorId != null) {
      // Move the hardware to the new location
      moveHardware(hardwareId, listeningAreaId: newLocation.listeningAreaId, floorId: newLocation.floorId);
    } else {
      hardware.add(hw.id, hw.copyWith(locationEntity: newLocation));

      if (newLocation.floorId == null && hw.locationEntity.floorId != null) {
        relationships.unlink(RelationshipType.hardwareLocation, hw.locationEntity.floorId!, hw.id);
      }
      // if (newLocation.zoneId == null && hw.locationEntity.zoneId != null) {
      //   relationships.unlink(RelationshipType.hardwareLocation, hw.locationEntity.zoneId!, hw.id);
      // }
      if (newLocation.listeningAreaId == null && hw.locationEntity.listeningAreaId != null) {
        relationships.unlink(RelationshipType.hardwareLocation, hw.locationEntity.listeningAreaId!, hw.id);
      }
    }
  }
}
