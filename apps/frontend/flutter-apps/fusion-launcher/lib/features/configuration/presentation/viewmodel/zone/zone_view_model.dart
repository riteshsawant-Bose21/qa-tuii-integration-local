import 'package:fusion_launcher/features/configuration/presentation/viewmodel/circuit/circuit_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../project_view_model.dart';

extension ZoneViewModel on ProjectViewModel {
  //get Zone by id
  Zone? getZone(String zoneId) {
    try {
      return projectManager.getZoneById(zoneId);
    } catch (e) {
      return null;
    }
  }

  void updateZone(Zone zone) {
    try {
      projectManager.updateZone(zone);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update zone: $e");
      throwError("Failed to update zone: $e");
    }
  }

  void updateListeningAreasInZone(String zoneId, List<String> listeningAreaIds) {
    try {
      final List<ListeningArea> currentListeningAreas = getListeningAreasForZone(zoneId);
      final List<String> currentListeningAreaIds = currentListeningAreas.map((ListeningArea e) => e.id).toList();
      final List<String> toRemove = currentListeningAreaIds.where((String id) => !listeningAreaIds.contains(id)).toList();
      final List<String> toAdd = listeningAreaIds.where((String id) => !currentListeningAreaIds.contains(id)).toList();
      for (final String id in toRemove) {
        projectManager.removeListeningAreaFromZone(id, zoneId);
      }
      for (final String id in toAdd) {
        projectManager.addListeningAreaToZone(id, zoneId);
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update listening areas for zone: $e");
      throwError("Failed to update listening areas for zone: $e");
    }
  }

  void addZone(Zone zone) {
    try {
      projectManager.addZone(zone);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add zone: $e");
      throwError("Failed to add zone: $e");
    }
  }

  void removeZone(String zoneId) {
    try {
      projectManager.removeZone(zoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove zone: $e");
      throwError("Failed to remove zone: $e");
    }
  }

  void removeAllZones() {
    try {
      final List<Zone> allZones = getAllZones();
      for (final Zone zone in allZones) {
        projectManager.removeZone(zone.id);
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

  List<ListeningArea> getListeningAreasForZone(String zoneId) {
    try {
      return projectManager.getListeningAreasForZone(zoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get listening areas for zone: $e");
      return <ListeningArea>[];
    }
  }

  List<SourceSet> getSourceSetsInZone(String zoneId) {
    try {
      return projectManager.getSourceSetsInZone(zoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get source sets for zone: $e");
      return <SourceSet>[];
    }
  }

  void updateSourceSets(String zoneId, List<String> sourceSetIds) {
    try {
      final List<SourceSet> currentSourceSets = getSourceSetsInZone(zoneId);
      final List<String> currentSourceSetIds = currentSourceSets.map((SourceSet e) => e.id).toList();
      final List<String> toRemove = currentSourceSetIds.where((String id) => !sourceSetIds.contains(id)).toList();
      final List<String> toAdd = sourceSetIds.where((String id) => !currentSourceSetIds.contains(id)).toList();
      for (final String id in toRemove) {
        projectManager.removeSourceSetFromZone(id, zoneId);
      }
      for (final String id in toAdd) {
        projectManager.addSourceSetToZone(id, zoneId);
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update source sets for zone: $e");
      throwError("Failed to update source sets for zone: $e");
    }
  }

  //add Speaker to zone with a new circuit
  void addSpeakerToZone(String hardwareId, String zoneId) {
    try {
      final CircuitModel circuitModel = CircuitModel(name: "New Circuit");
      addCircuit(circuitModel);
      addHardwareToCircuit(hardwareId, circuitModel.id);
      addCircuitToZone(circuitModel.id, zoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add speaker to zone: $e");
      throwError("Failed to add speaker to zone: $e");
    }
  }

  // Add Source Set to Zone
  void addSourceSetToZone(String sourceSetId, String zoneId) {
    try {
      projectManager.addSourceSetToZone(sourceSetId, zoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add source set to zone: $e");
      throwError("Failed to add source set to zone: $e");
    }
  }

  // Remove Source Set from Zone
  void removeSourceSetFromZone(String sourceSetId, String zoneId) {
    try {
      projectManager.removeSourceSetFromZone(sourceSetId, zoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove source set from zone: $e");
      throwError("Failed to remove source set from zone: $e");
    }
  }

  //Add Listening Area to Zone
  void addListeningAreaToZone(String listeningAreaId, String zoneId) {
    try {
      projectManager.addListeningAreaToZone(listeningAreaId, zoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add listening area to zone: $e");
      throwError("Failed to add listening area to zone: $e");
    }
  }

  // Remove Listening Area from Zone
  void removeListeningAreaFromZone(String listeningAreaId, String zoneId) {
    try {
      projectManager.removeListeningAreaFromZone(listeningAreaId, zoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove listening area from zone: $e");
      throwError("Failed to remove listening area from zone: $e");
    }
  }

  void addCircuitToZone(String zoneId, String circuitId) {
    try {
      projectManager.addCircuitToZone(circuitId, zoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add circuit to zone: $e");
      throwError("Failed to add circuit to zone: $e");
    }
  }

  void removeCircuitFromZone(String circuitId, String zoneId) {
    try {
      projectManager.removeCircuitFromZone(circuitId, zoneId);
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
