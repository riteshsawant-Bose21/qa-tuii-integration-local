import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension CircuitViewmodel on ProjectViewModel {
  void addNewCircuitWithHardware({
    required HardwareComponent hardware,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final SubZone? subzone = getSubZoneForHardware(hardwareId: hardware.id);
      final Zone? zone = getZoneForHardware(hardwareId: hardware.id);
      int count = 0;
      if (subzone != null) {
        count = getCircuitsInSubZone(subZoneId: subzone.id).length;
      }
      if (zone != null) {
        count = getCircuitsInZone(zone.id).length;
      }
      final CircuitModel newCircuit = CircuitModel(
        id: FusionUtils.shortStringUUID(),
        addedInBuildingPage: hardware.addedFromBuildingPage,
        name: "${hardware.hardwareName} ${count == 0 ? "" : count + 1}",
        speakerSKU: (hardware as Speaker).speakerSKU,
      );
      addCircuit(circuit: newCircuit, autoSave: false);
      projectManager.addHardwareToCircuit(hardware.id, newCircuit.id);

      if (subzone != null) {
        addCircuitToSubZone(
          subZoneId: subzone.id,
          circuitId: newCircuit.id,
          autoSave: false,
        );
      }

      if (zone != null) {
        addCircuitToZone(
          zoneId: zone.id,
          circuitId: newCircuit.id,
          autoSave: false,
        );
      }

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
      for (final String algo in <String>[
        "peq",
        'limiter',
        "delay",
      ]) {
        addProcessingBlockToParent(
          processingBlock:
              ProcessingBlockModel.circuitBlocks
                  .firstWhere(
                    (ProcessingBlockModel element) => element.algorithmId == algo,
                  )
                  .clone(),
          parentId: circuit.id,
          autoSave: false,
        );
      }
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

  SubZone? getSubZoneForCircuit({required String circuitId}) {
    try {
      return projectManager.getSubZoneForCircuit(circuitId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get sub zone for circuit: $e");
      throwError("Failed to get sub zone for circuit: $e");
      return null;
    }
  }

  Zone? getZoneForCircuit({required String circuitId}) {
    try {
      return projectManager.getZoneForCircuit(circuitId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get zone for circuit: $e");
      throwError("Failed to get zone for circuit: $e");
      return null;
    }
  }

  void createCircuitWithSpeakers({
    required ProductQueryModel speakerData,
    required String listeningAreaId,
    required int speakerCount,
    String? circuitName,
    String? subZoneId,
    required String zoneId,
    required bool isFromBuildingPage,
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
      speakerSKU: speakerData.sku,
      addedInBuildingPage: isFromBuildingPage,
    );
    projectManager.addCircuit(circuitModel);

    if (subZoneId != null) {
      projectManager.addCircuitToSubZone(subZoneId, circuitModel.id);
    } else {
      projectManager.addCircuitToZone(circuitModel.id, zoneId);
    }

    for (int i = 0; i < speakerCount; i++) {
      final HardwareComponent newHardware = fromProductQueryModel(speakerData, locationEntity: locationModel, isFromBuildingPage: isFromBuildingPage);
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

  void moveCircuitsFromZoneToSubZone({
    required String zoneId,
    required String subZoneId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }

      // Get all circuits in the zone before any operations
      final List<CircuitModel> zoneCircuits = getCircuitsInZone(zoneId);

      FusionLogger.log(tag: LogTag.project, message: "Moving ${zoneCircuits.length} circuits from zone $zoneId to subzone $subZoneId");

      // Move each circuit from zone to subzone
      // Note: This should typically be handled automatically when listening areas are moved
      // but we're doing this as a fallback to ensure circuits are properly assigned
      for (final CircuitModel circuit in zoneCircuits) {
        // Remove from zone first
        removeCircuitFromZone(circuitId: circuit.id, zoneId: zoneId, autoSave: false);
        // Then add to subzone
        addCircuitToSubZone(circuitId: circuit.id, subZoneId: subZoneId, autoSave: false);
      }

      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to move circuits from zone to subzone: $e");
      throwError("Failed to move circuits from zone to subzone: $e");
    }
  }

  List<CircuitModel> getCompatibleCircuits({
    required String hardwareId,
    String? sku,
  }) {
    String? speakerSKU = sku;
    if (speakerSKU == null) {
      final HardwareComponent? hardware = getHardware(hardwareId: hardwareId);
      if (hardware is Speaker) {
        speakerSKU = hardware.speakerSKU;
      }
    }
    final SubZone? subZone = getSubZoneForHardware(hardwareId: hardwareId);
    if (subZone != null) {
      return getCircuitsInSubZone(
        subZoneId: subZone.id,
      ).where((CircuitModel e) => e.speakerSKU == speakerSKU).toList();

      ///
    }
    final Zone? zone = getZoneForHardware(hardwareId: hardwareId);
    if (zone != null) {
      return getCircuitsInZone(
        zone.id,
      ).where((CircuitModel e) => e.speakerSKU == speakerSKU).toList();
    }
    return <CircuitModel>[];
  }
}
