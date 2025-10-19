import 'package:fusion_lib/fusion_lib.dart';

import '../project_view_model.dart';

extension SourceSetViewModel on ProjectViewModel {
  //get SourceSet by id
  SourceSet? getSourceSet(String sourceSetId) {
    try {
      return projectManager.getSourceSetById(sourceSetId);
    } catch (e) {
      return null;
    }
  }

  void updateSourceSet(SourceSet sourceSet) {
    try {
      projectManager.updateSourceSet(sourceSet);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update source set: $e");
      throwError("Failed to update source set: $e");
    }
  }

  void updateSourcesInSourceSet(String sourceSetId, List<String> sourceIds) {
    try {
      final List<Source> currentSources = getSourcesInSourceSet(sourceSetId);
      final List<String> currentSourceIds = currentSources.map((Source e) => e.id).toList();
      final List<String> toRemove = currentSourceIds.where((String id) => !sourceIds.contains(id)).toList();
      final List<String> toAdd = sourceIds.where((String id) => !currentSourceIds.contains(id)).toList();
      for (final String id in toRemove) {
        projectManager.removeSourceFromSourceSet(id, sourceSetId);
      }
      for (final String id in toAdd) {
        projectManager.addSourceToSourceSet(id, sourceSetId);
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update sources for source set: $e");
      throwError("Failed to update sources for source set: $e");
    }
  }

  void addSourceSet(SourceSet sourceSet) {
    try {
      projectManager.addSourceSet(sourceSet);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add source set: $e");
      throwError("Failed to add source set: $e");
    }
  }

  void removeSourceSet(String sourceSetId) {
    try {
      projectManager.removeSourceSet(sourceSetId);
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

  List<Source> getSourcesInSourceSet(String sourceSetId) {
    try {
      return projectManager.getSourcesInSourceSet(sourceSetId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get sources in source set: $e");
      return <Source>[];
    }
  }

  //Add Source to SourceSet
  void addSourceToSourceSet(String sourceId, String sourceSetId) {
    try {
      projectManager.addSourceToSourceSet(sourceId, sourceSetId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add source to source set: $e");
      throwError("Failed to add source to source set: $e");
    }
  }

  //Remove Source from SourceSet
  void removeSourceFromSourceSet(String sourceId, String sourceSetId) {
    try {
      projectManager.removeSourceFromSourceSet(sourceId, sourceSetId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove source from source set: $e");
      throwError("Failed to remove source from source set: $e");
    }
  }

  void reorderSourceSetInZone(String parentId, int oldIndex, int newIndex) {
    try {
      projectManager.reOrderSourceInSourceSet(parentId, oldIndex, newIndex);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to reorder sources in source set: $e");
      throwError("Failed to reorder sources in source set: $e");
    }
  }
}
