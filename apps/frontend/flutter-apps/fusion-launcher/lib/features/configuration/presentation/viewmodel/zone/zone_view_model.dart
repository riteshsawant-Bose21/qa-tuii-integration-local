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

  void addCircuitToZone(String circuitId, String zoneId) {
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
}
