import 'package:fusion_lib/fusion_lib.dart';

extension MixScenesService on ProjectService {
  /// get Selected Mix Scene for a specific function
  MixScene? getSelectedMixSceneForFunction(String functionId) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);

    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    final selectedSceneIds = zoneFunction.selectedMixSceneId;
    if (selectedSceneIds == null) {
      return null;
    }

    return zoneFunctions.getMixSceneById(
      functionId: functionId,
      sceneId: selectedSceneIds,
    );
  }

  /// Add a new mix scene for a specific function
  void addMixScene(MixScene mixScene, String functionId) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);

    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    List<MixScene> currentScenes = List.from(zoneFunction.mixScenes);
    if (currentScenes.any((scene) => scene.name == mixScene.name)) {
      // throw Exception('Mix Scene with name ${mixScene.name} already exists');
      updateCurrentSettingsForMixScene(functionId: functionId, sceneId: currentScenes.firstWhere((scene) => scene.name == mixScene.name).id);
      return;
    }

    currentScenes.add(mixScene);

    final updatedFunction = zoneFunction.copyWith(
      mixScenes: currentScenes,
      selectedMixSceneId: mixScene.id,
    );

    zoneFunctions.add(functionId, updatedFunction);
  }

  /// save current zones MixSettings and MatrixSettings as a new MixScene
  void saveCurrentSettingsAsMixScene(String functionId, String sceneName) {
    final function = getZoneFunctionById(functionId: functionId);
    if (function == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    if (function.type.hasSourceMixSettings) {
      final currentMixSettings = function.mixSettings;

      final newScene = SourceMixScene(
        name: sceneName,
        mixSettings: currentMixSettings?.map((e) => e.copyWith()).toList() ?? [],
      );

      addMixScene(newScene, functionId);
    } else if (function.type.hasMatrixSettings) {
      final currentConfig = function.matrixMixer;

      final newScene = MatrixMixScene(
        name: sceneName,
        mixerConfig: currentConfig!.clone(),
      );

      addMixScene(newScene, functionId);
    }
  }

  List<MixSettings> getCurrentMixSettingsForFunction({
    required String functionId,
  }) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }
    return zoneFunction.mixSettings ?? [];
  }

  MatrixMixer? getCurrentMatrixMixerForFunction({
    required String functionId,
  }) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }
    return zoneFunction.matrixMixer;
  }

  List<MatrixSettings> getCurrentMatrixSettingsForFunction({
    required String functionId,
  }) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }
    return zoneFunction.matrixMixer?.settings ?? [];
  }

  void applyMixSceneToFunction({
    required String functionId,
    required String sceneId,
  }) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    if (zoneFunction.type.hasSourceMixSettings) {
      final mixScene = zoneFunction.mixScenes.firstWhere((val) => val.id == sceneId);

      final updatedZoneFunction = zoneFunction.copyWith(
        selectedMixSceneId: sceneId,
        mixSettings: (mixScene is SourceMixScene) ? mixScene.mixSettings.map((e) => e.copyWith()).toList() : [],
      );

      zoneFunctions.add(functionId, updatedZoneFunction);
    } else if (zoneFunction.type.hasMatrixSettings) {
      final mixScene = zoneFunction.mixScenes.firstWhere((val) => val.id == sceneId);

      print("Applying Matrix Mix Scene: ${mixScene.name} to Function: ${zoneFunction.name}");

      final updatedZoneFunction = zoneFunction.copyWith(
        selectedMixSceneId: sceneId,
        matrixMixer: (mixScene is MatrixMixScene) ? mixScene.mixerConfig.clone() : null,
      );

      zoneFunctions.add(functionId, updatedZoneFunction);
    }
  }

  void updateCurrentSettingsForMixScene({
    required String functionId,
    required String sceneId,
  }) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    if (zoneFunction.type.hasSourceMixSettings) {
      final currentMixSettings = zoneFunction.mixSettings;

      final updatedScenes = zoneFunction.mixScenes.map((scene) {
        if (scene.id == sceneId && scene is SourceMixScene) {
          return scene.copyWith(
            mixSettings: currentMixSettings?.map((e) => e.copyWith()).toList() ?? [],
          );
        }
        return scene;
      }).toList();

      final updatedZoneFunction = zoneFunction.copyWith(
        mixScenes: updatedScenes,
      );

      zoneFunctions.add(functionId, updatedZoneFunction);
    } else if (zoneFunction.type.hasMatrixSettings) {
      final currentMatrixMixer = zoneFunction.matrixMixer;

      final updatedScenes = zoneFunction.mixScenes.map((scene) {
        if (scene.id == sceneId && scene is MatrixMixScene) {
          return scene.copyWith(
            mixerConfig: currentMatrixMixer!.clone(),
          );
        }
        return scene;
      }).toList();

      final updatedZoneFunction = zoneFunction.copyWith(
        mixScenes: updatedScenes,
      );

      zoneFunctions.add(functionId, updatedZoneFunction);
    }
  }

  /// add MixSettings to MixScene for all missing sources in the scene
  /// This ensures that every source in the project has a corresponding MixSettings entry in the scene
  void addMissingSourceSettingsToScene(String functionId, String sceneId) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    MixScene scene = zoneFunction.mixScenes.firstWhere((val) => val.id == sceneId);

    if (zoneFunction.type.hasScenes) {
      final zoneId = relationships.getParent(RelationshipType.zoneFunctions, functionId);
      if (zoneId == null) return;
      final sources = getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);

      if (zoneFunction.type.hasSourceMixSettings && scene is SourceMixScene) {
        List<MixSettings> existingMixSetting = List.from(scene.mixSettings);
        for (final source in sources) {
          final hasSetting = existingMixSetting.any((setting) => setting.sourceId == source.id);
          if (!hasSetting) {
            // Add default MixSettings for the missing source
            final newSetting = MixSettings(
              sourceId: source.id,
              gain: -24.0,
              muted: false,
            );
            existingMixSetting.add(newSetting);
          }
        }
        scene = scene.copyWith(
          mixSettings: existingMixSetting,
        );
      } else if (zoneFunction.type.hasMatrixSettings && scene is MatrixMixScene) {
        List<MatrixSettings> existingMatrixSetting = List.from(scene.mixerConfig.settings);
        for (final source in sources) {
          final hasSetting = existingMatrixSetting.any((setting) => setting.sourceId == source.id);
          if (!hasSetting) {
            //todo: based on zone need to identity mono or stereo default matrix settings in future
            // Add default MatrixSettings for the missing source
            final newSetting = MonoMatrixSettings(
              sourceId: source.id,
              gain: -24.0,
              muted: false,
              mixLevel: 0.0,
            );
            existingMatrixSetting.add(newSetting);
          }
        }
        scene = scene.copyWith(
          mixerConfig: scene.mixerConfig.copyWith(
            settings: existingMatrixSetting,
          ),
        );
      }

      // Update the scene in the zone function
      final updatedFunction = zoneFunction.copyWith(
        mixScenes: zoneFunction.mixScenes.map((s) {
          if (s.id == scene.id) {
            return scene;
          }
          return s;
        }).toList(),
      );
      zoneFunctions.add(functionId, updatedFunction);
    }
  }

  ///Add missing source setting to all MixSetting and MatrixSetting for all scenes in a function
  void addMissingSourceSettingsToFunction(String functionId) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    if (zoneFunction.type.hasScenes) {
      final zoneId = relationships.getParent(RelationshipType.zoneFunctions, functionId);
      if (zoneId == null) return;
      final sources = getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);

      if (zoneFunction.type.hasSourceMixSettings) {
        final List<MixSettings> existingMixSetting = List.from(zoneFunction.mixSettings ?? []);
        for (final source in sources) {
          final hasSetting = existingMixSetting.any((setting) => setting.sourceId == source.id);
          if (!hasSetting) {
            // Add default MixSettings for the missing source
            final newSetting = MixSettings(
              sourceId: source.id,
              gain: -24.0,
              muted: false,
            );
            existingMixSetting.add(newSetting);
          }
        }
        final updatedFunction = zoneFunction.copyWith(
          mixSettings: existingMixSetting,
        );
        zoneFunctions.add(functionId, updatedFunction);
      } else if (zoneFunction.type.hasMatrixSettings) {
        //todo: need to handle stereo matrix mixer as well in future based on zone type
        final MatrixMixer currentMatrixMixer =
            zoneFunction.matrixMixer ??
            MonoMatrixMixer(
              outGain: -24.0,
              outMuted: false,
            );
        final List<MatrixSettings> existingMatrixSetting = List.from(currentMatrixMixer.settings);
        for (final source in sources) {
          final hasSetting = existingMatrixSetting.any((setting) => setting.sourceId == source.id);
          if (!hasSetting) {
            //todo: based on zone need to identity mono or stereo default matrix settings in future
            // Add default MatrixSettings for the missing source
            final newSetting = MonoMatrixSettings(
              sourceId: source.id,
              gain: -24.0,
              muted: false,
              mixLevel: 0.0,
            );
            existingMatrixSetting.add(newSetting);
          }
        }

        final updatedFunction = zoneFunction.copyWith(
          matrixMixer: currentMatrixMixer.copyWith(
            settings: existingMatrixSetting,
          ),
        );
        zoneFunctions.add(functionId, updatedFunction);
      }
    }
  }

  /// Add missing source settings to all scenes for a specific function when sources are added to the zone
  void addMissingSourceSettingsToAllScenes(String functionId) {
    final scenes = getScenesForFunction(functionId);
    final copyOfScenes = List<MixScene>.from(scenes);
    for (final scene in copyOfScenes) {
      addMissingSourceSettingsToScene(functionId, scene.id);
    }
  }

  ///removes deleted source from all scenes
  void removeSourceFromAllScenes(String sourceId) {
    final allFunctions = zoneFunctions.getAll();
    final copyOfFunctions = List<ZoneFunctions>.from(allFunctions);
    for (final function in copyOfFunctions) {
      final scenes = getScenesForFunction(function.id);
      final copyOfScenes = List<MixScene>.from(scenes);

      List<MixScene> updatedScenes = [];
      for (final scene in copyOfScenes) {
        if (function.type.hasSourceMixSettings && scene is SourceMixScene) {
          List<MixSettings> mixScenes = List.from(scene.mixSettings);
          mixScenes.removeWhere((setting) => setting.sourceId == sourceId);
          final updatedScene = scene.copyWith(
            mixSettings: mixScenes,
          );
          updatedScenes.add(updatedScene);
        } else if (function.type.hasMatrixSettings && scene is MatrixMixScene) {
          List<MatrixSettings> matrixSettings = List.from(scene.mixerConfig.settings);
          matrixSettings.removeWhere((setting) => setting.sourceId == sourceId);
          final updatedScene = scene.copyWith(
            mixerConfig: scene.mixerConfig.copyWith(
              settings: matrixSettings,
            ),
          );
          updatedScenes.add(updatedScene);
        } else {
          updatedScenes.add(scene);
        }
      }

      final updatedFunction = function.copyWith(
        mixScenes: updatedScenes,
      );
      zoneFunctions.add(function.id, updatedFunction);
    }
  }

  void updateMixSettings({required MixSettings mixSettings, required String functionId}) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    final updatedMixSettings = zoneFunction.mixSettings?.map((setting) {
      if (setting.sourceId == mixSettings.sourceId) {
        return mixSettings;
      }
      return setting;
    }).toList();

    final updatedZoneFunction = zoneFunction.copyWith(
      mixSettings: updatedMixSettings,
    );

    zoneFunctions.add(functionId, updatedZoneFunction);
  }

  void updateMatrixSettings({required MatrixSettings setting, required String functionId}) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    final currentMatrixMixer = zoneFunction.matrixMixer;
    if (currentMatrixMixer == null) {
      throw Exception('Function with id $functionId does not have a matrix mixer');
    }

    final updatedSettings = currentMatrixMixer.settings.map((s) {
      if (s.sourceId == setting.sourceId) {
        return setting;
      }
      return s;
    }).toList();

    final updatedMatrixMixer = currentMatrixMixer.copyWith(
      settings: updatedSettings,
    );

    final updatedZoneFunction = zoneFunction.copyWith(
      matrixMixer: updatedMatrixMixer,
    );

    zoneFunctions.add(functionId, updatedZoneFunction);
  }

  void updateMatrixMixer({required MatrixMixer mixerConfig, required String functionId}) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    final updatedZoneFunction = zoneFunction.copyWith(
      matrixMixer: mixerConfig,
    );

    zoneFunctions.add(functionId, updatedZoneFunction);
  }

  /// Get all scenes for a function
  List<MixScene> getScenesForFunction(String functionId) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }
    return zoneFunction.mixScenes;
  }

  /// Get all mix settings for a function and scene (all sources)
  MixScene? getMixSceneForFunction({
    required String functionId,
    required String sceneId,
  }) {
    return zoneFunctions.getMixSceneById(functionId: functionId, sceneId: sceneId);
  }

  /// Get all matrix settings for a function and scene (all sources)
  List<MatrixSettings> getMatrixSettingsForFunctionScene({
    required String functionId,
    required String sceneId,
  }) {
    final mixScene = zoneFunctions.getMixSceneById(functionId: functionId, sceneId: sceneId);
    if (mixScene is MatrixMixScene) {
      return mixScene.mixerConfig.settings;
    }
    return [];
  }

  /// Delete all settings when a scene is deleted
  void removeScene({required String sceneId, required String functionId}) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) {
      throw Exception('Function with id $functionId does not exist');
    }
    final updatedScenes = zoneFunction.mixScenes.where((scene) => scene.id != sceneId).toList();
    final updatedFunction = zoneFunction.copyWith(
      mixScenes: updatedScenes,
    );
    zoneFunctions.add(functionId, updatedFunction);
  }
}
