import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension SubzoneViewModel on ProjectViewModel {
  //add SubZone
  void addSubZone({required SubZone subZone, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addSubZone(subZone);
      for (final String algo in <String>[
        "delay",
        "peq",
      ]) {
        addProcessingBlockToParent(
          processingBlock:
              ProcessingBlockModel.zoneBlocks
                  .firstWhere(
                    (ProcessingBlockModel element) => element.algorithmId == algo,
                  )
                  .clone(),
          parentId: subZone.id,
          autoSave: false,
        );
      }
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add subzone: $e");
      throwError("Failed to add subzone: $e");
    }
  }

  //get SubZone by id
  SubZone? getSubZone({required String subZoneId}) {
    try {
      return projectManager.getSubZoneById(subZoneId);
    } catch (e) {
      return null;
    }
  }

  void updateSubZone({required SubZone subZone, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSubZone(subZone);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update subzone: $e");
      throwError("Failed to update subzone: $e");
    }
  }

  void updateListeningAreasInSubZone({
    required String subZoneId,
    required List<String> listeningAreaIds,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final List<ListeningArea> currentListeningAreas = getListeningAreasInSubZone(subZoneId: subZoneId);
      final List<String> currentListeningAreaIds = currentListeningAreas.map((ListeningArea e) => e.id).toList();
      final List<String> toRemove = currentListeningAreaIds.where((String id) => !listeningAreaIds.contains(id)).toList();
      final List<String> toAdd = listeningAreaIds.where((String id) => !currentListeningAreaIds.contains(id)).toList();
      if (toRemove.isNotEmpty) {
        projectManager.removeMultipleListeningAreaFromSubZone(toRemove, subZoneId);
      }

      if (toAdd.isNotEmpty) {
        projectManager.addMultipleAreasToAddSubZone(toAdd, subZoneId);
      }

      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update listening areas for subzone: $e");
      throwError("Failed to update listening areas for subzone: $e");
    }
  }

  void removeSubZone({required String subZoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSubZone(subZoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove subzone: $e");
      throwError("Failed to remove subzone: $e");
    }
  }

  List<SubZone> getAllSubZones() {
    try {
      return projectManager.getAllSubZones();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all subzones: $e");
      throwError("Failed to get all subzones: $e");
      return <SubZone>[];
    }
  }

  List<SubZone> getSubZonesForZone({required String parentZoneId}) {
    try {
      return projectManager.getSubZonesForZone(parentZoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get subzones for zone: $e");
      throwError("Failed to get subzones for zone: $e");
      return <SubZone>[];
    }
  }

  void addSubZoneToZone({required String subZoneId, required String parentZoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addSubZoneToZone(subZoneId, parentZoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add subzone to zone: $e");
      throwError("Failed to add subzone to zone: $e");
    }
  }

  void removeSubZoneFromZone({required String subZoneId, required String parentZoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeSubZoneFromZone(subZoneId, parentZoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove subzone from zone: $e");
      throwError("Failed to remove subzone from zone: $e");
    }
  }

  //
  // List<HardwareComponent> getHardwareInSubZone({required String subZoneId}) {
  //   try {
  //     return projectManager.getHardwareInSubZone(subZoneId);
  //   } catch (e) {
  //     FusionLogger.log(tag: LogTag.project, message: "Failed to get hardware for subzone: $e");
  //     throwError("Failed to get hardware for subzone: $e");
  //     return <HardwareComponent>[];
  //   }
  // }

  void addCircuitToSubZone({required String subZoneId, required String circuitId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addCircuitToSubZone(subZoneId, circuitId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add circuit to subzone: $e");
      throwError("Failed to add circuit to subzone: $e");
    }
  }

  void removeCircuitFromSubZone({required String subZoneId, required String circuitId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeCircuitFromSubZone(subZoneId, circuitId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove circuit from subzone: $e");
      throwError("Failed to remove circuit from subzone: $e");
    }
  }

  List<CircuitModel> getCircuitsInSubZone({required String subZoneId}) {
    try {
      final SubZone? subZone = getSubZone(subZoneId: subZoneId);
      if (subZone == null) {
        throw Exception('SubZone with id $subZoneId does not exist');
      }
      return projectManager.getCircuitsInZone(subZoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get circuits for subzone: $e");
      throwError("Failed to get circuits for subzone: $e");
      return <CircuitModel>[];
    }
  }

  void addListeningAreaToSubZone({required String areaId, required String subZoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addListeningAreaToSubZone(areaId, subZoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add listening area to subzone: $e");
      throwError("Failed to add listening area to subzone: $e");
    }
  }

  void addMultipleListeningAreasToSubZone({required List<String> listeningAreaIds, required String subZoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addMultipleAreasToAddSubZone(listeningAreaIds, subZoneId);

      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add multiple listening areas to subzone: $e");

      throwError("Failed to add multiple listening areas to subzone: $e");
    }
  }

  void removeListeningAreaFromSubZone({required String areaId, required String subZoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeListeningAreaFromSubZone(areaId, subZoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove listening area from subzone: $e");
      throwError("Failed to remove listening area from subzone: $e");
    }
  }

  void removeMultipleListeningAreasFromSubZone({required List<String> listeningAreaIds, required String subZoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeMultipleListeningAreaFromSubZone(listeningAreaIds, subZoneId);

      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove multiple listening areas from subzone: $e");

      throwError("Failed to remove multiple listening areas from subzone: $e");
    }
  }

  List<ListeningArea> getListeningAreasInSubZone({required String subZoneId}) {
    try {
      return projectManager.getListeningAreasInSubZone(subZoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get listening areas for subzone: $e");
      throwError("Failed to get listening areas for subzone: $e");
      return <ListeningArea>[];
    }
  }

  void reOrderSubZoneInZone({
    required String parentId,
    required int oldIndex,
    required int newIndex,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOrderSubZones(parentId, oldIndex, newIndex);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to reorder subzones in zone: $e");
      throwError("Failed to reorder subzones in zone: $e");
    }
  }

  Zone? getZoneForSubZone({required String subZoneId}) {
    try {
      return projectManager.getZoneForSubZone(subZoneId: subZoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get zone for subzone: $e");
      throwError("Failed to get zone for subzone: $e");
    }
    return null;
  }

  Map<String, String> getSubZoneToZoneMap() {
    // find the parent zone for each subzone
    final Map<String, String> subZoneToZoneMap = <String, String>{};
    final List<SubZone> allSubZones = getAllSubZones();
    for (final SubZone subZone in allSubZones) {
      final Zone? parentZone = getZoneForSubZone(subZoneId: subZone.id);
      if (parentZone != null) {
        subZoneToZoneMap[subZone.id] = parentZone.id;
      }
    }
    return subZoneToZoneMap;
  }
}
