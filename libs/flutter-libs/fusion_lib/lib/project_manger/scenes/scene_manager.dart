import 'package:fusion_lib/fusion_lib.dart';

extension SceneManager on ProjectManager {
  void addNewSnapshots(SnapshotsModel scene) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addNewSnapshots(scene);
  }

  void updateSnapshots(SnapshotsModel scene) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateSnapshots(scene);
  }

  void addNewSceneAction(SceneActionModel action) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addNewSceneAction(action: action);
  }

  void removeSceneAction(String actionId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.removeSceneAction(actionId);
  }

  void addSceneActionToSnapshot({required String sceneId, required SceneActionModel action}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addSceneActionToSnapshot(sceneId: sceneId, action: action);
  }

  void removeSceneActionFromSnapshot({required String sceneId, required String actionId}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.removeSceneActionFromSnapshot(sceneId: sceneId, actionId: actionId);
  }

  List<SceneActionModel> getSceneActionsForSnapshot(String sceneId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getSceneActionsForSnapshot(sceneId);
  }

  void updateSceneActionType({required String actionId, required SceneActionType actionType}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateSceneActionType(actionType: actionType, actionId: actionId);
  }

  void updateSceneActionItem({required String actionId, required SceneItem item}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateSceneActionItem(actionId: actionId, item: item);
  }

  void updateSceneActionParam({required String actionId, required SceneParam param, String? eventId}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateSceneActionParam(actionId: actionId, param: param, eventId: eventId);
  }

  void updateSceneActionValue({required String actionId, required SceneValue value}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateSceneActionValue(actionId: actionId, value: value);
  }

  void removeSnapshots(String sceneId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.removeSnapshots(sceneId);
  }

  List<SceneActionType> getSceneActionTypes({String? eventId}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }

    return projectService!.getSceneActionTypes(eventId: eventId);
  }

  List<SceneItemDropdown> getActionItemsByType(SceneActionType actionType) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }

    return projectService!.getActionItemsByType(actionType);
  }

  List<SceneParam> getParamsByActionTypeAndItem({required SceneActionType actionType, required SceneItem item, String? eventId}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }

    return projectService!.getParamsByActionTypeAndItem(actionType: actionType, item: item, eventId: eventId);
  }

  List<SceneValueDropdown> getSceneValueDropdownItems(String actionId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }

    return projectService!.getSceneActionValueDropdownItems(actionId);
  }

  List<SnapshotsModel> getAllSnapshots() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getAllSnapshots();
  }

  SnapshotsModel? getSnapshotById(String sceneId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getSnapshotById(sceneId);
  }

  //scene sets
  void addNewSceneSet(SceneSetModel sceneSet) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addNewSceneSet(sceneSet);
  }

  void updateSceneSet(SceneSetModel sceneSet) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateSceneSet(sceneSet);
  }

  void deleteSceneSet(String sceneSetId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.deleteSceneSet(sceneSetId);
  }

  List<SceneSetModel> getAllSceneSets() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getAllSceneSets();
  }

  void addSnapshotToSceneSet({required String sceneSetId, required String sceneId}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addSnapshotToSceneSet(sceneSetId: sceneSetId, sceneId: sceneId);
  }

  void removeSnapshotFromSceneSet({required String sceneSetId, required String sceneId}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.removeSnapshotFromSceneSet(sceneSetId: sceneSetId, sceneId: sceneId);
  }

  void addNewSnapshotToSceneSet({required String sceneSetId, required SnapshotsModel scene}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addNewSnapshotToSceneSet(sceneSetId: sceneSetId, scene: scene);
  }

  List<SnapshotsModel> getSnapshotInSceneSet(String sceneSetId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getSnapshotInSceneSet(sceneSetId);
  }

  void reOrderSnapshotInSceneSet({required String parentId, required int oldIndex, required int newIndex}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.reOrderSnapshotInSceneSet(parentId, oldIndex, newIndex);
  }

  void reOderSceneActionsInSnapshot({required String sceneId, required int oldIndex, required int newIndex}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.reOderSceneActionsInSnapshot(sceneId, oldIndex, newIndex);
  }

  void reOrderSceneSets({required String sceneSetIdToMove, required String sceneSetAtNewIndex}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    Map<String, SceneSetModel> reorderedList = projectService!.reOderSceneSets(
      sceneSetIdToMove: sceneSetIdToMove,
      sceneSetAtNewIndexId: sceneSetAtNewIndex,
    );

    projectService = projectService!.copyWith(
      sceneSetRepository: projectService!.sceneSets.copyWith(reorderedList),
    );
  }

  void reOderSnapshots({required String sceneIdToMove, required String sceneAtNewIndex}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    Map<String, SnapshotsModel> reorderedList = projectService!.reOderSnapshots(
      sceneIdToMove: sceneIdToMove,
      sceneAtNewIndexId: sceneAtNewIndex,
    );

    projectService = projectService!.copyWith(
      scenesRepository: projectService!.snapshots.copyWith(reorderedList),
    );
  }

  void duplicateSnapshot(String sceneId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.duplicateSnapshot(sceneId);
  }

  void duplicateSceneSet(String sceneSetId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.duplicateSceneSet(sceneSetId);
  }

  void duplicateSceneAction(String actionId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.duplicateSceneAction(actionId);
  }
}
