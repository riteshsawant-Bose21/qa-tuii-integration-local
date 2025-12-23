import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension ScenesViewModel on ProjectViewModel {
  void addNewSnapshots({required SnapshotsModel scene, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addNewSnapshots(scene);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add New Scene Error  ${e.toString()}");
    }
  }

  void updateSnapshots({required SnapshotsModel scene, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSnapshots(scene);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Update Scene Error  ${e.toString()}");
    }
  }

  void removeSnapshots({required String sceneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSnapshots(sceneId);
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

  void addSceneActionToSnapshot({required String sceneId, required SceneActionModel action, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addSceneActionToSnapshot(sceneId: sceneId, action: action);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add Scene Action To Scene Error  ${e.toString()}");
    }
  }

  void removeSceneActionFromSnapshot({required String sceneId, required String actionId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSceneActionFromSnapshot(sceneId: sceneId, actionId: actionId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Remove Scene Action From Scene Error  ${e.toString()}");
    }
  }

  List<SceneActionModel> getSceneActionsForSnapshot(String sceneId) {
    try {
      return projectManager.getSceneActionsForSnapshot(sceneId);
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

  void updateSceneActionParam({required String actionId, required SceneParam param, String? eventId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSceneActionParam(actionId: actionId, param: param, eventId: eventId);
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

  List<SceneActionType> getSceneActionTypes({String? eventId}) {
    try {
      return projectManager.getSceneActionTypes(eventId: eventId);
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

  List<SceneParam> getParamsByActionTypeAndItem({required SceneActionType actionType, required SceneItem item, String? eventId}) {
    try {
      return projectManager.getParamsByActionTypeAndItem(actionType: actionType, item: item, eventId: eventId);
    } catch (e) {
      throwError("Get Params By Action Type And Item Error  ${e.toString()}");
      return <SceneParam>[];
    }
  }

  List<SceneValueDropdown> getSceneValueDropdownItems(String actionId) {
    try {
      return projectManager.getSceneValueDropdownItems(actionId);
    } catch (e) {
      throwError("Get Scene Value Dropdown Items Error  ${e.toString()}");
      return <SceneValueDropdown>[];
    }
  }

  List<SnapshotsModel> getAllSnapshots() {
    try {
      return projectManager.getAllSnapshots();
    } catch (e) {
      throwError("Get All Scenes Error  ${e.toString()}");
      return <SnapshotsModel>[];
    }
  }

  SnapshotsModel? getSnapshotById({required String sceneId}) {
    try {
      return projectManager.getSnapshotById(sceneId);
    } catch (e) {
      throwError("Get Scene By Id Error  ${e.toString()}");
      return null; // return empty scene model on error
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

  void removeSceneSet({required String sceneSetId, bool autoSave = true}) {
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

  void addSnapshotToSceneSet({required String sceneSetId, required String sceneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addSnapshotToSceneSet(sceneSetId: sceneSetId, sceneId: sceneId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add Scene To Scene Set Error  ${e.toString()}");
    }
  }

  void removeSnapshotFromSceneSet({required String sceneSetId, required String sceneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSnapshotFromSceneSet(sceneSetId: sceneSetId, sceneId: sceneId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Remove Scene From Scene Set Error  ${e.toString()}");
    }
  }

  void addNewSnapshotToSceneSet({required String sceneSetId, required SnapshotsModel scene, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addNewSnapshotToSceneSet(sceneSetId: sceneSetId, scene: scene);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Add New Scene To Scene Set Error  ${e.toString()}");
    }
  }

  List<SnapshotsModel> getSnapshotInSceneSet({required String sceneSetId}) {
    try {
      return projectManager.getSnapshotInSceneSet(sceneSetId);
    } catch (e) {
      throwError("Get Scenes In Scene Set Error  ${e.toString()}");
      return <SnapshotsModel>[];
    }
  }

  void reOrderSnapshotInSceneSet({required String sceneSetId, required int oldIndex, required int newIndex, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOrderSnapshotInSceneSet(parentId: sceneSetId, oldIndex: oldIndex, newIndex: newIndex);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Reorder Scenes In Scene Set Error  ${e.toString()}");
    }
  }

  void reOderSceneSets({required String sceneSetIdToMove, required String sceneSetAtNewIndex, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOrderSceneSets(sceneSetIdToMove: sceneSetIdToMove, sceneSetAtNewIndex: sceneSetAtNewIndex);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Reorder Scene Sets Error  ${e.toString()}");
    }
  }

  void reOderSceneActionsInSnapshot({required String sceneId, required int oldIndex, required int newIndex, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOderSceneActionsInSnapshot(sceneId: sceneId, oldIndex: oldIndex, newIndex: newIndex);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Reorder Scene Actions In Scene Error  ${e.toString()}");
    }
  }

  void reOderSnapshots({required String sceneIdToMove, required String sceneIdAtNewIndex, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOderSnapshots(sceneIdToMove: sceneIdToMove, sceneAtNewIndex: sceneIdAtNewIndex);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Reorder Scenes Error  ${e.toString()}");
    }
  }

  void duplicateSnapshot({required String sceneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.duplicateSnapshot(sceneId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Duplicate Scene Error  ${e.toString()}");
    }
  }

  void duplicateSceneSet({required String sceneSetId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.duplicateSceneSet(sceneSetId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Duplicate Scene Set Error  ${e.toString()}");
    }
  }

  void duplicateSceneAction({required String actionId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.duplicateSceneAction(actionId);
      if (autoSave) {
        saveProject();
      }
    } catch (e) {
      throwError("Duplicate Scene Action Error  ${e.toString()}");
    }
  }
}
