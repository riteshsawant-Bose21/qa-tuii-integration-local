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

    // //remove all the circuits in the subzone
    // final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, subZoneId);
    //
    // // Create a copy to avoid concurrent modification during iteration
    // final circuitIdsCopy = List<String>.from(circuitIds);
    // for (final cId in circuitIdsCopy) {
    //   removeCircuit(cId);
    // }

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

  void addMultipleAreasToAddSubZone(List<String> allAreasToAdd, String subZoneId) {
    for (final area in allAreasToAdd) {
      addListeningAreaToZone(area, subZoneId, allAreasToAdd: allAreasToAdd);
    }
  }

  //add Listening area to sub zone
  void addListeningAreaToSubZone(String listeningAreaId, String subZoneId, {List<String>? allAreasToAdd}) {
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

    final hardwareInArea = relationships.getChildren(RelationshipType.hardwareLocation, listeningAreaId);
    final hardwareInAreaCopy = List<String>.from(hardwareInArea);
    for (final hwId in hardwareInAreaCopy) {
      final circuitForHardware = relationships.getParent(RelationshipType.circuitHardware, hwId);
      if (circuitForHardware != null) {
        //check if all hardware in circuit is in same area as current
        final hardwareInCircuit = relationships.getChildren(RelationshipType.circuitHardware, circuitForHardware);
        final listeningAreaInCircuit = [];
        final hardwareInCurrentArea = [];
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
          // Just add circuit to this zone
          relationships.link(RelationshipType.zoneCircuits, subZoneId, circuitForHardware);
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

    relationships.link(RelationshipType.zoneAreas, subZoneId, listeningAreaId);
  }

  void removeMultipleListeningAreaFromSubZone(List<String> listeningAreaIds, String subZoneId) {
    // final zoneAreas = relationships.getChildren(RelationshipType.zoneAreas, zoneId);

    final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, subZoneId);

    // --- NEW LOGIC ---
    final circuitIdsCopy = List<String>.from(circuitIds);
    for (final cid in circuitIdsCopy) {
      final hardwareInCircuit = relationships.getChildren(RelationshipType.circuitHardware, cid);

      final allHardwareInCircuit = hardwareInCircuit.map((hwId) => hardware.get(hwId)).whereType<Speaker>().toList();

      final hardwareInArea = allHardwareInCircuit.where((hw) => listeningAreaIds.contains(hw.locationEntity.listeningAreaId)).toList();

      // check if all hardware in area are in the same circuit
      if (hardwareInArea.length == hardwareInCircuit.length) {
        // Just remove circuit from this zone
        relationships.unlink(RelationshipType.zoneCircuits, subZoneId, cid);
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
      relationships.unlink(RelationshipType.zoneAreas, subZoneId, listeningAreaId);
    }
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
        relationships.unlink(RelationshipType.zoneCircuits, subZoneId, cid);
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

    //OLD LOGIC
    //
    // List<String> circuitIdsToRemove = [];
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
    //     circuitIdsToRemove.add(cId);
    //   }
    // }
    //
    // //remove empty circuits
    // for (final cId in circuitIdsToRemove) {
    //   removeCircuit(cId);
    // }

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
