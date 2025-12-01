import 'package:fusion_lib/fusion_lib.dart';

extension HardwareService on ProjectService {
  /// Add hardware component into repo; create relationships based on its LocationModel.
  void addHardware({required HardwareComponent hw, bool addToCircuit = true}) {
    if (hardware.exists(hw.id)) {
      throw Exception('Hardware ${hw.id} already exists');
    }

    hardware.add(hw.id, hw);

    // Link to the relevant parent(s). Use hardwareLocation relationship type.
    final loc = hw.locationEntity;
    if (loc.floorId != null) {
      relationships.link(RelationshipType.hardwareFloor, loc.floorId!, hw.id);
    }

    if (loc.listeningAreaId != null) {
      relationships.link(RelationshipType.hardwareLocation, loc.listeningAreaId!, hw.id);
    }

    if (addToCircuit) {
      checkAndAddHardwareForCircuit(hw.id, hw.addedFromBuildingPage);
    }
  }

  void checkAndAddHardwareForCircuit(String hardwareId, bool fromBuildingPage) {
    final hw = hardware.get(hardwareId);
    if (hw == null) {
      throw Exception('Hardware $hardwareId not found');
    }
    final loc = hw.locationEntity;

    if (hw is Speaker && loc.listeningAreaId != null) {
      //chek if it has subzone
      String? zoneIdForHw = getSubZoneForHardware(hw.id)?.id;

      //else check if it has zone
      zoneIdForHw ??= getZoneForHardware(hw.id)?.id;

      if (zoneIdForHw != null) {
        final circuitsInZone = getCircuitsInZone(zoneIdForHw);
        bool addedToCircuit = false;
        for (final circuit in circuitsInZone) {
          if (circuit.speakerSKU == hw.speakerSKU) {
            //add hardware to this circuit
            addHardwareToCircuit(hw.id, circuit.id);
            addedToCircuit = true;
            break;
          }
        }
        if (!addedToCircuit) {
          //create new circuit for this hardware
          final newCircuit = CircuitModel(
            name: hw.hardwareName,
            speakerSKU: hw.speakerSKU,
            addedInBuildingPage: fromBuildingPage,
          );
          addCircuit(newCircuit);
          addHardwareToCircuit(hw.id, newCircuit.id);
          addCircuitToZone(newCircuit.id, zoneIdForHw);
        }
      } else {
        final hardwareInLa = getHardwareForListeningArea(loc.listeningAreaId ?? '');
        String? circuitForNewHardware;
        if (hardwareInLa.length > 1) {
          for (final hardwareItem in hardwareInLa) {
            if (hardwareItem is Speaker) {
              if (hardwareItem.speakerSKU == hw.speakerSKU) {
                final hwCircuitId = relationships.getParent(RelationshipType.circuitHardware, hardwareItem.id);
                if (hwCircuitId != null) {
                  circuitForNewHardware = hwCircuitId;
                  break;
                }
              }
            }
          }
        }
        if (circuitForNewHardware == null) {
          //create new circuit for this hardware
          final newCircuit = CircuitModel(name: hw.hardwareName, speakerSKU: hw.speakerSKU, addedInBuildingPage: fromBuildingPage);
          addCircuit(newCircuit);
          addHardwareToCircuit(hw.id, newCircuit.id);
        } else {
          //add hardware to existing circuit
          addHardwareToCircuit(hw.id, circuitForNewHardware);
        }
      }
    }
  }

  Zone? getZoneForHardware(String hardwareId) {
    final hw = hardware.get(hardwareId);
    if (hw == null) throw Exception('Hardware $hardwareId not found');
    final loc = hw.locationEntity;
    if (loc.listeningAreaId != null) {
      final laId = loc.listeningAreaId!;
      final parentZoneIds = relationships.getParents(RelationshipType.zoneAreas, laId);
      if (parentZoneIds.isNotEmpty) {
        final zoneId = parentZoneIds.first;
        final zone = zones.get(zoneId);
        return zone;
      }
    }
    return null;
  }

  SubZone? getSubZoneForHardware(String hardwareId) {
    final hw = hardware.get(hardwareId);
    if (hw == null) throw Exception('Hardware $hardwareId not found');
    final loc = hw.locationEntity;
    if (loc.listeningAreaId != null) {
      final laId = loc.listeningAreaId!;
      final parentZoneIds = relationships.getParents(RelationshipType.zoneAreas, laId);
      if (parentZoneIds.isNotEmpty) {
        final zoneId = parentZoneIds.first;
        final subZone = subZones.get(zoneId);
        return subZone;
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

    //if hardware is part of any circuit, and circuit has only this hardware, remove circuit too
    final circuitIds = relationships.getParents(RelationshipType.circuitHardware, hardwareId);
    if (circuitIds.isNotEmpty) {
      final String cId = circuitIds.first;
      final hwIds = relationships.getChildren(RelationshipType.circuitHardware, cId);
      if (hwIds.length == 1 && hwIds.contains(hardwareId)) {
        //remove circuit
        // Remove all relationships
        relationships.removeAllRelationships(cId);
        circuits.remove(cId);
      }
    }

    final hwToRemove = hardware.get(hardwareId);
    if (hwToRemove is Source) {
      // Remove source set relationship if any
      final sourceSetIds = relationships.getParent(RelationshipType.sourceSetSources, hardwareId);
      if (sourceSetIds != null) {
        removeSourceFromSourceSet(hardwareId, sourceSetIds);
      }

      // Remove from all scenes if source is added to any
      removeSourceFromAllScenes(hardwareId);

      //remove priority source data for this source
      removePrioritySourceDataForSource(hardwareId);
    }

    final wireConnections = relationships.getChildren(RelationshipType.wireConnection, hardwareId);
    final wireConnectionsCopy = List<String>.from(wireConnections);
    for (final connId in wireConnectionsCopy) {
      removeWiringConnection(connId);
    }

    // Remove relationship links
    relationships.removeAllRelationships(hardwareId);

    // Remove repo entry
    hardware.remove(hardwareId);
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

    final prevFloorParents = relationships.getParents(RelationshipType.hardwareFloor, hardwareId).toList();

    String parentFloorId = prevFloorParents.first;
    if (parentFloorId != floorId) {
      relationships.unlink(RelationshipType.hardwareFloor, parentFloorId, hardwareId);
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
      final inferredFloorId = relationships.getParent(RelationshipType.floorAreas, listeningAreaId);
      if (inferredFloorId != null) {
        loc.floorId = inferredFloorId;
        relationships.link(RelationshipType.hardwareLocation, inferredFloorId, hardwareId);
      }
    } else if (floorId != null) {
      // 4) Moving to a floor only (no listening area, no zone)
      if (!floors.exists(floorId)) {
        throw Exception('Floor $floorId not found');
      }

      loc.floorId = floorId;
      relationships.link(RelationshipType.hardwareFloor, floorId, hardwareId);
    }
  }

  List<HardwareComponent> getAllHardware() {
    return hardware.getAll();
  }

  List<HardwareComponent> getHardwareForListeningArea(String laId) {
    final ids = relationships.getChildren(RelationshipType.hardwareLocation, laId);
    return ids.map((id) => hardware.get(id)).whereType<HardwareComponent>().toList();
  }

  List<HardwareComponent> getAllHardwareInFloor(String floorId) {
    final Set<String> resultIds = {};

    // hardware directly linked to the floor
    resultIds.addAll(relationships.getChildren(RelationshipType.hardwareFloor, floorId));

    // all listening areas on this floor
    // final laIds = relationships.getChildren(RelationshipType.floorAreas, floorId);
    // for (final laId in laIds) {
    //   resultIds.addAll(relationships.getChildren(RelationshipType.hardwareLocation, laId));
    //
    //   // zones that include this listening area
    //   final zoneIds = relationships.getParents(RelationshipType.zoneAreas, laId);
    //   for (final zoneId in zoneIds) {
    //     resultIds.addAll(relationships.getChildren(RelationshipType.hardwareLocation, zoneId));
    //   }
    // }

    return resultIds.map((id) => hardware.get(id)).whereType<HardwareComponent>().toList();
  }

  List<HardwareComponent> getAllHardwareInFloorWithPosition({required String floorId}) {
    final allHardware = getAllHardwareInFloor(floorId);
    return allHardware.where((hw) => hw.pos != null).toList();
  }

  List<HardwareComponent> getAllHardwareInFloorWithoutPosition({required String floorId}) {
    final allHardware = getAllHardwareInFloor(floorId);
    return allHardware.where((hw) => hw.pos == null).toList();
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
        relationships.unlink(RelationshipType.hardwareFloor, hw.locationEntity.floorId!, hw.id);
      }
      // if (newLocation.zoneId == null && hw.locationEntity.zoneId != null) {
      //   relationships.unlink(RelationshipType.hardwareLocation, hw.locationEntity.zoneId!, hw.id);
      // }
      if (newLocation.listeningAreaId == null && hw.locationEntity.listeningAreaId != null) {
        relationships.unlink(RelationshipType.hardwareLocation, hw.locationEntity.listeningAreaId!, hw.id);
      }
    }
  }

  // List<HardwareComponent> reOrderHardware({
  //   required String hwToMoveId,
  //   required String hwAtNewIndexId,
  // }) {
  //   final hardwareList = getAllHardware();
  //
  //   final currentIndex = hardwareList.indexWhere((h) => h.id == hwToMoveId);
  //   final newIndex = hardwareList.indexWhere((h) => h.id == hwAtNewIndexId);
  //
  //   if (currentIndex == -1) {
  //     throw Exception("Hardware to move not found");
  //   }
  //   if (newIndex == -1) {
  //     throw Exception("Hardware at new index not found");
  //   }
  //
  //   final updatedList = List<HardwareComponent>.from(hardwareList);
  //   final item = updatedList.removeAt(currentIndex);
  //   updatedList.insert(newIndex, item);
  //
  //   return updatedList;
  // }

  Map<String, HardwareComponent> reOrderHardware({
    required String hwToMoveId,
    required String hwAtNewIndexId,
  }) {
    List<HardwareComponent> items = hardware.getAll();

    // Find indices
    int fromIndex = items.indexWhere((hw) => hw.id == hwToMoveId);
    int toIndex = items.indexWhere((hw) => hw.id == hwAtNewIndexId);

    // Validate
    if (fromIndex == -1 || toIndex == -1) {
      throw ArgumentError('Invalid hardware IDs');
    }

    // Reorder using List operations
    HardwareComponent item = items.removeAt(fromIndex);
    items.insert(toIndex, item);

    // Convert back to Map
    return {for (var hw in items) hw.id: hw};
  }

  void removePrioritySourceDataForSource(String sourceId) {
    final List<PrioritySourceData> prioDataList = prioritySourceData.getBySource(sourceId);

    final copyOfPrioDataList = List<PrioritySourceData>.from(prioDataList);
    // Remove the source from the priority data of affected zones
    for (final priorityData in copyOfPrioDataList) {
      final zoneId = relationships.getParent(RelationshipType.zonePriorities, priorityData.id);
      if (zoneId != null) {
        relationships.unlink(RelationshipType.zonePriorities, zoneId, priorityData.id);
      }
      prioritySourceData.remove(priorityData.id);
    }
  }
}
