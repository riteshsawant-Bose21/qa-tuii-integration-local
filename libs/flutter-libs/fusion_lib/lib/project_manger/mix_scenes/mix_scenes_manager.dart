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
    final MixScene? mixScene = projectService!.getMixSceneForFunction(
      functionId: functionId,
      sceneId: sceneId,
    );

    return mixScene is SourceMixScene ? mixScene.mixSettings : [];
  }

  MatrixMixer? getMatrixMixerForFunction({
    required String functionId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getCurrentMatrixMixerForFunction(
      functionId: functionId,
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

  void updateMixSettings({
    required MixSettings mixSettings,
    required String functionId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateMixSettings(mixSettings: mixSettings, functionId: functionId);
  }

  void updateMatrixSettings({
    required MatrixSettings matrixSettings,
    required String functionId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateMatrixSettings(setting: matrixSettings, functionId: functionId);
  }

  void updateMatrixMixer({
    required MatrixMixer matrixMixer,
    required String functionId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateMatrixMixer(mixerConfig: matrixMixer, functionId: functionId);
  }

  /// Removes either a MixScene or MatrixScene based on the provided sceneId
  void removeScene({
    required String sceneId,
    required String functionId,
  }) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeScene(
      sceneId: sceneId,
      functionId: functionId,
    );
  }
}
