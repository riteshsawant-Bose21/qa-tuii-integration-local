import 'dart:ui';

import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension CircuitViewmodel on ProjectViewModel {
  void addNewCircuitWithHardware({required HardwareComponent hardware, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final CircuitModel newCircuit = CircuitModel(
        id: FusionUtils.shortStringUUID(),
        name: "New Circuit",
      );
      projectManager.addCircuit(newCircuit);
      projectManager.addHardwareToCircuit(hardware.id, newCircuit.id);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add new circuit with hardware: $e");
      throwError("Failed to add new circuit with hardware: $e");
    }
  }

  void addCircuit({required CircuitModel circuit, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addCircuit(circuit);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add circuit: $e");
      throwError("Failed to add circuit: $e");
    }
  }

  void updateCircuit({required CircuitModel circuit, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateCircuit(circuit);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update circuit: $e");
      throwError("Failed to update circuit: $e");
    }
  }

  void removeCircuit({required String circuitId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeCircuit(circuitId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove circuit: $e");
      throwError("Failed to remove circuit: $e");
    }
  }

  CircuitModel? getCircuitById({required String circuitId}) {
    try {
      return projectManager.getCircuitById(circuitId);
    } catch (e) {
      return null;
    }
  }

  List<CircuitModel> getAllCircuits() {
    try {
      return projectManager.getAllCircuits();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all circuits: $e");
      throwError("Failed to get all circuits: $e");
      return <CircuitModel>[];
    }
  }

  List<HardwareComponent> getHardwareForCircuit({required String circuitId}) {
    try {
      return projectManager.getHardwareForCircuit(circuitId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get hardware for circuit: $e");
      throwError("Failed to get hardware for circuit: $e");
      return <HardwareComponent>[];
    }
  }

  void addHardwareToCircuit({required String hwId, required String circuitId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addHardwareToCircuit(hwId, circuitId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add hardware to circuit: $e");
      throwError("Failed to add hardware to circuit: $e");
    }
  }

  void removeHardwareFromCircuit({required String hwId, required String circuitId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeHardwareFromCircuit(hwId, circuitId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove hardware from circuit: $e");
      throwError("Failed to remove hardware from circuit: $e");
    }
  }

  void removeAllCircuits({bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final List<CircuitModel> allCircuits = getAllCircuits();
      for (final CircuitModel circuit in allCircuits) {
        projectManager.removeCircuit(circuit.id);
      }
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove all circuits: $e");
      throwError("Failed to remove all circuits: $e");
    }
  }

  List<ListeningArea> getListeningAreasForCircuit({required String circuitId}) {
    try {
      return projectManager.getListeningAreasForCircuit(circuitId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get listening areas for circuit: $e");
      throwError("Failed to get listening areas for circuit: $e");
      return <ListeningArea>[];
    }
  }

  void createCircuitWithSpeakers({
    required ProductQueryModel speakerData,
    required String listeningAreaId,
    required int speakerCount,
    String? circuitName,
    String? subZoneId,
    required String zoneId,
    bool autoSave = true,
  }) {
    if (autoSave) {
      recordSnapshot();
    }
    final FloorModel? floorModel = getFloorForListeningArea(areaId: listeningAreaId);
    final LocationModel locationModel = LocationModel(
      listeningAreaId: listeningAreaId,
      floorId: floorModel?.id,
    );

    final CircuitModel circuitModel = CircuitModel(
      name: circuitName ?? "Circuit ${circuits.length + 1}",
    );
    projectManager.addCircuit(circuitModel);

    if (subZoneId != null) {
      projectManager.addCircuitToSubZone(subZoneId, circuitModel.id);
    } else {
      projectManager.addCircuitToZone(circuitModel.id, zoneId);
    }

    for (int i = 0; i < speakerCount; i++) {
      final HardwareComponent newHardware = fromProductQueryModel(
        speakerData,
        pos: Offset.zero,
        locationEntity: locationModel,
      );
      projectManager.addHardware(newHardware);
      projectManager.addHardwareToCircuit(newHardware.id, circuitModel.id);
    }
    if (autoSave) {
      saveProject();
    }
    updateProject();
  }

  void reOrderCircuitInZone({required String parentId, required int oldIndex, required int newIndex, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reorderCircuitsInZone(parentId, oldIndex, newIndex);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to reorder circuit in zone: $e");
      throwError("Failed to reorder circuit in zone: $e");
    }
  }
}
