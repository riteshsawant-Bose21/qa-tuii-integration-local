import 'package:fusion_lib/fusion_lib.dart';

extension SceneManager on ProjectManager {
  void addNewScene(SceneModel scene) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addNewScene(scene);
  }

  void updateScene(SceneModel scene) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateScene(scene);
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

  void addSceneActionToScene({required String sceneId, required SceneActionModel action}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addSceneActionToScene(sceneId: sceneId, action: action);
  }

  void removeSceneActionFromScene({required String sceneId, required String actionId}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.removeSceneActionFromScene(sceneId: sceneId, actionId: actionId);
  }

  List<SceneActionModel> getSceneActionsForScene(String sceneId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getSceneActionsForScene(sceneId);
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

  void updateSceneActionParam({required String actionId, required SceneParam param}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateSceneActionParam(actionId: actionId, param: param);
  }

  void updateSceneActionValue({required String actionId, required SceneValue value}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.updateSceneActionValue(actionId: actionId, value: value);
  }

  void deleteScene(String sceneId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.deleteScene(sceneId);
  }

  List<SceneActionType> getSceneActionTypes() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }

    return projectService!.getSceneActionTypes();
  }

  List<SceneItemDropdown> getActionItemsByType(SceneActionType actionType) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }

    return projectService!.getActionItemsByType(actionType);
  }

  List<SceneParam> getParamsByActionTypeAndItem(SceneActionType actionType, SceneItem item) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }

    return projectService!.getParamsByActionTypeAndItem(actionType, item);
  }

  List<SceneValueDropdown> getSceneValueDropdownItems(String actionId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }

    return projectService!.getSceneActionValueDropdownItems(actionId);
  }

  List<SceneModel> getAllScenes() {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getAllScenes();
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

  void addSceneToSceneSet({required String sceneSetId, required String sceneId}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addSceneToSceneSet(sceneSetId: sceneSetId, sceneId: sceneId);
  }

  void removeSceneFromSceneSet({required String sceneSetId, required String sceneId}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.removeSceneFromSceneSet(sceneSetId: sceneSetId, sceneId: sceneId);
  }

  void addNewSceneToSceneSet({required String sceneSetId, required SceneModel scene}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.addNewSceneToSceneSet(sceneSetId: sceneSetId, scene: scene);
  }

  List<SceneModel> getScenesInSceneSet(String sceneSetId) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    return projectService!.getScenesInSceneSet(sceneSetId);
  }

  void reOrderScenesInSceneSet({required String parentId, required int oldIndex, required int newIndex}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.reOrderScenesInSceneSet(parentId, oldIndex, newIndex);
  }

  void reOderSceneActionsInScene({required String sceneId, required int oldIndex, required int newIndex}) {
    if (projectService == null) {
      throw Exception("Project service is not initialized.");
    }
    projectService!.reOderSceneActionsInScene(sceneId, oldIndex, newIndex);
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

  void reOderScenes({required String sceneIdToMove, required String sceneAtNewIndex}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    Map<String, SceneModel> reorderedList = projectService!.reOderScenes(
      sceneIdToMove: sceneIdToMove,
      sceneAtNewIndexId: sceneAtNewIndex,
    );

    projectService = projectService!.copyWith(
      scenesRepository: projectService!.scenes.copyWith(reorderedList),
    );
  }
}
