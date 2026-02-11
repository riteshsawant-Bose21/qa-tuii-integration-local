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

    //remove functions associated with this zone
    final functionIds = relationships.getChildren(RelationshipType.zoneFunctions, zoneId).toList();
    final functionIdsCopy = List<String>.from(functionIds);
    for (final functionId in functionIdsCopy) {
      removeFunction(functionId: functionId);
    }

    removeAllPrioritySourcesFromZone(zoneId);

    //remove all associated Scene actions
    final sceneActionsIds = relationships.getParents(RelationshipType.actionItemMapping, zoneId).toList();
    final sceneActionsIdsCopy = List<String>.from(sceneActionsIds);
    for (final actionId in sceneActionsIdsCopy) {
      removeSceneAction(actionId);
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

    //check if zone has functions
    final functionIds = relationships.getChildren(RelationshipType.zoneFunctions, zoneId);
    if (functionIds.isEmpty) return;
    //if zone has functions, we need to add missing source settings to all scenes

    addMissingSourceSettingsToAllScenes(functionIds.first);

    addMissingSourceSettingsToFunction(functionIds.first);
  }

  /// Unlink a SourceSet from a Zone.
  void removeSourceSetFromZone(String sourceSetId, String zoneId) {
    if (!zones.exists(zoneId)) return;

    relationships.unlink(RelationshipType.zoneSourceSet, zoneId, sourceSetId);

    //check if zone has functions
    final functionIds = relationships.getChildren(RelationshipType.zoneFunctions, zoneId);
    if (functionIds.isEmpty) return;

    //remove all sources in source set from all scenes
    final sourcesInSourceSet = relationships.getChildren(RelationshipType.sourceSetSources, sourceSetId);
    final sourcesInSourceSetCopy = List<String>.from(sourcesInSourceSet);
    for (final source in sourcesInSourceSetCopy) {
      removeSourceFromAllScenes(source);

      //check if this source is used in any Source action, if yes, remove it
      final sourceActions = relationships.getParents(RelationshipType.actionValueMapping, source);
      final sourceActionsCopy = List<String>.from(sourceActions);
      for (final actionId in sourceActionsCopy) {
        removeSceneAction(actionId);
      }
    }
  }

  /// returns all the SourceSets linked to the given zoneId
  List<SourceSet> getSourceSetsInZone(String zoneId) {
    final sourceSetIds = relationships.getChildren(RelationshipType.zoneSourceSet, zoneId);
    return sourceSetIds.map((id) => sourceSets.get(id)).where((m) => m != null).cast<SourceSet>().toList();
  }

  //Add Circuit to Zone
  void addCircuitToZone(String circuitId, String zoneId) {
    if (!circuits.exists(circuitId)) throw Exception('Circuit $circuitId not found');
    // if (!zones.exists(zoneId)) throw Exception('Zone $zoneId not found');

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

  List<Zone> getZonesWithoutSubzones() {
    final allZones = zones.getAll();
    return allZones.where((zone) {
      final subZoneIds = relationships.getChildren(RelationshipType.zoneSubZones, zone.id);
      return subZoneIds.isEmpty;
    }).toList();
  }

  //Zone Sources
  void addSourceToZone(String sourceId, String zoneId) {
    if (!hardware.exists(sourceId)) throw Exception('Source $sourceId not found');
    if (!zones.exists(zoneId)) throw Exception('Zone $zoneId not found');

    relationships.link(RelationshipType.zoneSources, zoneId, sourceId);

    //check if zone has functions
    final functionIds = relationships.getChildren(RelationshipType.zoneFunctions, zoneId);
    if (functionIds.isEmpty) return;
    //if zone has functions, we need to add missing source settings to all scenes

    addMissingSourceSettingsToAllScenes(functionIds.first);

    addMissingSourceSettingsToFunction(functionIds.first);
  }

  void removeSourceFromZone(String sourceId, String zoneId) {
    if (!zones.exists(zoneId)) return;

    relationships.unlink(RelationshipType.zoneSources, zoneId, sourceId);

    removeSourceFromAllScenes(sourceId);

    final sourceActions = relationships.getParents(RelationshipType.actionValueMapping, sourceId);
    final sourceActionsCopy = List<String>.from(sourceActions);
    for (final actionId in sourceActionsCopy) {
      removeSceneAction(actionId);
    }
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
    final zonePriorities = relationships.getChildren(RelationshipType.zonePriorities, zoneId).toList();
    if (zonePriorities.isNotEmpty) {
      for (final priorityId in zonePriorities) {
        final existingPriority = prioritySourceData.get(priorityId)!;
        if (existingPriority.sourceId == sourceId) {
          throw Exception('Source $sourceId already exists as priority ${existingPriority.priority} in zone $zoneId ');
        }
      }
    }

    //update existing priority source or add new one
    final existingPriorityWithSamePriority = zonePriorities.map((id) => prioritySourceData.get(id)!).where((p) => p.priority == priority).firstOrNull;

    if (existingPriorityWithSamePriority != null) {
      // Update existing priority source with same priority level
      final updatedPriority = existingPriorityWithSamePriority.copyWith(sourceId: sourceId);
      prioritySourceData.add(updatedPriority.id, updatedPriority);
    } else {
      // Add new priority source
      final newPriority = PrioritySourceData(priority: priority, sourceId: sourceId, zoneId: zoneId);
      prioritySourceData.add(newPriority.id, newPriority);
      relationships.link(RelationshipType.zonePriorities, zoneId, newPriority.id);
    }

    // final prioritySources = relationships.getChildren(RelationshipType.prioritySources, zoneId).toList();
    //
    // if (prioritySources.contains(sourceId)) {
    //   throw Exception('Source $sourceId already exists in zone $zoneId ');
    // }
    //
    // final priorityOrder = <String>[...prioritySources];
    //
    // if (priority == 1) {
    //   if (priorityOrder.isEmpty) {
    //     priorityOrder.add(sourceId);
    //   } else {
    //     priorityOrder[0] = sourceId;
    //   }
    // } else {
    //   if (priorityOrder.isEmpty) priorityOrder.add("");
    //
    //   if (priorityOrder.length == 2) {
    //     priorityOrder[1] = sourceId;
    //   } else {
    //     priorityOrder.add(sourceId);
    //   }
    // }
    //
    // for (final childId in priorityOrder) {
    //   relationships.link(RelationshipType.prioritySources, zoneId, childId);
    // }
    //
    // relationships.reOrder(RelationshipType.prioritySources, zoneId, priorityOrder);
  }

  void checkAndRemoveSourceFromZonePrioritySources({
    required String sourceId,
  }) {
    final allZones = zones.getAll();

    for (final zone in allZones) {
      final prioritySources = relationships.getChildren(RelationshipType.zonePriorities, zone.id).toList();

      for (final priorityId in prioritySources) {
        final priorityData = prioritySourceData.get(priorityId);
        if (priorityData?.sourceId == sourceId) {
          relationships.unlink(RelationshipType.zonePriorities, zone.id, priorityId);
          prioritySourceData.remove(priorityId);
          break;
        }
      }
    }
  }

  void reOrderPrioritySourcesInZone({
    required String zoneId,
    required List<String> newOrder,
  }) {
    if (!zones.exists(zoneId)) return;

    final currentOrder = prioritySourceData.getByZone(zoneId);

    final String? newFirst = newOrder.isNotEmpty ? newOrder[0] : null;
    final String? newSecond = newOrder.length > 1 ? newOrder[1] : null;

    final Map<int, PrioritySourceData> oldMap = {for (var p in currentOrder) p.priority: p};

    final Map<int, PrioritySourceData> newMap = {};

    // Update priority=1
    if (newFirst != null && newFirst.trim().isNotEmpty) {
      final existing = currentOrder.firstWhere(
        (p) => p.sourceId == newFirst,
        orElse: () => PrioritySourceData(
          sourceId: newFirst,
          zoneId: zoneId,
          priority: 1,
        ),
      );

      newMap[1] = existing.copyWith(priority: 1);
    }

    // Update priority=2
    if (newSecond != null && newSecond.trim().isNotEmpty) {
      final existing = currentOrder.firstWhere(
        (p) => p.sourceId == newSecond,
        orElse: () => PrioritySourceData(
          sourceId: newSecond,
          zoneId: zoneId,
          priority: 2,
        ),
      );

      newMap[2] = existing.copyWith(priority: 2);
    }

    // Write priorities in one pass so no conflicts
    for (var p in newMap.values) {
      prioritySourceData.add(p.id, p);
    }
  }

  void removePrioritySourceFromZone({required String sourceId, required String zoneId}) {
    if (!zones.exists(zoneId)) return;

    final prioritySources = relationships.getChildren(RelationshipType.zonePriorities, zoneId);

    for (final priorityId in prioritySources) {
      final priorityData = prioritySourceData.get(priorityId);
      if (priorityData?.sourceId == sourceId) {
        relationships.unlink(RelationshipType.zonePriorities, zoneId, priorityId);
        prioritySourceData.remove(priorityId);
        break;
      }
    }
  }

  List<PrioritySourceData> getPrioritySourcesDataInZone(String zoneId) {
    final prioritySources = relationships.getChildren(RelationshipType.zonePriorities, zoneId).toList();

    final priorityData = prioritySources.map((id) => prioritySourceData.get(id)).where((data) => data != null).cast<PrioritySourceData>().toList();

    // Sort by priority
    priorityData.sort((a, b) => a.priority.compareTo(b.priority));

    return priorityData;
  }

  void updatePrioritySourceGain({
    required String priorityDataId,
    required double newGain,
  }) {
    final existingData = prioritySourceData.get(priorityDataId);
    if (existingData == null) {
      throw Exception('PrioritySourceData $priorityDataId not found');
    }

    final updatedData = existingData.copyWith(gain: newGain);
    prioritySourceData.add(updatedData.id, updatedData);
  }

  PrioritySourceData? getPrioritySourceDataById({required String priorityDataId}) {
    return prioritySourceData.get(priorityDataId);
  }

  void updatePrioritySourceData({
    required PrioritySourceData updatedData,
  }) {
    final existingData = prioritySourceData.get(updatedData.id);
    if (existingData == null) {
      throw Exception('PrioritySourceData ${updatedData.id} not found');
    }

    prioritySourceData.add(updatedData.id, updatedData);
  }

  void removeAllPrioritySourcesFromZone(String zoneId) {
    if (!zones.exists(zoneId)) return;

    final prioritySources = relationships.getChildren(RelationshipType.zonePriorities, zoneId).toList();
    final prioritySourcesCopy = List<String>.from(prioritySources);
    for (final priorityId in prioritySourcesCopy) {
      relationships.unlink(RelationshipType.zonePriorities, zoneId, priorityId);
      prioritySourceData.remove(priorityId);
    }
  }

  List<String> getPrioritySourcesInZone(String zoneId) {
    final prioritySources = relationships.getChildren(RelationshipType.zonePriorities, zoneId).toList();

    //get sourceIds from priority source data ordered by priority
    final priorityData = prioritySources.map((id) => prioritySourceData.get(id)).where((data) => data != null).cast<PrioritySourceData>().toList();

    // Sort by priority and return source IDs
    priorityData.sort((a, b) => a.priority.compareTo(b.priority));

    final result = <String>[];
    for (int i = 1; i <= 2; i++) {
      final data = priorityData.where((d) => d.priority == i).firstOrNull;
      result.add(data?.sourceId ?? "");
    }

    return result;
  }
}
