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
      return projectManager.getSourcesInSourceSet(sourceSetId) as List<Source>;
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
}
