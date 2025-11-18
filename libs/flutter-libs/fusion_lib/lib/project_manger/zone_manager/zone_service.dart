import 'package:fusion_lib/fusion_lib.dart';

extension ZoneService on ProjectService {
  /// Add a new Zone and establish relationships to the referenced listening areas & sourceSetes.
  void addZone(Zone zone) {
    if (zones.exists(zone.id)) {
      throw Exception('Zone with id ${zone.id} already exists');
    }

    // Add zone to repo
    zones.add(zone.id, zone);
  }

  /// Remove a zone and clean up all relationships to/from it.
  void removeZone(String zoneId) {
    if (!zones.exists(zoneId)) return;

    //remove all the subzones in zone
    final subZoneIds = relationships.getChildren(RelationshipType.zoneSubZones, zoneId).toList();
    final subZoneIdsCopy = List<String>.from(subZoneIds);
    for (final subZoneId in subZoneIdsCopy) {
      removeSubZone(subZoneId);
    }

    //remove all the circuits in zone
    // final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, zoneId).toList();
    // final circuitIdsCopy = List<String>.from(circuitIds);
    // for (final circuitId in circuitIdsCopy) {
    //   removeCircuit(circuitId);
    // }

    // Remove relationships that refer to this zone (both parent->children and child->parents)
    relationships.removeAllRelationships(zoneId);

    // Finally remove the zone itself
    zones.remove(zoneId);
  }

  // Update an existing zone
  void updateZone(Zone updatedZone) {
    final zoneId = updatedZone.id;
    if (!zones.exists(zoneId)) {
      throw Exception('Zone $zoneId not found');
    }

    zones.add(updatedZone.id, updatedZone);
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
    final laIds = relationships.getChildren(RelationshipType.zoneAreas, zoneId);
    return laIds.map((id) => listeningAreas.get(id)).whereType<ListeningArea>().toList();
  }

  /// Link an existing SourceSet to an existing Zone (keeps both relationship graph and zone model in sync).
  void addSourceSetToZone(String sourceSetId, String zoneId) {
    if (!sourceSets.exists(sourceSetId)) throw Exception('sourceSet $sourceSetId not found');
    if (!zones.exists(zoneId)) throw Exception('Zone $zoneId not found');

    // Update relationship graph (idempotent)
    relationships.link(RelationshipType.zoneSourceSet, zoneId, sourceSetId);
  }

  /// Unlink a SourceSet from a Zone.
  void removeSourceSetFromZone(String sourceSetId, String zoneId) {
    if (!zones.exists(zoneId)) return;

    relationships.unlink(RelationshipType.zoneSourceSet, zoneId, sourceSetId);
  }

  /// returns all the SourceSets linked to the given zoneId
  List<SourceSet> getSourceSetsInZone(String zoneId) {
    final sourceSetIds = relationships.getChildren(RelationshipType.zoneSourceSet, zoneId);
    return sourceSetIds.map((id) => sourceSets.get(id)).where((m) => m != null).cast<SourceSet>().toList();
  }

  //Add Circuit to Zone
  void addCircuitToZone(String circuitId, String zoneId) {
    if (!circuits.exists(circuitId)) throw Exception('Circuit $circuitId not found');
    if (!zones.exists(zoneId)) throw Exception('Zone $zoneId not found');

    // Update relationship graph (idempotent)
    relationships.link(RelationshipType.zoneCircuits, zoneId, circuitId);
  }

  //Remove Circuit from Zone
  void removeCircuitFromZone(String circuitId, String zoneId) {
    if (!zones.exists(zoneId)) return;

    final hwChildren = relationships.getChildren(RelationshipType.circuitHardware, circuitId);
    final hwChildrenCopy = List<String>.from(hwChildren);
    for (final hwId in hwChildrenCopy) {
      relationships.unlink(RelationshipType.circuitHardware, circuitId, hwId);
    }

    relationships.unlink(RelationshipType.zoneCircuits, zoneId, circuitId);
  }

  /// returns all the Circuits linked to the given zoneId
  List<CircuitModel> getCircuitsInZone(String zoneId) {
    final circuitIds = relationships.getChildren(RelationshipType.zoneCircuits, zoneId);
    return circuitIds.map((id) => circuits.get(id)).where((m) => m != null).cast<CircuitModel>().toList();
  }

  Map<String, Zone> reOrderZones({
    required String zoneIdToMove,
    required String zoneAtNewIndexId,
  }) {
    List<Zone> items = zones.getAll();

    // Find indices
    int fromIndex = items.indexWhere((hw) => hw.id == zoneIdToMove);
    int toIndex = items.indexWhere((hw) => hw.id == zoneAtNewIndexId);

    // Validate
    if (fromIndex == -1 || toIndex == -1) {
      throw ArgumentError('Invalid hardware IDs');
    }

    // Reorder using List operations
    Zone item = items.removeAt(fromIndex);
    items.insert(toIndex, item);

    // Convert back to Map
    return {for (var zone in items) zone.id: zone};
  }

  //Zone Sources
  void addSourceToZone(String sourceId, String zoneId) {
    if (!hardware.exists(sourceId)) throw Exception('Source $sourceId not found');
    if (!zones.exists(zoneId)) throw Exception('Zone $zoneId not found');

    relationships.link(RelationshipType.zoneSources, zoneId, sourceId);
  }

  void removeSourceFromZone(String sourceId, String zoneId) {
    if (!zones.exists(zoneId)) return;

    relationships.unlink(RelationshipType.zoneSources, zoneId, sourceId);
  }

  List<Source> getSourcesInZone(String zoneId) {
    final sourceIds = relationships.getChildren(RelationshipType.zoneSources, zoneId);
    return sourceIds.map((id) => hardware.get(id)).where((m) => m != null).whereType<Source>().toList();
  }

  ///This method returns all the sources linked directly to the zone
  /// as well as all the sources that are part of the source sets linked to the zone
  List<Source> getSourcesAndSourceSetSourcesInZone({required String zoneId}) {
    final sourcesInZone = getSourcesInZone(zoneId);
    final sourceSetsInZone = relationships.getChildren(RelationshipType.zoneSourceSet, zoneId);

    final sourceSetSources = <Source>[];
    sourceSetSources.addAll(sourcesInZone);
    for (final sourceSet in sourceSetsInZone) {
      List<Source> sourcesInSourceSet = getSourcesInSourceSet(sourceSet);
      sourceSetSources.addAll(sourcesInSourceSet);
    }
    return sourceSetSources;
  }

  //Add Priority sources
  void addPrioritySourceToZone({required String sourceId, required String zoneId, required int priority}) {
    if (!hardware.exists(sourceId)) throw Exception('Source $sourceId not found');
    if (!zones.exists(zoneId)) throw Exception('Zone $zoneId not found');
    if (priority < 1 || priority > 2) throw Exception('Priority should be [1,2]');

    final prioritySources = relationships.getChildren(RelationshipType.prioritySources, zoneId).toList();

    if (prioritySources.contains(sourceId)) {
      throw Exception('Source $sourceId already exists in zone $zoneId ');
    }

    final priorityOrder = <String>[...prioritySources];

    if (priority == 1) {
      priorityOrder.insert(0, sourceId);
    } else {
      if (priorityOrder.isEmpty) priorityOrder.add("");

      if (priorityOrder.length == 2) {
        priorityOrder.insert(1, sourceId);
      } else {
        priorityOrder.add(sourceId);
      }
    }

    for (final childId in priorityOrder) {
      relationships.link(RelationshipType.prioritySources, zoneId, childId);
    }

    relationships.reOrder(RelationshipType.prioritySources, zoneId, priorityOrder);
  }

  void reOrderPrioritySourcesInZone({required String zoneId, required List<String> newOrder}) {
    if (!zones.exists(zoneId)) return;

    final prioritySources = relationships.getChildren(RelationshipType.prioritySources, zoneId).toList();

    if (newOrder.length != prioritySources.length || !newOrder.every((id) => prioritySources.contains(id))) {
      throw Exception('New order does not match existing priority sources in zone $zoneId');
    }

    relationships.reOrder(RelationshipType.prioritySources, zoneId, newOrder);
  }

  void removePrioritySourceFromZone({required String sourceId, required String zoneId}) {
    if (!zones.exists(zoneId)) return;

    final prioritySources = relationships.getChildren(RelationshipType.prioritySources, zoneId).toList();

    if (!prioritySources.contains(sourceId)) return;

    final updatedPrioritySources = prioritySources.map((id) => id == sourceId ? "" : id).toList();

    for (final childId in updatedPrioritySources) {
      relationships.link(RelationshipType.prioritySources, zoneId, childId);
    }

    relationships.reOrder(RelationshipType.prioritySources, zoneId, updatedPrioritySources);
  }

  List<String> getPrioritySourcesInZone(String zoneId) {
    final prioritySources = relationships.getChildren(RelationshipType.prioritySources, zoneId).toList();

    return prioritySources;
  }
}
