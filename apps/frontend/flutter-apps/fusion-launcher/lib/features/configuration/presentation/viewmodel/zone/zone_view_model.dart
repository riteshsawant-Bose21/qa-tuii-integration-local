import 'package:fusion_lib/fusion_lib.dart';

import '../project_view_model.dart';

extension ZoneViewModel on ProjectViewModel {
  //get Zone by id
  Zone? getZone({required String zoneId}) {
    try {
      return projectManager.getZoneById(zoneId);
    } catch (e) {
      return null;
    }
  }

  void updateZone({required Zone zone, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateZone(zone);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update zone: $e");
      throwError("Failed to update zone: $e");
    }
  }

  void updateListeningAreasInZone({required String zoneId, required List<String> listeningAreaIds, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final List<ListeningArea> currentListeningAreas = getListeningAreasForZone(zoneId: zoneId);
      final List<String> currentListeningAreaIds = currentListeningAreas.map((ListeningArea e) => e.id).toList();
      final List<String> toRemove = currentListeningAreaIds.where((String id) => !listeningAreaIds.contains(id)).toList();
      final List<String> toAdd = listeningAreaIds.where((String id) => !currentListeningAreaIds.contains(id)).toList();
      for (final String id in toRemove) {
        projectManager.removeListeningAreaFromZone(id, zoneId);
      }
      for (final String id in toAdd) {
        projectManager.addListeningAreaToZone(id, zoneId);
      }
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update listening areas for zone: $e");
      throwError("Failed to update listening areas for zone: $e");
    }
  }

  void addZone({required Zone zone, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addZone(zone);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add zone: $e");
      throwError("Failed to add zone: $e");
    }
  }

  void removeZone({required String zoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeZone(zoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove zone: $e");
      throwError("Failed to remove zone: $e");
    }
  }

  void removeAllZones({bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final List<Zone> allZones = getAllZones();
      for (final Zone zone in allZones) {
        projectManager.removeZone(zone.id);
      }
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove all zones: $e");
      throwError("Failed to remove all zones: $e");
    }
  }

  List<Zone> getAllZones() {
    try {
      return projectManager.getAllZones();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all zones: $e");
      return <Zone>[];
    }
  }

  List<ListeningArea> getListeningAreasForZone({required String zoneId}) {
    try {
      return projectManager.getListeningAreasForZone(zoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get listening areas for zone: $e");
      return <ListeningArea>[];
    }
  }

  List<SourceSet> getSourceSetsInZone({required String zoneId}) {
    try {
      return projectManager.getSourceSetsInZone(zoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get source sets for zone: $e");
      return <SourceSet>[];
    }
  }

  void updateSourceSets({required String zoneId, required List<String> sourceSetIds, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final List<SourceSet> currentSourceSets = getSourceSetsInZone(zoneId: zoneId);
      final List<String> currentSourceSetIds = currentSourceSets.map((SourceSet e) => e.id).toList();
      final List<String> toRemove = currentSourceSetIds.where((String id) => !sourceSetIds.contains(id)).toList();
      final List<String> toAdd = sourceSetIds.where((String id) => !currentSourceSetIds.contains(id)).toList();
      for (final String id in toRemove) {
        projectManager.removeSourceSetFromZone(id, zoneId);
      }
      for (final String id in toAdd) {
        projectManager.addSourceSetToZone(id, zoneId);
      }
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update source sets for zone: $e");
      throwError("Failed to update source sets for zone: $e");
    }
  }

  //add Speaker to zone with a new circuit
  void addSpeakerToZone({required String hardwareId, required String zoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final CircuitModel circuitModel = CircuitModel(name: "New Circuit");
      projectManager.addCircuit(circuitModel);
      projectManager.addHardwareToCircuit(hardwareId, circuitModel.id);
      projectManager.addCircuitToZone(circuitModel.id, zoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add speaker to zone: $e");
      throwError("Failed to add speaker to zone: $e");
    }
  }

  // Add Source Set to Zone
  void addSourceSetToZone({required String sourceSetId, required String zoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addSourceSetToZone(sourceSetId, zoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add source set to zone: $e");
      throwError("Failed to add source set to zone: $e");
    }
  }

  // Remove Source Set from Zone
  void removeSourceSetFromZone({required String sourceSetId, required String zoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSourceSetFromZone(sourceSetId, zoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove source set from zone: $e");
      throwError("Failed to remove source set from zone: $e");
    }
  }

  //Add Listening Area to Zone
  void addListeningAreaToZone({required String listeningAreaId, required String zoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addListeningAreaToZone(listeningAreaId, zoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add listening area to zone: $e");
      throwError("Failed to add listening area to zone: $e");
    }
  }

  // Remove Listening Area from Zone
  void removeListeningAreaFromZone({required String listeningAreaId, required String zoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeListeningAreaFromZone(listeningAreaId, zoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove listening area from zone: $e");
      throwError("Failed to remove listening area from zone: $e");
    }
  }

  void addCircuitToZone({required String zoneId, required String circuitId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addCircuitToZone(circuitId, zoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add circuit to zone: $e");
      throwError("Failed to add circuit to zone: $e");
    }
  }

  void removeCircuitFromZone({required String circuitId, required String zoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeCircuitFromZone(circuitId, zoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove circuit from zone: $e");
      throwError("Failed to remove circuit from zone: $e");
    }
  }

  List<CircuitModel> getCircuitsInZone(String zoneId) {
    try {
      return projectManager.getCircuitsInZone(zoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get circuits for zone: $e");
      return <CircuitModel>[];
    }
  }

  void reorderZones({required String zoneIdToMove, required String zoneIdAtNewIndex}) {
    try {
      projectManager.reOrderZones(zoneIdToMove: zoneIdToMove, zoneAtNewIndex: zoneIdAtNewIndex);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to reorder zones: $e");
      throwError("Failed to reorder zones: $e");
    }
  }
}
