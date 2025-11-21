import 'package:fusion_lib/fusion_lib.dart';

extension MixScenesManager on ProjectManager {
  MixScene? getSelectedMixSceneForFunction(String functionId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getSelectedMixSceneForFunction(functionId);
  }

  List<MixSettings> getMixSettingsForScene({
    required String functionId,
    required String sceneId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getMixSettingsForFunctionScene(
      functionId: functionId,
      sceneId: sceneId,
    );
  }

  List<MatrixSettings> getMatrixSettingsForScene({
    required String functionId,
    required String sceneId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getMatrixSettingsForFunctionScene(
      functionId: functionId,
      sceneId: sceneId,
    );
  }

  void saveCurrentSettingsAsMixScene({
    required String sceneName,
    required String functionId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.saveCurrentSettingsAsMixScene(
      functionId,
      sceneName,
    );
  }

  List<MixSettings> getCurrentMixSettingsForFunction({
    required String functionId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getCurrentMixSettingsForFunction(
      functionId: functionId,
    );
  }

  List<MatrixSettings> getCurrentMatrixSettingsForFunction({
    required String functionId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getCurrentMatrixSettingsForFunction(
      functionId: functionId,
    );
  }

  void applyMixSceneToFunction({
    required String functionId,
    required String sceneId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.applyMixSceneToFunction(
      functionId: functionId,
      sceneId: sceneId,
    );
  }

  void updateCurrentSettingsForMixScene({
    required String functionId,
    required String sceneId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateCurrentSettingsForMixScene(
      functionId: functionId,
      sceneId: sceneId,
    );
  }

  List<MixScene> getAllMixScenesForFunction({
    required String functionId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getScenesForFunction(
      functionId,
    );
  }

  void addNewMixScene({required MixScene mixScene, required String functionId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addMixScene(mixScene, functionId);
  }

  void selectMixSceneForFunction({
    required String functionId,
    required String sceneId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.selectMixSceneForFunction(
      functionId: functionId,
      sceneId: sceneId,
    );
  }

  void updateMixSettings({
    required MixSettings mixSettings,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.setMixSetting(
      functionId: mixSettings.functionId,
      sceneId: mixSettings.sceneId,
      sourceId: mixSettings.sourceId,
      gain: mixSettings.gain,
      muted: mixSettings.muted,
    );
  }

  void updateMatrixSettings({
    required MatrixSettings matrixSettings,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.setMatrixSetting(
      setting: matrixSettings,
    );
  }

  /// Removes either a MixScene or MatrixScene based on the provided sceneId
  void removeScene({
    required String sceneId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeScene(
      sceneId,
    );
  }
}
