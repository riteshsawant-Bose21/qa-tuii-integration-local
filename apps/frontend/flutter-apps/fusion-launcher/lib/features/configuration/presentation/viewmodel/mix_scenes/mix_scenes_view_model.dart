import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension MixScenesViewModel on ProjectViewModel {
  MixScene? getSelectedMixSceneForFunction(String functionId) {
    try {
      return projectManager.getSelectedMixSceneForFunction(functionId);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get selected mix scene for function : $ex");
      throwError("Failed to get selected mix scene for function : $ex");
      return null;
    }
  }

  List<MixSettings> getMixSettingsForScene({
    required String functionId,
    required String sceneId,
  }) {
    try {
      return projectManager.getMixSettingsForScene(
        functionId: functionId,
        sceneId: sceneId,
      );
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get mix settings for scene : $ex");
      throwError("Failed to get mix settings for scene : $ex");
      return <MixSettings>[];
    }
  }

  List<MatrixSettings> getMatrixSettingsForScene({
    required String functionId,
    required String sceneId,
  }) {
    try {
      return projectManager.getMatrixSettingsForScene(
        functionId: functionId,
        sceneId: sceneId,
      );
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get matrix settings for scene : $ex");
      throwError("Failed to get matrix settings for scene : $ex");
      return <MatrixSettings>[];
    }
  }

  void addNewMixScene({required MixScene mixScene, required String functionId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addNewMixScene(mixScene: mixScene, functionId: functionId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add new mix scene : $ex");
      throwError("Failed to add new mix scene : $ex");
    }
  }

  void selectMixSceneForFunction({
    required String functionId,
    required String sceneId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.selectMixSceneForFunction(
        functionId: functionId,
        sceneId: sceneId,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to select mix scene for function : $ex");
      throwError("Failed to select mix scene for function : $ex");
    }
  }

  List<MixSettings> getCurrentMixSettingsForFunction({
    required String functionId,
  }) {
    try {
      return projectManager.getCurrentMixSettingsForFunction(
        functionId: functionId,
      );
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get current mix settings for function : $ex");
      throwError("Failed to get current mix settings for function : $ex");
      return <MixSettings>[];
    }
  }

  List<MatrixSettings> getCurrentMatrixSettingsForFunction({
    required String functionId,
  }) {
    try {
      return projectManager.getCurrentMatrixSettingsForFunction(
        functionId: functionId,
      );
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get current matrix settings for function : $ex");
      throwError("Failed to get current matrix settings for function : $ex");
      return <MatrixSettings>[];
    }
  }

  void updateMixSettings({
    required MixSettings mixSettings,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateMixSettings(
        mixSettings: mixSettings,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update mix settings for scene : $ex");
      throwError("Failed to update mix settings for scene : $ex");
    }
  }

  void updateMatrixSettings({
    required MatrixSettings matrixSettings,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateMatrixSettings(
        matrixSettings: matrixSettings,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update matrix settings for scene : $ex");
      throwError("Failed to update matrix settings for scene : $ex");
    }
  }

  void saveCurrentSettingsAsMixScene({
    required String functionId,
    required String sceneName,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.saveCurrentSettingsAsMixScene(
        functionId: functionId,
        sceneName: sceneName,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to save current settings as mix scene : $ex");
      throwError("Failed to save current settings as mix scene : $ex");
    }
  }

  void updateCurrentSettingsForMixScene({
    required String functionId,
    required String sceneId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateCurrentSettingsForMixScene(
        functionId: functionId,
        sceneId: sceneId,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to save current settings as mix scene : $ex");
      throwError("Failed to save current settings as mix scene : $ex");
    }
  }

  void applyMixSceneToFunction({
    required String functionId,
    required String sceneId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.applyMixSceneToFunction(
        functionId: functionId,
        sceneId: sceneId,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to apply mix scene to function : $ex");
      throwError("Failed to apply mix scene to function : $ex");
    }
  }

  List<MixScene> getAllMixScenesForFunction({
    required String functionId,
  }) {
    try {
      return projectManager.getAllMixScenesForFunction(
        functionId: functionId,
      );
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all mix scenes for function : $ex");
      throwError("Failed to get all mix scenes for function : $ex");
      return <MixScene>[];
    }
  }

  void removeScene({
    required String sceneId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeScene(
        sceneId: sceneId,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove scene : $ex");
      throwError("Failed to remove scene : $ex");
    }
  }
}
