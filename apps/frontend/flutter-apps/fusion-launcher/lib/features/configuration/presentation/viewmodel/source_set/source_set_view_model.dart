import 'package:fusion_lib/fusion_lib.dart';

import '../project_view_model.dart';

extension SourceSetViewModel on ProjectViewModel {
  //get SourceSet by id
  SourceSet? getSourceSet({required String sourceSetId}) {
    try {
      return projectManager.getSourceSetById(sourceSetId);
    } catch (e) {
      return null;
    }
  }

  void updateSourceSet({required SourceSet sourceSet, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSourceSet(sourceSet);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update source set: $e");
      throwError("Failed to update source set: $e");
    }
  }

  // void updateSourcesInSourceSet({required String sourceSetId, required List<String> sourceIds, bool autoSave = true}) {
  //   try {
  //     if (autoSave) {
  //       recordSnapshot();
  //     }
  //     final List<Source> currentSources = getSourcesInSourceSet(sourceSetId: sourceSetId);
  //     final List<String> currentSourceIds = currentSources.map((Source e) => e.id).toList();
  //     final List<String> toRemove = currentSourceIds.where((String id) => !sourceIds.contains(id)).toList();
  //     final List<String> toAdd = sourceIds.where((String id) => !currentSourceIds.contains(id)).toList();
  //     for (final String id in toRemove) {
  //       projectManager.removeSourceFromSourceSet(id, sourceSetId);
  //     }
  //     for (final String id in toAdd) {
  //       projectManager.addSourceToSourceSet(id, sourceSetId);
  //     }
  //     if (autoSave) {
  //       saveProject();
  //     }
  //     updateProject();
  //   } catch (e) {
  //     FusionLogger.log(tag: LogTag.project, message: "Failed to update sources for source set: $e");
  //     throwError("Failed to update sources for source set: $e");
  //   }
  // }

  void addSourceSet({required SourceSet sourceSet, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addSourceSet(sourceSet);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add source set: $e");
      throwError("Failed to add source set: $e");
    }
  }

  void removeSourceSet({required String sourceSetId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSourceSet(sourceSetId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove source set: $e");
      throwError("Failed to remove source set: $e");
    }
  }

  List<SourceSet> getAllSourceSets() {
    try {
      return projectManager.getAllSourceSets();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all source sets: $e");
      return <SourceSet>[];
    }
  }

  List<Source> getSourcesInSourceSet({required String sourceSetId}) {
    try {
      return projectManager.getSourcesInSourceSet(sourceSetId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get sources in source set: $e");
      return <Source>[];
    }
  }

  List<Source> getSourcesWithoutSourceSet() {
    try {
      return projectManager.getSourcesWithoutSourceSet();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get sources without source set: $e");
      return <Source>[];
    }
  }

  SourceSet? getSourceSetForSource({required String sourceId}) {
    try {
      return projectManager.getSourceSetForSource(sourceId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get source set for source: $e");
      return null;
    }
  }

  void updateSourcesInSourceSet({required String sourceSetId, required List<String> sourceIds, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }

      projectManager.updateSourcesInSourceSet(sourceSetId, sourceIds);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update sources for source set: $e");
      throwError("Failed to update sources for source set: $e");
    }
  }

  //Add Source to SourceSet
  void addSourceToSourceSet({required String sourceId, required String sourceSetId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addSourceToSourceSet(sourceId, sourceSetId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add source to source set: $e");
      throwError("Failed to add source to source set: $e");
    }
  }

  //Remove Source from SourceSet
  void removeSourceFromSourceSet({required String sourceId, required String sourceSetId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSourceFromSourceSet(sourceId, sourceSetId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove source from source set: $e");
      throwError("Failed to remove source from source set: $e");
    }
  }

  void reorderSourceSetInZone({required String parentId, required int oldIndex, required int newIndex, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOrderSourceInSourceSet(parentId, oldIndex, newIndex);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to reorder sources in source set: $e");
      throwError("Failed to reorder sources in source set: $e");
    }
  }

  bool canLinkSourceSet({required String sourceSetId}) {
    try {
      return projectManager.canLinkSourceSet(sourceSetId: sourceSetId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to check if source set can be linked: $e");
      return false;
    }
  }

  void addProcessingBlockToSource({required String sourceId, required ProcessingBlockModel processingBlock, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addProcessingBlockToSource(sourceId: sourceId, processingBlock: processingBlock);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add processing block to source: $e");
      throwError("Failed to add processing block to source: $e");
    }
  }

  void removeProcessingBlockFromSource({required String sourceId, required String processingBlockId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeProcessingBlockFromSource(sourceId: sourceId, processingBlockId: processingBlockId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove processing block from source: $e");
      throwError("Failed to remove processing block from source: $e");
    }
  }

  void updateProcessingBlockInSource({required String sourceId, required ProcessingBlockModel processingBlock, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateProcessingBlockInSource(sourceId: sourceId, processingBlock: processingBlock);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update processing block in source: $e");
      throwError("Failed to update processing block in source: $e");
    }
  }

  void linkSourceSet({required String sourceSetId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.linkSourceSet(sourceSetId: sourceSetId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to link source set: $e");
      throwError("Failed to link source set: $e");
    }
  }

  void unlinkSourceSet({required String sourceSetId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.unlinkSourceSet(sourceSetId: sourceSetId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to unlink source set: $e");
      throwError("Failed to unlink source set: $e");
    }
  }
}
