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

      //also unlink from any zones since its added to source set
      final parentZone = relationships.getParent(RelationshipType.zoneSources, source);
      if (parentZone != null) {
        relationships.unlink(RelationshipType.zoneSources, parentZone, source);
      }
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
  void addSourceToSourceSet(
    String sourceId,
    String sourceSetId,
  ) {
    // Adjust repo name if yours is `mixes` instead of `sourceSets`.
    if (!sourceSets.exists(sourceSetId)) {
      throw Exception('SourceSet $sourceSetId not found');
    }

    //remove current parent
    final currentParent = relationships.getParent(RelationshipType.sourceSetSources, sourceId);
    if (currentParent != null && currentParent != sourceSetId) {
      relationships.unlink(RelationshipType.sourceSetSources, currentParent, sourceId);
    }

    // Add to id list idempotently
    relationships.link(RelationshipType.sourceSetSources, sourceSetId, sourceId);

    //also unlink from any zones since its added to source set
    final parentZone = relationships.getParent(RelationshipType.zoneSources, sourceId);
    if (parentZone != null) {
      relationships.unlink(RelationshipType.zoneSources, parentZone, sourceId);
    }
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

  /// Determine if source set can be linked
  /// Returns true if all sources in the set have the same type and processing blocks
  bool canLinkSourceSet(String sourceSetId) {
    final sourcesInSet = relationships.getChildren(RelationshipType.sourceSetSources, sourceSetId);

    // Early return for empty or single source sets
    if (sourcesInSet.length <= 1) return sourcesInSet.isNotEmpty;

    // Use iterator to avoid creating a list copy
    final iterator = sourcesInSet.iterator;
    if (!iterator.moveNext()) return false;

    // Get reference source properties
    final firstSourceId = iterator.current;
    final firstSource = getHardwareById(firstSourceId) as Source?;
    if (firstSource == null) return false;

    final referenceType = firstSource.type;
    final referenceBlocks = getProcessingBlockFor(firstSourceId);

    // Check remaining sources against reference using iterator
    while (iterator.moveNext()) {
      final sourceId = iterator.current;
      final source = getHardwareById(sourceId) as Source?;

      // Early return on type mismatch or null source
      if (source == null || source.type != referenceType) return false;

      final blocks = getProcessingBlockFor(sourceId);

      // Fast length check first
      if (blocks.length != referenceBlocks.length) return false;

      // Efficient element-by-element comparison
      // Use every() for more efficient comparison - stops at first mismatch
      if (!blocks.asMap().entries.every((entry) => entry.value.algorithmId == referenceBlocks[entry.key].algorithmId)) return false;
    }

    return true;
  }

  void linkSourceSet({required String sourceSetId}) {
    final sourceSet = getSourceSetById(sourceSetId);
    if (sourceSet == null) {
      throw Exception('SourceSet $sourceSetId not found');
    }

    List<Source> sourcesInSet = getSourcesInSourceSet(sourceSetId);
    if (sourcesInSet.length >= 2) {
      final processingBlocks = getProcessingBlockFor(sourcesInSet.first.id);
      for (var source in sourcesInSet) {
        if (source.id == sourcesInSet.first.id) continue;
        //copy processing block properties form first source
        final sourceBlocks = getProcessingBlockFor(sourcesInSet.first.id);
        for (var i = 0; i < sourceBlocks.length; i++) {
          final updatedBlock = sourceBlocks[i].copyProperties(model: processingBlocks[i]);
          updateProcessingBlock(updatedBlock);
        }
      }
    }

    sourceSets.add(sourceSetId, sourceSet.copyWith(isLinked: true));
  }

  void unlinkSourceSet({required String sourceSetId}) {
    final sourceSet = getSourceSetById(sourceSetId);
    if (sourceSet == null) {
      throw Exception('SourceSet $sourceSetId not found');
    }

    sourceSets.add(sourceSetId, sourceSet.copyWith(isLinked: false));
  }

  //add Processing block to source,
  // if source in source set and source set is linked then add processing block to all the sources in that source set
  void addProcessingBlockToSource({required String sourceId, required ProcessingBlockModel processingBlock}) {
    final source = getHardwareById(sourceId) as Source?;
    if (source == null) return;
    addProcessingBlockToParent(processingBlock, sourceId);

    final sourceSet = getSourceSetForSource(sourceId);
    if (sourceSet == null) return;

    if (sourceSet.isLinked) {
      print('Source set is linked, adding processing block to all sources in set');
      final sourcesInSet = relationships.getChildren(RelationshipType.sourceSetSources, sourceSet.id);

      for (var source in sourcesInSet) {
        //we already added this processing block to the source so skip it
        if (source == sourceId) continue;

        //add processing block to other sources in set cloned from current processing block
        addProcessingBlockToParent(processingBlock.clone(), source);
      }
    }
  }

  void removeProcessingBlockFromSource({required String sourceId, required String processingBlockId}) {
    final source = getHardwareById(sourceId) as Source?;
    if (source == null) return;

    //get the index
    final allBlocksInSource = relationships.getChildren(RelationshipType.processingBlock, sourceId).toList();
    final indexOfProcessingBlock = allBlocksInSource.indexOf(processingBlockId);

    removeProcessingBlockFromParent(processingBlockId, sourceId);

    final sourceSet = getSourceSetForSource(sourceId);
    if (sourceSet == null) return;

    if (sourceSet.isLinked) {
      final sourcesInSet = relationships.getChildren(RelationshipType.sourceSetSources, sourceSet.id);

      for (var source in sourcesInSet) {
        if (source == sourceId) continue;

        final allBlocksInOtherSource = relationships.getChildren(RelationshipType.processingBlock, source).toList();
        final indexOfProcessingBlockInOtherSource = allBlocksInOtherSource.indexOf(processingBlockId);

        if (indexOfProcessingBlockInOtherSource == -1) {
          throw (Exception('Processing block $processingBlockId not found in source $source'));
        }

        final processingBlockToRemove = allBlocksInOtherSource[indexOfProcessingBlockInOtherSource];

        removeProcessingBlockFromParent(processingBlockToRemove, source);
      }
    }
  }

  // Update Processing block in source
  void updateProcessingBlockInSource({required String sourceId, required ProcessingBlockModel processingBlock}) {
    final source = getHardwareById(sourceId) as Source?;
    if (source == null) return;
    //update
    updateProcessingBlock(processingBlock);

    final sourceSet = getSourceSetForSource(sourceId);
    if (sourceSet == null) return;

    if (sourceSet.isLinked) {
      final sourcesInSet = relationships.getChildren(RelationshipType.sourceSetSources, sourceSet.id);

      //get the index of currently updated processing block
      final allBlocksInSource = relationships.getChildren(RelationshipType.processingBlock, sourceId).toList();
      final index = allBlocksInSource.indexOf(processingBlock.id);

      for (var source in sourcesInSet) {
        //skip for current source
        if (source == sourceId) continue;

        final allBlocksInOtherSource = relationships.getChildren(RelationshipType.processingBlock, source).toList();

        final processingBlockId = allBlocksInOtherSource[index];

        //get processing block
        final processingBlockToUpdated = getProcessingBlock(processingBlockId);

        if (processingBlockToUpdated == null) {
          throw Exception('Processing block $processingBlockId not found');
        }

        //update processing block in other sources in set cloned from current processing block
        updateProcessingBlock(processingBlockToUpdated.copyProperties(model: processingBlock));
      }
    }
  }

  Map<String, SourceSet> reOrderSourceSet({
    required String sourceSetToMoveId,
    required String sourceSetAtNewIndexId,
  }) {
    List<SourceSet> items = sourceSets.getAll();

    // Find indices
    int fromIndex = items.indexWhere((ss) => ss.id == sourceSetToMoveId);
    int toIndex = items.indexWhere((ss) => ss.id == sourceSetAtNewIndexId);

    // Validate
    if (fromIndex == -1 || toIndex == -1) {
      throw ArgumentError('Invalid hardware IDs');
    }

    // Reorder using List operations
    SourceSet item = items.removeAt(fromIndex);
    items.insert(toIndex, item);

    // Convert back to Map
    return {for (var ss in items) ss.id: ss};
  }
}
