import 'package:fusion_lib/fusion_lib.dart';

extension MixScenesService on ProjectService {
  /// get Selected Mix Scene for a specific function
  MixScene? getSelectedMixSceneForFunction(String functionId) {
    final selectedScene = relationships.getChildren(
      RelationshipType.selectedFunctionScenes,
      functionId,
    );

    if (selectedScene.isEmpty) {
      return null;
    }
    return mixScenes.get(selectedScene.first);
  }

  /// Add a new mix scene for a specific function
  void addMixScene(MixScene mixScene, String functionId) {
    mixScenes.add(mixScene.id, mixScene);
    relationships.link(
      RelationshipType.functionScenes,
      functionId,
      mixScene.id,
    );
  }

  /// save current zones MixSettings and MatrixSettings as a new MixScene
  void saveCurrentSettingsAsMixScene(String functionId, String sceneName) {
    final function = getZoneFunctionById(functionId: functionId);
    if (function == null) {
      throw Exception('Function with id $functionId does not exist');
    }

    if (function.type.hasMixScenes) {
      final newScene = SourceMixScene(
        name: sceneName,
      );
      addMixScene(newScene, functionId);

      final currentMixSettings = mixSettings.getByFunction(functionId);
      for (final setting in currentMixSettings) {
        final newSetting = setting.copyWith(
          id: "MIX${FusionUtils.shortStringUUID()}",
          sceneId: newScene.id,
        );
        mixSettings.add(newSetting.id, newSetting);
      }
    } else if (function.type.hasMatrixSettings) {
      final newScene = SourceMixScene(
        name: sceneName,
      );
      addMixScene(newScene, functionId);

      final currentMatrixSettings = matrixSettings.getByFunction(functionId);
      for (final setting in currentMatrixSettings) {
        final newSetting = setting.copyWith(
          id: "MAT${FusionUtils.shortStringUUID()}",
          sceneId: newScene.id,
        );
        matrixSettings.add(newSetting.id, newSetting);
      }
    }
  }

  List<MixSettings> getCurrentMixSettingsForFunction({
    required String functionId,
  }) {
    return mixSettings.getByFunction(functionId);
  }

  List<MatrixSettings> getCurrentMatrixSettingsForFunction({
    required String functionId,
  }) {
    return matrixSettings.getByFunction(functionId);
  }

  void applyMixSceneToFunction({
    required String functionId,
    required String sceneId,
  }) {
    final sceneMixSettings = getMixSettingsForFunctionScene(
      functionId: functionId,
      sceneId: sceneId,
    );
    for (final setting in sceneMixSettings) {
      setMixSetting(
        functionId: setting.functionId,
        sceneId: null,
        sourceId: setting.sourceId,
        gain: setting.gain,
        muted: setting.muted,
      );
    }

    final sceneMatrixSettings = getMatrixSettingsForFunctionScene(
      functionId: functionId,
      sceneId: sceneId,
    );
    for (final setting in sceneMatrixSettings) {
      setMatrixSetting(
        setting: setting.copyWith(sceneId: null),
      );
    }
  }

  void updateCurrentSettingsForMixScene({
    required String functionId,
    required String sceneId,
  }) {
    final currentMixSettings = getCurrentMixSettingsForFunction(
      functionId: functionId,
    );
    for (final setting in currentMixSettings) {
      final sceneSetting = getMixSetting(
        functionId: functionId,
        sceneId: sceneId,
        sourceId: setting.sourceId,
      );
      if (sceneSetting != null) {
        final updatedSetting = sceneSetting.copyWith(
          gain: setting.gain,
          muted: setting.muted,
        );
        mixSettings.add(updatedSetting.id, updatedSetting);
      } else {
        final newSetting = MixSettings(
          functionId: functionId,
          sceneId: sceneId,
          sourceId: setting.sourceId,
          gain: setting.gain,
          muted: setting.muted,
        );
        mixSettings.add(newSetting.id, newSetting);
      }
    }

    final currentMatrixSettings = getCurrentMatrixSettingsForFunction(
      functionId: functionId,
    );
    for (final setting in currentMatrixSettings) {
      final sceneSetting = getMatrixSetting(
        functionId: functionId,
        sceneId: sceneId,
        sourceId: setting.sourceId,
      );
      if (sceneSetting != null) {
        final updatedSetting = sceneSetting.copyWith(
          gain: setting.gain,
          muted: setting.muted,
        );
        matrixSettings.add(updatedSetting.id, updatedSetting);
      } else {
        final newSetting = setting.copyWith(
          id: "MAT${FusionUtils.shortStringUUID()}",
          sceneId: sceneId,
        );
        matrixSettings.add(newSetting.id, newSetting);
      }
    }
  }

  /// add MixSettings to MixScene for all missing sources in the scene
  /// This ensures that every source in the project has a corresponding MixSettings entry in the scene
  void addMissingSourceSettingsToScene(String functionId, String sceneId) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) return;

    if (zoneFunction.type.hasMixScenes) {
      final zoneId = relationships.getParent(RelationshipType.zoneFunctions, functionId);
      if (zoneId == null) return;
      final sources = getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);

      for (final source in sources) {
        if (zoneFunction.type.hasMixSettings) {
          final existingSetting = getMixSetting(
            functionId: functionId,
            sceneId: sceneId,
            sourceId: source.id,
          );
          if (existingSetting == null) {
            // Add default MixSettings for the missing source
            setMixSetting(
              functionId: functionId,
              sceneId: sceneId,
              sourceId: source.id,
              gain: -24.0,
              muted: false,
            );
          }
        } else if (zoneFunction.type.hasMatrixSettings) {
          final existingSetting = getMatrixSetting(
            functionId: functionId,
            sceneId: sceneId,
            sourceId: source.id,
          );
          if (existingSetting == null) {
            //todo: need to identity mono or stereo default matrix settings in future based on zone
            // Add default MatrixSettings for the missing source
            final newSetting = MonoMatrixSettings(
              functionId: functionId,
              sceneId: sceneId,
              sourceId: source.id,
              gain: -24.0,
              muted: false,
              mixLevel: 0.0,
              outGain: -24.0,
              outMuted: false,
            );
            setMatrixSetting(
              setting: newSetting,
            );
          }
        }
      }
    }
  }

  ///Add missing source setting to all MixSetting and MatrixSetting for all scenes in a function
  void addMissingSourceSettingsToFunction(String functionId) {
    final zoneFunction = getZoneFunctionById(functionId: functionId);
    if (zoneFunction == null) return;

    if (zoneFunction.type.hasMixSettings) {
      final zoneId = relationships.getParent(RelationshipType.zoneFunctions, functionId);
      if (zoneId == null) return;
      final sources = getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);
      for (final source in sources) {
        final existingSetting = getMixSetting(
          functionId: functionId,
          sceneId: null,
          sourceId: source.id,
        );
        if (existingSetting == null) {
          // Add default MixSettings for the missing source
          setMixSetting(
            functionId: functionId,
            sceneId: null,
            sourceId: source.id,
            gain: -24.0,
            muted: false,
          );
        }
      }
    }

    if (zoneFunction.type.hasMatrixSettings) {
      final zoneId = relationships.getParent(RelationshipType.zoneFunctions, functionId);
      if (zoneId == null) return;
      final sources = getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);
      for (final source in sources) {
        final existingSetting = getMatrixSetting(
          functionId: functionId,
          sceneId: null,
          sourceId: source.id,
        );
        if (existingSetting == null) {
          //todo: need to identity mono or stereo default matrix settings in future based on zone
          // Add default MatrixSettings for the missing source
          final newSetting = MonoMatrixSettings(
            functionId: functionId,
            sceneId: null,
            sourceId: source.id,
            gain: -24.0,
            muted: false,
            mixLevel: 0.0,
            outGain: -24.0,
            outMuted: false,
          );

          setMatrixSetting(
            setting: newSetting,
          );
        }
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
    final allMixSettings = mixSettings.getBySource(sourceId);
    final copyOfMixSettings = List<MixSettings>.from(allMixSettings);
    for (final setting in copyOfMixSettings) {
      mixSettings.remove(setting.id);
    }

    final allMatrixSettings = matrixSettings.getBySource(sourceId);
    final copyOfMatrixSettings = List<MatrixSettings>.from(allMatrixSettings);
    for (final setting in copyOfMatrixSettings) {
      matrixSettings.remove(setting.id);
    }
  }

  /// Get mix setting for a specific function, scene, and source
  MixSettings? getMixSetting({
    required String functionId,
    required String? sceneId,
    required String sourceId,
  }) {
    return mixSettings.getByContext(
      functionId: functionId,
      sceneId: sceneId,
      sourceId: sourceId,
    );
  }

  /// Get matrix setting for a specific function, scene, and source
  MatrixSettings? getMatrixSetting({
    required String functionId,
    required String? sceneId,
    required String sourceId,
  }) {
    return matrixSettings.getByContext(
      functionId: functionId,
      sceneId: sceneId,
      sourceId: sourceId,
    );
  }

  /// Set or update mix setting for a function, scene, and source
  void setMixSetting({
    required String functionId,
    required String? sceneId,
    required String sourceId,
    required double gain,
    required bool muted,
  }) {
    // Check if setting already exists
    final existing = mixSettings.getByContext(
      functionId: functionId,
      sceneId: sceneId,
      sourceId: sourceId,
    );

    if (existing != null) {
      // Update existing setting
      final updated = existing.copyWith(gain: gain, muted: muted);
      mixSettings.add(updated.id, updated);
    } else {
      // Create new setting
      final newSetting = MixSettings(
        functionId: functionId,
        sceneId: sceneId,
        sourceId: sourceId,
        gain: gain,
        muted: muted,
      );
      mixSettings.add(newSetting.id, newSetting);

      if (sceneId == null) {
        return;
      }
      // Add relationships
      relationships.link(
        RelationshipType.functionScenes,
        functionId,
        sceneId,
      );
    }
  }

  /// Set or update matrix setting for a function, scene, and source
  void setMatrixSetting({
    required MatrixSettings setting,
  }) {
    // Check if setting already exists
    final existing = matrixSettings.getByContext(
      functionId: setting.functionId,
      sceneId: setting.sceneId,
      sourceId: setting.sourceId,
    );

    if (existing != null) {
      // Update existing setting
      matrixSettings.add(existing.id, setting.copyWith(id: existing.id));
    } else {
      // Create new setting
      matrixSettings.add(setting.id, setting);

      if (setting.sceneId != null) {
        // Add relationships
        relationships.link(
          RelationshipType.functionScenes,
          setting.functionId,
          setting.sceneId!,
        );
      }
    }
  }

  /// Get all scenes for a function
  List<MixScene> getScenesForFunction(String functionId) {
    final sceneIds = relationships
        .getChildren(
          RelationshipType.functionScenes,
          functionId,
        )
        .toList();
    return sceneIds.map((id) => mixScenes.get(id)).whereType<MixScene>().toList();
  }

  /// Get all mix settings for a function and scene (all sources)
  List<MixSettings> getMixSettingsForFunctionScene({
    required String functionId,
    required String sceneId,
  }) {
    return mixSettings.getAll().where((s) => s.functionId == functionId && s.sceneId == sceneId).toList();
  }

  /// Get all matrix settings for a function and scene (all sources)
  List<MatrixSettings> getMatrixSettingsForFunctionScene({
    required String functionId,
    required String sceneId,
  }) {
    return matrixSettings.getAll().where((s) => s.functionId == functionId && s.sceneId == sceneId).toList();
  }

  void selectMixSceneForFunction({
    required String functionId,
    required String sceneId,
  }) {
    // First, remove any existing selected scene for this function
    final existingSelectedScenes = relationships.getChildren(
      RelationshipType.selectedFunctionScenes,
      functionId,
    );
    final copyOfExistingScenes = List<String>.from(existingSelectedScenes);
    for (final existingSceneId in copyOfExistingScenes) {
      relationships.unlink(
        RelationshipType.selectedFunctionScenes,
        functionId,
        existingSceneId,
      );
    }

    // Now link the new selected scene
    relationships.link(
      RelationshipType.selectedFunctionScenes,
      functionId,
      sceneId,
    );
  }

  /// Delete all settings when a function is deleted
  // void removeFunction(String functionId) {
  //   // Remove all mix scenes for this function
  //   final sceneIdsToRemove = relationships.getChildren(RelationshipType.functionScenes, functionId);
  //   final copyOfSceneIds = List<String>.from(sceneIdsToRemove);
  //   for (final sceneId in copyOfSceneIds) {
  //     removeScene(sceneId);
  //   }
  //
  //   // Remove all mix settings for this function
  //   final mixSettingsToRemove = mixSettings.getByFunction(functionId);
  //   final copyOfMixSettings = List<MixSettings>.from(mixSettingsToRemove);
  //   for (final setting in copyOfMixSettings) {
  //     mixSettings.remove(setting.id);
  //   }
  //
  //   // Remove all matrix settings for this function
  //   final matrixSettingsToRemove = matrixSettings.getByFunction(functionId);
  //   final copyOfMatrixSettings = List<MatrixSettings>.from(matrixSettingsToRemove);
  //   for (final setting in copyOfMatrixSettings) {
  //     matrixSettings.remove(setting.id);
  //   }
  //
  //   // Remove function-scene relationships
  //   relationships.removeAllRelationships(
  //     functionId,
  //   );
  // }

  /// Delete all settings when a scene is deleted
  void removeScene(String sceneId) {
    // Remove all mix settings for this scene
    final mixSettingsToRemove = mixSettings.getByScene(sceneId);
    final copyOfMixSettings = List<MixSettings>.from(mixSettingsToRemove);
    for (final setting in copyOfMixSettings) {
      mixSettings.remove(setting.id);
    }

    // Remove all matrix settings for this scene
    final matrixSettingsToRemove = matrixSettings.getByScene(sceneId);
    final copyOfMatrixSettings = List<MatrixSettings>.from(matrixSettingsToRemove);
    for (final setting in copyOfMatrixSettings) {
      matrixSettings.remove(setting.id);
    }

    mixScenes.remove(sceneId);

    // Remove scene from all function relationships
    relationships.removeAllRelationships(
      sceneId,
    );
  }

  /// Delete all settings when a source is deleted
  void removeSourceFromScenes(String sourceId) {
    // Remove all mix settings for this source
    final mixSettingsToRemove = mixSettings.getBySource(sourceId);
    for (final setting in mixSettingsToRemove) {
      mixSettings.remove(setting.id);
    }

    // Remove all matrix settings for this source
    final matrixSettingsToRemove = matrixSettings.getBySource(sourceId);
    for (final setting in matrixSettingsToRemove) {
      matrixSettings.remove(setting.id);
    }
  }
}
