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

  void updateSourcesInSourceSet(String sourceSetId, List<String> sourceIds) {
    if (!sourceSets.exists(sourceSetId)) {
      throw Exception('sourceSet $sourceSetId does not exist');
    }

    //find difference between current and new
    final currentSources = relationships.getChildren(RelationshipType.sourceSetSources, sourceSetId);

    final currentSourceCopy = List<String>.from(currentSources);

    final sourcesToRemove = currentSourceCopy.where((s) => !sourceIds.contains(s)).toList();
    final sourcesToAdd = sourceIds.where((s) => !currentSourceCopy.contains(s)).toList();

    //remove
    for (var source in sourcesToRemove) {
      relationships.unlink(RelationshipType.sourceSetSources, sourceSetId, source);
    }

    //to  add
    for (var source in sourcesToAdd) {
      relationships.link(RelationshipType.sourceSetSources, sourceSetId, source);
    }

    final sourcesInSet = relationships.getChildren(RelationshipType.sourceSetSources, sourceSetId);
    if (sourcesInSet.isEmpty || sourceSetId.length == 1) {
      removeSourceSet(sourceSetId);
    }
  }

  /// Remove a sourceSet and unlink it from any zones that referenced it.
  void removeSourceSet(String sourceSetId) {
    if (!sourceSets.exists(sourceSetId)) return;

    // Find zones that reference this sourceSet via relationships
    relationships.getParents(RelationshipType.zoneSourceSet, sourceSetId);

    // Remove sourceSet id from each zone's internal list (if present) and unlink relationship
    relationships.removeAllRelationships(sourceSetId);

    // Remove sourceSet repository entry and all remaining relationships for the sourceSet
    sourceSets.remove(sourceSetId);
  }

  /// Add a source id into a SourceSet (idempotent).
  /// - Ensures the SourceSet exists (throws otherwise).
  /// - Adds the sourceId to the sourceIds list (if not already present).
  /// - Sets an initial mix level in sourceMixLevels if not present.
  ///
  /// Optionally call onChangeCallback?.call() or persist after this method.
  void addSourceToSourceSet(String sourceId, String sourceSetId, {double? initialMixLevel}) {
    // Adjust repo name if yours is `mixes` instead of `sourceSets`.
    if (!sourceSets.exists(sourceSetId)) {
      throw Exception('SourceSet $sourceSetId not found');
    }

    // Add to id list idempotently
    relationships.link(RelationshipType.sourceSetSources, sourceSetId, sourceId);
  }

  /// Remove a source id from a SourceSet (idempotent).
  /// - If SourceSet not found, returns silently.
  void removeSourceFromSourceSet(String sourceId, String sourceSetId) {
    if (!sourceSets.exists(sourceSetId)) return;

    relationships.unlink(RelationshipType.sourceSetSources, sourceSetId, sourceId);

    final sourcesInSet = relationships.getChildren(RelationshipType.sourceSetSources, sourceSetId);
    if (sourcesInSet.isEmpty || sourcesInSet.length == 1) {
      print('Removing empty SourceSet: $sourceSetId and length is ${sourcesInSet.length}');
      removeSourceSet(sourceSetId);
    }
  }

  // Get SourceSet by id
  SourceSet? getSourceSetById(String sourceSetId) {
    return sourceSets.get(sourceSetId);
  }

  SourceSet? getSourceSetForSource(String sourceId) {
    final parentId = relationships.getParent(RelationshipType.sourceSetSources, sourceId);
    if (parentId == null) return null;
    return getSourceSetById(parentId);
  }

  // Get all Source in a SourceSet
  List<Source> getSourcesInSourceSet(String sourceSetId) {
    final sourcesInSet = relationships.getChildren(RelationshipType.sourceSetSources, sourceSetId);
    if (sourcesInSet.isEmpty) return <Source>[];
    return sourcesInSet.map((s) => getHardwareById(s)).whereType<Source>().toList();
  }

  List<Source> getSourcesWithoutSourceSet() {
    final allSources = getAllHardware().whereType<Source>().toList();
    List<Source> sourcesWithoutSourceSet = [];
    for (var source in allSources) {
      //if no source set parent then add it
      if (relationships.getParent(RelationshipType.sourceSetSources, source.id) == null) {
        sourcesWithoutSourceSet.add(source);
      }
    }
    return sourcesWithoutSourceSet;
  }

  void reOrderSourcesInSourceSet(String parentId, int oldIndex, int newIndex) {
    final sourceSetSources = relationships.getChildren(RelationshipType.sourceSetSources, parentId).toList();

    final item = sourceSetSources.removeAt(oldIndex);
    sourceSetSources.insert(newIndex, item);

    relationships.reOrder(RelationshipType.sourceSetSources, parentId, sourceSetSources);
  }
}
