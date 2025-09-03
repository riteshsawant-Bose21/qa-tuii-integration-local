import 'package:fusion_lib/fusion_lib.dart';

extension SourceSetService on ProjectService {
  /// Add a SourceSet (sourceSet) to repo.
  void addSourceSet(SourceSet sourceSet) {
    if (sourceSets.exists(sourceSet.id)) {
      throw Exception('sourceSet ${sourceSet.id} already exists');
    }
    sourceSets.add(sourceSet.id, sourceSet);
  }

  ///Update SourceSet (sourceSet) in repo.
  void updateSourceSet(SourceSet sourceSet) {
    if (!sourceSets.exists(sourceSet.id)) {
      throw Exception('sourceSet ${sourceSet.id} does not exist');
    }
    sourceSets.add(sourceSet.id, sourceSet);
  }

  /// Remove a sourceSet and unlink it from any zones that referenced it.
  void removeSourceSet(String sourceSetId) {
    if (!sourceSets.exists(sourceSetId)) return;

    // Find zones that reference this sourceSet via relationships
    final parentZones = relationships.getParents(RelationshipType.zoneSourceSet, sourceSetId);

    // Remove sourceSet id from each zone's internal list (if present) and unlink relationship
    for (final zoneId in parentZones) {
      final zone = zones.get(zoneId);
      if (zone != null) {
        zone.sourceSetIds.remove(sourceSetId);
      }
      relationships.unlink(RelationshipType.zoneSourceSet, zoneId, sourceSetId);
    }

    // Remove sourceSet repository entry and all remaining relationships for the sourceSet
    sourceSets.remove(sourceSetId);
    relationships.removeAllRelationships(sourceSetId);
  }

  /// Add a source id into a SourceSet (idempotent).
  /// - Ensures the SourceSet exists (throws otherwise).
  /// - Adds the sourceId to the sourceIds list (if not already present).
  /// - Sets an initial mix level in sourceMixLevels if not present.
  ///
  /// Optionally call onChangeCallback?.call() or persist after this method.
  void addSourceToSourceSet(String sourceId, String sourceSetId, {double initialMixLevel = 1.0}) {
    // Adjust repo name if yours is `mixes` instead of `sourceSets`.
    if (!sourceSets.exists(sourceSetId)) {
      throw Exception('SourceSet $sourceSetId not found');
    }

    final ss = sourceSets.get(sourceSetId)!;

    // Add to id list idempotently
    if (!ss.sourceIds.contains(sourceId)) {
      ss.sourceIds.add(sourceId);
    }

    // Ensure a mix level exists for this source (do not override existing level)
    ss.sourceMixLevels.putIfAbsent(sourceId, () => initialMixLevel);
  }

  /// Remove a source id from a SourceSet (idempotent).
  /// - If SourceSet not found, returns silently.
  /// - Removes from sourceIds and removes any entry from sourceMixLevels.
  void removeSourceFromSourceSet(String sourceId, String sourceSetId) {
    if (!sourceSets.exists(sourceSetId)) return;

    final ss = sourceSets.get(sourceSetId)!;

    // Remove from ids and mix-levels
    ss.sourceIds.remove(sourceId);
    ss.sourceMixLevels.remove(sourceId);
  }

  /// Update mix level for a source inside a SourceSet
  void updateSourceMixLevelInSourceSet(String sourceId, String sourceSetId, double newMixLevel) {
    final sourceSet = sourceSets.get(sourceSetId);
    if (sourceSet == null) throw Exception('SourceSet $sourceSetId not found');

    // If the source is not part of the SourceSet, it's likely a user error.
    // We allow adding the source id into the set if you want, but here we'll require it to exist.
    if (!sourceSet.sourceIds.contains(sourceId)) {
      throw Exception('Source $sourceId is not part of SourceSet $sourceSetId');
    }

    // Update the mix level (adds or replaces the value)
    sourceSet.sourceMixLevels[sourceId] = newMixLevel;
  }

  // Get SourceSet by id
  SourceSet? getSourceSetById(String sourceSetId) {
    return sourceSets.get(sourceSetId);
  }

  // Get all Source in a SourceSet
  List<HardwareComponent> getSourcesInSourceSet(String sourceSetId) {
    final sourceSet = sourceSets.get(sourceSetId);
    if (sourceSet == null) return <HardwareComponent>[];
    return sourceSet.sourceIds.map((s) => getHardwareById(s)).whereType<Source>().toList();
  }
}
