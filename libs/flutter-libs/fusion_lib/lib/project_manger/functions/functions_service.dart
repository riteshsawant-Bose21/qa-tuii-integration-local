import 'package:fusion_lib/fusion_lib.dart';

extension ZoneFunctionService on ProjectService {
  void addFunctionToZone({required ZoneFunctions function, required String zoneId}) {
    zoneFunctions.add(function.id, function);

    //unlink previous function
    final currentZoneFunctions = relationships.getChildren(RelationshipType.zoneFunctions, zoneId);
    if (currentZoneFunctions.isNotEmpty) {
      //remove old function
      removeFunction(functionId: currentZoneFunctions.first);
    }

    relationships.link(RelationshipType.zoneFunctions, zoneId, function.id);

    addMissingSourceSettingsToFunction(function.id);
  }

  void removeFunction({required String functionId}) {
    //remove all mix scenes associated with this function
    final mixSceneIds = relationships.getChildren(RelationshipType.functionScenes, functionId);
    final copyOfMixSceneIds = List<String>.from(mixSceneIds);
    for (final mixSceneId in copyOfMixSceneIds) {
      removeScene(mixSceneId);
    }

    //remove all mix settings for this scene
    final mixSettingsToRemove = mixSettings.getByFunction(functionId);
    final copyOfMixSettings = List<MixSettings>.from(mixSettingsToRemove);
    for (final setting in copyOfMixSettings) {
      mixSettings.remove(setting.id);
    }

    // Remove all matrix settings for this scene
    final matrixSettingsToRemove = matrixSettings.getByFunction(functionId);
    final copyOfMatrixSettings = List<MatrixSettings>.from(matrixSettingsToRemove);
    for (final setting in copyOfMatrixSettings) {
      matrixSettings.remove(setting.id);
    }

    zoneFunctions.remove(functionId);
    relationships.removeAllRelationships(functionId);
  }

  ZoneFunctions? getZoneFunction({required String zoneId}) {
    final zoneFunctions = relationships.getChildren(RelationshipType.zoneFunctions, zoneId);
    if (zoneFunctions.isEmpty) {
      return null;
    }
    return getZoneFunctionById(functionId: zoneFunctions.first);
  }

  ZoneFunctions? getZoneFunctionById({required String functionId}) {
    return zoneFunctions.get(functionId);
  }

  void updateZoneGain({required String zoneId, required double gain}) {
    if (zones.exists(zoneId)) {
      final zone = zones.get(zoneId)!;
      final updatedZone = zone.copyWith(gain: gain);
      zones.add(zoneId, updatedZone);
    } else if (subZones.exists(zoneId)) {
      final subZone = subZones.get(zoneId)!;
      final updatedSubZone = subZone.copyWith(gain: gain);
      subZones.add(zoneId, updatedSubZone);
    }
  }

  void muteZone({required String zoneId, required bool isMuted}) {
    if (zones.exists(zoneId)) {
      final zone = zones.get(zoneId)!;
      final updatedZone = zone.copyWith(muted: isMuted);
      zones.add(zoneId, updatedZone);
    } else if (subZones.exists(zoneId)) {
      final subZone = subZones.get(zoneId)!;
      final updatedSubZone = subZone.copyWith(muted: isMuted);
      subZones.add(zoneId, updatedSubZone);
    }
  }

  //return selected Source for given function
  String? getSelectedSourceForFunction({required String functionId}) {
    final selectedSources = relationships.getChildren(RelationshipType.selectedSourceForFunction, functionId);
    if (selectedSources.isEmpty) {
      return null;
    } else {
      return selectedSources.first;
    }
  }

  void selectSourceForFunction({required String functionId, required String sourceId}) {
    //remove previous selection
    final currentSelectedSources = relationships.getChildren(RelationshipType.selectedSourceForFunction, functionId);
    final copyOfCurrentSelectedSources = List<String>.from(currentSelectedSources);
    for (final selectedSourceId in copyOfCurrentSelectedSources) {
      relationships.unlink(RelationshipType.selectedSourceForFunction, functionId, selectedSourceId);
    }

    //link new selection
    relationships.link(RelationshipType.selectedSourceForFunction, functionId, sourceId);
  }
}
