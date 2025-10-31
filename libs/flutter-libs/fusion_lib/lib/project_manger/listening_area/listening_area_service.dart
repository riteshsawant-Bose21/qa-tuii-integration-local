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

  void addMultipleAreasToAddZone(List<String> allAreasToAdd, String zoneId) {
    //if zone already have a subzone, then add listening area to subzone
    final subZoneForZone = relationships.getChildren(RelationshipType.zoneSubZones, zoneId);
    if (subZoneForZone.isEmpty) {
      for (final area in allAreasToAdd) {
        addListeningAreaToZone(area, zoneId, allAreasToAdd: allAreasToAdd);
      }
    } else {
      final SubZone subZone = SubZone(name: "SubZone ${subZoneForZone.length + 1}");
      addSubZone(subZone);
      addSubZoneToZone(subZone.id, zoneId);
      addMultipleAreasToAddSubZone(allAreasToAdd, subZone.id);
    }
  }

  /// Assign a listening area to a zone.
  /// If the listening area is already part of some other zone(s), they will be removed first.
  /// This updates:
  ///  - RelationshipManager (zoneListening links),
  ///  - Zone.listeningAreasIds lists,
  ///  - Hardware.locationEntity.zoneId and hardwareLocation links (remove old zone links, add new).
  /// Add ListeningArea to Zone with full validation + circuit + cleanup support
  void addListeningAreaToZone(String listeningAreaId, String zoneId, {List<String>? allAreasToAdd}) {
    if (!listeningAreas.exists(listeningAreaId)) {
      throw Exception('ListeningArea $listeningAreaId not found');
    }
    if (!zones.exists(zoneId)) {
      throw Exception('Zone $zoneId not found');
    }

    final currentAreas = relationships.getChildren(RelationshipType.zoneAreas, zoneId);
    if (currentAreas.contains(listeningAreaId)) {
      return; // Already linked to target zone, just removed from subzones
    }

    // Find current zones/subzones where this ListeningArea exists
    final currentParents = relationships
        .getParents(
          RelationshipType.zoneAreas,
          listeningAreaId,
        )
        .toList();

    //  Remove from any old zones first (cleanup old zone links)
    final currentZoneCopy = List<String>.from(currentParents);
    for (final oldZoneId in currentZoneCopy) {
      //check if its a zone or subzone
      if (zones.exists(oldZoneId)) {
        removeListeningAreaFromZone(listeningAreaId, oldZoneId);
      } else if (subZones.exists(oldZoneId)) {
        removeListeningAreaFromSubZone(listeningAreaId, oldZoneId);
      }
    }

    final subZoneForZone = relationships.getChildren(RelationshipType.zoneSubZones, zoneId);

    //As per Robs requirement When listening area is added to Zone with Subzone, zone cannot have area, it should we added to subzone

    if (subZoneForZone.isEmpty) {
      final hardwareInArea = relationships.getChildren(RelationshipType.hardwareLocation, listeningAreaId);

      final hardwareInAreaCopy = List<String>.from(hardwareInArea);
      for (final hwId in hardwareInAreaCopy) {
        final circuitForHardware = relationships.getParent(RelationshipType.circuitHardware, hwId);
        if (circuitForHardware != null) {
          //check if all hardware in circuit is in same area as current
          final listeningAreaInCircuit = [];
          final hardwareInCurrentArea = [];
          final hardwareInCircuit = relationships.getChildren(RelationshipType.circuitHardware, circuitForHardware);
          final hardwareInCircuitCopy = List<String>.from(hardwareInCircuit);
          for (final hw in hardwareInCircuitCopy) {
            final laId = relationships.getParent(RelationshipType.hardwareLocation, hw);
            if (laId != null) {
              listeningAreaInCircuit.add(laId);

              //if hardware in same area add it to current area hardware
              if (laId == listeningAreaId || (allAreasToAdd != null && allAreasToAdd.contains(laId))) {
                hardwareInCurrentArea.add(hw);
              }
            }
          }

          // check if whole circuit is in same area
          if (hardwareInCurrentArea.length == hardwareInCircuit.length) {
            final currentParent = relationships.getParent(RelationshipType.zoneCircuits, circuitForHardware);
            if (currentParent != null) {
              relationships.unlink(RelationshipType.zoneCircuits, currentParent, circuitForHardware);
            }
            // Just add circuit to this zone
            relationships.link(RelationshipType.zoneCircuits, zoneId, circuitForHardware);
          } else {
            if (hardwareInCurrentArea.isNotEmpty) {
              //From new Circuit form the hardware
              final speaker = hardware.get(hardwareInCurrentArea.first);
              final newCircuit = CircuitModel(name: (speaker! as Speaker).speakerSKU, speakerSKU: (speaker as Speaker).speakerSKU);
              addCircuit(newCircuit);
              for (final hw in hardwareInCurrentArea) {
                relationships.unlink(RelationshipType.circuitHardware, circuitForHardware, hw);
                addHardwareToCircuit(hw, newCircuit.id);
              }
            }
          }
        }
      }

      relationships.link(RelationshipType.zoneAreas, zoneId, listeningAreaId);
    } else {
      final SubZone subZone = SubZone(name: "SubZone ${subZoneForZone.length + 1}");
      addSubZone(subZone);
      addSubZoneToZone(subZone.id, zoneId);
      addListeningAreaToSubZone(listeningAreaId, subZone.id);
    }
  }

  void removeMultipleListeningAreaFromZone(List<String> listeningAreaIds, String zoneId) {
    // final zoneAreas = relationships.getChildren(RelationshipType.zoneAreas, zoneId);

    final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, zoneId);

    // --- NEW LOGIC ---
    final circuitIdsCopy = List<String>.from(circuitIds);
    for (final cid in circuitIdsCopy) {
      final hardwareInCircuit = relationships.getChildren(RelationshipType.circuitHardware, cid);

      final allHardwareInCircuit = hardwareInCircuit.map((hwId) => hardware.get(hwId)).whereType<Speaker>().toList();

      final hardwareInArea = allHardwareInCircuit.where((hw) => listeningAreaIds.contains(hw.locationEntity.listeningAreaId)).toList();

      // check if all hardware in area are in the same circuit
      if (hardwareInArea.length == hardwareInCircuit.length) {
        // Just remove circuit from this zone
        relationships.unlink(RelationshipType.zoneCircuits, zoneId, cid);
      } else {
        if (hardwareInArea.isNotEmpty) {
          //From new Circuit form the hardware
          final newCircuit = CircuitModel(name: hardwareInArea.first.speakerSKU, speakerSKU: hardwareInArea.first.speakerSKU);
          addCircuit(newCircuit);
          for (final hw in hardwareInArea) {
            relationships.unlink(RelationshipType.circuitHardware, cid, hw.id);
            addHardwareToCircuit(hw.id, newCircuit.id);
          }
        }
      }
    }

    for (final listeningAreaId in listeningAreaIds) {
      // Unlink listening area from zone
      relationships.unlink(RelationshipType.zoneAreas, zoneId, listeningAreaId);
    }
  }

  /// Remove ListeningArea from Zone, cleaning circuits + hardware references
  void removeListeningAreaFromZone(String listeningAreaId, String zoneId) {
    if (!listeningAreas.exists(listeningAreaId)) return;
    if (!zones.exists(zoneId)) return;

    final zoneAreas = relationships.getChildren(RelationshipType.zoneAreas, zoneId);

    //If the zone doesn’t actually include this LA, skip
    if (!zoneAreas.contains(listeningAreaId)) return;

    final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, zoneId);
    // --- NEW LOGIC ---
    final circuitIdsCopy = List<String>.from(circuitIds);
    for (final cid in circuitIdsCopy) {
      final hardwareInCircuit = relationships.getChildren(RelationshipType.circuitHardware, cid);
      final hardwareInArea = hardwareInCircuit
          .map((hwId) => hardware.get(hwId))
          .whereType<Speaker>()
          .where((hw) => hw.locationEntity.listeningAreaId == listeningAreaId)
          .toList();
      // check if all hardware in area are in the same circuit
      if (hardwareInArea.length == hardwareInCircuit.length) {
        // Just remove circuit from this zone
        relationships.unlink(RelationshipType.zoneCircuits, zoneId, cid);
      } else {
        if (hardwareInArea.isNotEmpty) {
          //From new Circuit form the hardware

          final newCircuit = CircuitModel(
            name: hardwareInArea.first.speakerSKU,
            speakerSKU: hardwareInArea.first.speakerSKU,
          );
          addCircuit(newCircuit);
          for (final hw in hardwareInArea) {
            relationships.unlink(RelationshipType.circuitHardware, cid, hw.id);
            addHardwareToCircuit(hw.id, newCircuit.id);
          }
        }
      }
    }

    // ---- OLD LOGIC ---
    //
    // List<String> circuitIdToRemove = [];
    //
    // for (final cId in circuitIds) {
    //   final hardwareInCircuit = relationships.getChildren(RelationshipType.circuitHardware, cId);
    //
    //   final hardwareInArea = hardwareInCircuit
    //       .map((hwId) => hardware.get(hwId))
    //       .whereType<HardwareComponent>()
    //       .where((hw) => hw.locationEntity.listeningAreaId == listeningAreaId)
    //       .toList();
    //
    //   // Unlink hardware
    //   for (final hw in hardwareInArea) {
    //     relationships.unlink(RelationshipType.circuitHardware, cId, hw.id);
    //   }
    //
    //   // If the circuit now has no hardware or LAs, delete it
    //   final remainingHW = relationships.getChildren(RelationshipType.circuitHardware, cId);
    //   if (remainingHW.isEmpty) {
    //     circuitIdToRemove.add(cId);
    //   }
    // }
    // // Remove empty circuits
    // for (final cId in circuitIdToRemove) {
    //   removeCircuit(cId);
    // }

    // Unlink listening area from zone
    relationships.unlink(RelationshipType.zoneAreas, zoneId, listeningAreaId);

    // final subZoneIds = relationships.getChildren(RelationshipType.zoneSubZones, zoneId);
    //
    // // Also remove from any subzones under this zone
    // final subZoneIdsCopy = List<String>.from(subZoneIds);
    // for (final subZoneId in subZoneIdsCopy) {
    //   removeListeningAreaFromSubZone(listeningAreaId, subZoneId);
    // }
  }

  FloorModel? getFloorForListeningArea(String listeningAreaId) {
    final floorId = relationships.getParent(RelationshipType.floorAreas, listeningAreaId);
    return floorId != null ? floors.get(floorId) : null;
  }

  Zone? getZoneForListeningArea(String listeningAreaId) {
    final zoneIds = relationships.getParents(RelationshipType.zoneAreas, listeningAreaId);

    if (zoneIds.isEmpty) {
      return null;
    }
    final String zoneId = zoneIds.first;

    if (zones.exists(zoneId)) {
      return zones.get(zoneId);
    } else if (subZones.exists(zoneId)) {
      //get parent zone of subzone
      final parentZoneId = relationships.getParent(RelationshipType.zoneSubZones, zoneId);
      if (parentZoneId != null) {
        return zones.get(parentZoneId);
      }
    }

    return null;
  }

  SubZone? getSubZoneForListeningArea(String listeningAreaId) {
    final zoneIds = relationships.getParents(RelationshipType.zoneAreas, listeningAreaId);
    if (zoneIds.isEmpty) {
      return null;
    }
    final String zoneId = zoneIds.first;
    if (subZones.exists(zoneId)) {
      return subZones.get(zoneId);
    }
    return null;
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
