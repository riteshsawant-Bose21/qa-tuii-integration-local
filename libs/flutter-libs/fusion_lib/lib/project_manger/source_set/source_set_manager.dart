import 'package:fusion_lib/fusion_lib.dart';

extension SourceSetManager on ProjectManager {
  //Add SourceSet
  void addSourceSet(SourceSet sourceSet) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    if (projectService!.sourceSets.exists(sourceSet.id)) {
      throw Exception('SourceSet with id ${sourceSet.id} already exists');
    }
    projectService!.sourceSets.add(sourceSet.id, sourceSet);
  }

  /// Remove SourceSet
  void removeSourceSet(String sourceSetId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.sourceSets.remove(sourceSetId);
  }

  ///Update SourceSet
  void updateSourceSet(SourceSet sourceSet) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    if (!projectService!.sourceSets.exists(sourceSet.id)) {
      throw Exception('SourceSet with id ${sourceSet.id} does not exist');
    }
    projectService!.sourceSets.add(sourceSet.id, sourceSet);
  }

  List<SourceSet> getAllSourceSets() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.sourceSets.getAll();
  }

  //Add Source to SourceSet
  void addSourceToSourceSet(String sourceId, String sourceSetId, {double? initialMixLevel}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addSourceToSourceSet(sourceId, sourceSetId, initialMixLevel: initialMixLevel);
  }

  // Remove Source from SourceSet
  void removeSourceFromSourceSet(String sourceId, String sourceSetId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeSourceFromSourceSet(sourceId, sourceSetId);
  }

  // Update Source Mix Level in SourceSet
  void updateSourceMixLevelInSourceSet(String sourceId, String sourceSetId, double newMixLevel) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateSourceMixLevelInSourceSet(sourceId, sourceSetId, newMixLevel);
  }

  // Get SourceSet by id
  SourceSet? getSourceSetById(String sourceSetId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getSourceSetById(sourceSetId);
  }

  // Get all Sources in a SourceSet
  List<Source> getSourcesInSourceSet(String sourceSetId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getSourcesInSourceSet(sourceSetId);
  }

  void reOrderSourceInSourceSet(String parentId, int oldIndex, int newIndex) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.reOrderSourcesInSourceSet(parentId, oldIndex, newIndex);
  }
}
