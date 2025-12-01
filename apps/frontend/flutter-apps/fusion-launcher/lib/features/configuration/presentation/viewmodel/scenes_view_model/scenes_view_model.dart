import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension ScenesViewModel on ProjectViewModel {
  void addNewScene({required SceneModel scene, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addNewScene(scene);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add New Scene Error  ${e.toString()}");
    }
  }

  void updateScene({required SceneModel scene, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateScene(scene);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update Scene Error  ${e.toString()}");
    }
  }

  void deleteScene({required String sceneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.deleteScene(sceneId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Delete Scene Error  ${e.toString()}");
    }
  }

  void addNewSceneAction({required SceneActionModel action, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addNewSceneAction(action);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add New Scene Action Error  ${e.toString()}");
    }
  }

  void removeSceneAction({required String actionId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSceneAction(actionId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Remove Scene Action Error  ${e.toString()}");
    }
  }

  void addSceneActionToScene({required String sceneId, required SceneActionModel action, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addSceneActionToScene(sceneId: sceneId, action: action);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add Scene Action To Scene Error  ${e.toString()}");
    }
  }

  void removeSceneActionFromScene({required String sceneId, required String actionId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSceneActionFromScene(sceneId: sceneId, actionId: actionId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Remove Scene Action From Scene Error  ${e.toString()}");
    }
  }

  List<SceneActionModel> getSceneActionsForScene(String sceneId) {
    try {
      return projectManager.getSceneActionsForScene(sceneId);
    } catch (e) {
      throwError("Get Scene Actions For Scene Error  ${e.toString()}");
      return <SceneActionModel>[];
    }
  }

  void updateSceneActionType({required String actionId, required SceneActionType actionType, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSceneActionType(actionId: actionId, actionType: actionType);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update Scene Action Type Error  ${e.toString()}");
    }
  }

  void updateSceneActionItem({required String actionId, required SceneItem item, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSceneActionItem(actionId: actionId, item: item);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update Scene Item Error  ${e.toString()}");
    }
  }

  void updateSceneActionParam({required String actionId, required SceneParam param, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSceneActionParam(actionId: actionId, param: param);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update Scene Param Error  ${e.toString()}");
    }
  }

  void updateSceneActionValue({required String actionId, required SceneValue value, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSceneActionValue(actionId: actionId, value: value);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update Scene Value Error  ${e.toString()}");
    }
  }

  List<SceneActionType> getSceneActionTypes() {
    try {
      return projectManager.getSceneActionTypes();
    } catch (e) {
      throwError("Get Scene Action Types Error  ${e.toString()}");
      return <SceneActionType>[];
    }
  }

  List<SceneItemDropdown> getActionItemsByType(SceneActionType actionType) {
    try {
      return projectManager.getActionItemsByType(actionType);
    } catch (e) {
      throwError("Get Action Items By Type Error  ${e.toString()}");
      return <SceneItemDropdown>[];
    }
  }

  List<SceneParam> getParamsByActionTypeAndItem(SceneActionType actionType, SceneItem item) {
    try {
      return projectManager.getParamsByActionTypeAndItem(actionType, item);
    } catch (e) {
      throwError("Get Params By Action Type And Item Error  ${e.toString()}");
      return <SceneParam>[];
    }
  }

  List<SceneValueDropdown> getSceneValueDropdownItems(String sceneId) {
    try {
      return projectManager.getSceneValueDropdownItems(sceneId);
    } catch (e) {
      throwError("Get Scene Value Dropdown Items Error  ${e.toString()}");
      return <SceneValueDropdown>[];
    }
  }

  List<SceneModel> getAllScenes() {
    try {
      return projectManager.getAllScenes();
    } catch (e) {
      throwError("Get All Scenes Error  ${e.toString()}");
      return <SceneModel>[];
    }
  }

  //Scene set
  void addNewSceneSet({required SceneSetModel sceneSet, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addNewSceneSet(sceneSet);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add New Scene Set Error  ${e.toString()}");
    }
  }

  void updateSceneSet({required SceneSetModel sceneSet, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSceneSet(sceneSet);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update Scene Set Error  ${e.toString()}");
    }
  }

  void deleteSceneSet({required String sceneSetId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.deleteSceneSet(sceneSetId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Delete Scene Set Error  ${e.toString()}");
    }
  }

  List<SceneSetModel> getAllSceneSets() {
    try {
      return projectManager.getAllSceneSets();
    } catch (e) {
      throwError("Get All Scene Sets Error  ${e.toString()}");
      return <SceneSetModel>[];
    }
  }

  void addSceneToSceneSet({required String sceneSetId, required String sceneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addSceneToSceneSet(sceneSetId: sceneSetId, sceneId: sceneId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add Scene To Scene Set Error  ${e.toString()}");
    }
  }

  void removeSceneFromSceneSet({required String sceneSetId, required String sceneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSceneFromSceneSet(sceneSetId: sceneSetId, sceneId: sceneId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Remove Scene From Scene Set Error  ${e.toString()}");
    }
  }

  void addNewSceneToSceneSet({required String sceneSetId, required SceneModel scene, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addNewSceneToSceneSet(sceneSetId: sceneSetId, scene: scene);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add New Scene To Scene Set Error  ${e.toString()}");
    }
  }

  List<SceneModel> getScenesInSceneSet(String sceneSetId) {
    try {
      return projectManager.getScenesInSceneSet(sceneSetId);
    } catch (e) {
      throwError("Get Scenes In Scene Set Error  ${e.toString()}");
      return <SceneModel>[];
    }
  }
}
