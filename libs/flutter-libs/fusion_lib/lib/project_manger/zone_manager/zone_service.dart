import 'package:fusion_lib/fusion_lib.dart';

extension ZoneService on ProjectService {
  /// Add a new Zone and establish relationships to the referenced listening areas & sourceSetes.
  void addZone(Zone zone) {
    if (zones.exists(zone.id)) {
      throw Exception('Zone with id ${zone.id} already exists');
    }

    // Add zone to repo
    zones.add(zone.id, zone);

    // Link listening areas referenced in the zone (idempotent)
    for (final laId in zone.listeningAreasIds) {
      if (!listeningAreas.exists(laId)) {
        // either throw or skip — choose behavior your app prefers
        throw Exception('ListeningArea $laId does not exist');
      }
      relationships.link(RelationshipType.zoneListening, zone.id, laId);
    }

    // Link sourceSet references
    for (final sourceSetId in zone.sourceSetIds) {
      if (!sourceSets.exists(sourceSetId)) {
        throw Exception('sourceSet $sourceSetId does not exist');
      }
      relationships.link(RelationshipType.zoneSourceSet, zone.id, sourceSetId);
    }

    // Optional persistence/notification hook
    // _onProjectChanged();
  }

  /// Remove a zone and clean up all relationships to/from it.
  void removeZone(String zoneId) {
    if (!zones.exists(zoneId)) return;

    // Remove relationships that refer to this zone (both parent->children and child->parents)
    relationships.removeAllRelationships(zoneId);

    // Finally remove the zone itself
    zones.remove(zoneId);

    // Optional persistence/notification hook
    // _onProjectChanged();
  }

  /// Update an existing zone using the provided `updatedZone`.
  /// This updates relationships, the zone repo entry, hardware zone links, and ensures
  /// listening areas are moved to the new zone (removing them from old zones).
  ///
  /// Throws if the zone does not exist or any referenced listening area / mix does not exist.
  void updateZone(Zone updatedZone) {
    final zoneId = updatedZone.id;
    if (!zones.exists(zoneId)) {
      throw Exception('Zone $zoneId not found');
    }

    final existing = zones.get(zoneId)!;

    // --- Listening Areas diff
    final oldLAs = Set<String>.from(existing.listeningAreasIds);
    final newLAs = Set<String>.from(updatedZone.listeningAreasIds);
    final toAddLAs = newLAs.difference(oldLAs);
    final toRemoveLAs = oldLAs.difference(newLAs);

    // Remove LAs that are no longer part of this zone
    for (final laId in toRemoveLAs) {
      // unlink relationship
      relationships.unlink(RelationshipType.zoneListening, zoneId, laId);
      // update zone model list
      existing.listeningAreasIds.remove(laId);

      // For hardware placed in this listening area: if hw.locationEntity.zoneId == this zone -> clear it and unlink hardwareLocation zone->hw
      final hwIdsInLA = relationships.getChildren(RelationshipType.hardwareLocation, laId);
      for (final hwId in hwIdsInLA) {
        final hw = hardware.get(hwId);
        if (hw != null && hw.locationEntity.zoneId == zoneId) {
          hw.locationEntity.zoneId = null;
          relationships.unlink(RelationshipType.hardwareLocation, zoneId, hwId);
        }
      }
    }

    // Add / move listening areas into this zone
    for (final laId in toAddLAs) {
      if (!listeningAreas.exists(laId)) {
        throw Exception('ListeningArea $laId not found');
      }

      // Remove LA from any other zones (enforce single-parent semantics)
      final currentParents = relationships.getParents(RelationshipType.zoneListening, laId).toList();
      for (final oldZoneId in currentParents) {
        if (oldZoneId == zoneId) continue;
        // unlink relationship oldZone -> la
        relationships.unlink(RelationshipType.zoneListening, oldZoneId, laId);

        // update old zone model
        final oldZone = zones.get(oldZoneId);
        if (oldZone != null) {
          oldZone.listeningAreasIds.remove(laId);
        }

        // fix hardware references that pointed to oldZone via this LA
        final hwIds = relationships.getChildren(RelationshipType.hardwareLocation, laId);
        for (final hwId in hwIds) {
          final hw = hardware.get(hwId);
          if (hw != null && hw.locationEntity.zoneId == oldZoneId) {
            hw.locationEntity.zoneId = null;
            relationships.unlink(RelationshipType.hardwareLocation, oldZoneId, hwId);
          }
        }
      }

      // link this zone -> la
      relationships.link(RelationshipType.zoneListening, zoneId, laId);

      // update zone model list (idempotent)
      if (!existing.listeningAreasIds.contains(laId)) {
        existing.listeningAreasIds.add(laId);
      }

      // ensure hardware in this LA are linked to this zone and have locationEntity.zoneId set
      final hwIdsNow = relationships.getChildren(RelationshipType.hardwareLocation, laId);
      for (final hwId in hwIdsNow) {
        final hw = hardware.get(hwId);
        if (hw == null) continue;
        hw.locationEntity.zoneId = zoneId;
        relationships.link(RelationshipType.hardwareLocation, zoneId, hwId);
      }
    }

    // --- Mixes diff
    final oldMixes = Set<String>.from(existing.sourceSetIds);
    final newMixes = Set<String>.from(updatedZone.sourceSetIds);
    final toAddMixes = newMixes.difference(oldMixes);
    final toRemoveMixes = oldMixes.difference(newMixes);

    // Remove mixes
    for (final mixId in toRemoveMixes) {
      existing.sourceSetIds.remove(mixId);
      relationships.unlink(RelationshipType.zoneSourceSet, zoneId, mixId);
    }

    // Add mixes
    for (final mixId in toAddMixes) {
      if (!sourceSets.exists(mixId)) {
        throw Exception('Mix $mixId not found');
      }
      if (!existing.sourceSetIds.contains(mixId)) existing.sourceSetIds.add(mixId);
      relationships.link(RelationshipType.zoneSourceSet, zoneId, mixId);
    }

    zones.add(updatedZone.id, updatedZone);
  }

  /// Add a hardware (speaker) to a zone. This updates:
  ///  - hardware.locationEntity.zoneId/listeningAreaId/floorId
  ///  - hardwareLocation relationships (zone, listeningArea, floor)
  ///
  /// Moves the hardware from any previous location to the new zone.
  void addSpeakerToZone(String hardwareId, String zoneId) {
    if (!hardware.exists(hardwareId)) {
      throw Exception('Hardware $hardwareId not found');
    }
    if (!zones.exists(zoneId)) {
      throw Exception('Zone $zoneId not found');
    }

    final hw = hardware.get(hardwareId)!;
    final loc = hw.locationEntity; // LocationModel instance

    // 1) Unlink existing hardwareLocation relationships (move semantics)
    final prevParents = relationships.getParents(RelationshipType.hardwareLocation, hardwareId).toList();
    for (final parentId in prevParents) {
      relationships.unlink(RelationshipType.hardwareLocation, parentId, hardwareId);
    }

    // 2) Update the LocationModel
    loc.zoneId = zoneId;

    // 3) Infer listeningArea and floor from zone relationships (if any)
    final listeningAreasForZone = relationships.getChildren(RelationshipType.zoneListening, zoneId);
    if (listeningAreasForZone.isNotEmpty) {
      final chosenLA = listeningAreasForZone.first; // pick the first (or change strategy)
      loc.listeningAreaId = chosenLA;
      // find floor for that listening area
      final floorId = relationships.getParent(RelationshipType.floorListening, chosenLA);
      loc.floorId = floorId;
      // 4) Link hardware to listeningArea & floor (if found)
      relationships.link(RelationshipType.hardwareLocation, chosenLA, hardwareId);
      if (floorId != null) relationships.link(RelationshipType.hardwareLocation, floorId, hardwareId);
    } else {
      // No listening area -> clear those fields
      loc.listeningAreaId = null;
      loc.floorId = null;
    }

    // 5) Link hardware to the zone itself
    relationships.link(RelationshipType.hardwareLocation, zoneId, hardwareId);
  }

  /// Remove hardware from a zone. This will:
  ///  - unlink hardware <-> zone (and any inferred listeningArea & floor),
  ///  - clear the LocationModel fields (zone/listeningArea/floor).
  void removeSpeakerFromZone(String hardwareId, String zoneId) {
    if (!hardware.exists(hardwareId)) return;
    final hw = hardware.get(hardwareId)!;
    final loc = hw.locationEntity;

    // If hardware not in that zone, nothing to do
    if (loc.zoneId != zoneId) return;

    // Unlink zone
    relationships.unlink(RelationshipType.hardwareLocation, zoneId, hardwareId);

    // If we had listeningArea/floor set, unlink those too
    if (loc.listeningAreaId != null) {
      relationships.unlink(RelationshipType.hardwareLocation, loc.listeningAreaId!, hardwareId);
    }
    if (loc.floorId != null) {
      relationships.unlink(RelationshipType.hardwareLocation, loc.floorId!, hardwareId);
    }

    // Clear location fields
    loc.zoneId = null;
    loc.listeningAreaId = null;
    loc.floorId = null;
  }

  // Get zone by id
  Zone? getZoneById(String zoneId) {
    return zones.get(zoneId);
  }

  // Get all listening areas in a zone
  List<ListeningArea> getListeningAreasInZone(String zoneId) {
    if (!zones.exists(zoneId)) {
      throw Exception('Zone $zoneId not found');
    }
    final laIds = relationships.getChildren(RelationshipType.zoneListening, zoneId);
    return laIds.map((id) => listeningAreas.get(id)).whereType<ListeningArea>().toList();
  }

  /// Link an existing SourceSet to an existing Zone (keeps both relationship graph and zone model in sync).
  void addSourceSetToZone(String sourceSetId, String zoneId) {
    if (!sourceSets.exists(sourceSetId)) throw Exception('sourceSet $sourceSetId not found');
    if (!zones.exists(zoneId)) throw Exception('Zone $zoneId not found');

    final zone = zones.get(zoneId)!;

    // Update zone model list (idempotent)
    if (!zone.sourceSetIds.contains(sourceSetId)) {
      zone.sourceSetIds.add(sourceSetId);
    }

    // Update relationship graph (idempotent)
    relationships.link(RelationshipType.zoneSourceSet, zoneId, sourceSetId);

    // Optional persistence/notification hook
    // _onProjectChanged();
  }

  /// Unlink a SourceSet from a Zone.
  void removeSourceSetFromZone(String sourceSetId, String zoneId) {
    if (!zones.exists(zoneId)) return;

    final zone = zones.get(zoneId)!;
    zone.sourceSetIds.remove(sourceSetId);

    relationships.unlink(RelationshipType.zoneSourceSet, zoneId, sourceSetId);

    // Optional persistence/notification hook
    // _onProjectChanged();
  }

  /// returns all the SourceSets linked to the given zoneId
  List<SourceSet> getSourceSetsInZone(String zoneId) {
    final sourceSetIds = relationships.getChildren(RelationshipType.zoneSourceSet, zoneId);
    return sourceSetIds.map((id) => sourceSets.get(id)).where((m) => m != null).cast<SourceSet>().toList();
  }
}
