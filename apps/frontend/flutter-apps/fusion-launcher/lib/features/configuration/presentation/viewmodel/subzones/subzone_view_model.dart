import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension SubzoneViewModel on ProjectViewModel {
  //add SubZone
  void addSubZone(SubZone subZone) {
    try {
      projectManager.addSubZone(subZone);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add subzone: $e");
      throwError("Failed to add subzone: $e");
    }
  }

  //get SubZone by id
  SubZone? getSubZone(String subZoneId) {
    try {
      return projectManager.getSubZoneById(subZoneId);
    } catch (e) {
      return null;
    }
  }

  void updateSubZone(SubZone subZone) {
    try {
      projectManager.updateSubZone(subZone);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update subzone: $e");
      throwError("Failed to update subzone: $e");
    }
  }

  void updateListeningAreasInSubZone(String subZoneId, List<String> listeningAreaIds) {
    try {
      final List<ListeningArea> currentListeningAreas = getListeningAreasInSubZone(subZoneId);
      final List<String> currentListeningAreaIds = currentListeningAreas.map((ListeningArea e) => e.id).toList();
      final List<String> toRemove = currentListeningAreaIds.where((String id) => !listeningAreaIds.contains(id)).toList();
      final List<String> toAdd = listeningAreaIds.where((String id) => !currentListeningAreaIds.contains(id)).toList();
      for (final String id in toRemove) {
        projectManager.removeListeningAreaFromSubZone(id, subZoneId);
      }
      for (final String id in toAdd) {
        projectManager.addListeningAreaToSubZone(id, subZoneId);
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update listening areas for subzone: $e");
      throwError("Failed to update listening areas for subzone: $e");
    }
  }

  void removeSubZone(String subZoneId) {
    try {
      projectManager.removeSubZone(subZoneId);
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

  List<SubZone> getSubZonesForZone(String parentZoneId) {
    try {
      return projectManager.getSubZonesForZone(parentZoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get subzones for zone: $e");
      throwError("Failed to get subzones for zone: $e");
      return <SubZone>[];
    }
  }

  void addSubZoneToZone(String subZoneId, String parentZoneId) {
    try {
      projectManager.addSubZoneToZone(subZoneId, parentZoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add subzone to zone: $e");
      throwError("Failed to add subzone to zone: $e");
    }
  }

  void removeSubZoneFromZone(String subZoneId, String parentZoneId) {
    try {
      projectManager.removeSubZoneFromZone(subZoneId, parentZoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove subzone from zone: $e");
      throwError("Failed to remove subzone from zone: $e");
    }
  }

  List<HardwareComponent> getHardwareInSubZone(String subZoneId) {
    try {
      return projectManager.getHardwareInSubZone(subZoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get hardware for subzone: $e");
      throwError("Failed to get hardware for subzone: $e");
      return <HardwareComponent>[];
    }
  }

  void addCircuitToSubZone(String subZoneId, String circuitId) {
    try {
      projectManager.addCircuitToSubZone(subZoneId, circuitId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add circuit to subzone: $e");
      throwError("Failed to add circuit to subzone: $e");
    }
  }

  void removeCircuitFromSubZone(String subZoneId, String circuitId) {
    try {
      projectManager.removeCircuitFromSubZone(subZoneId, circuitId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove circuit from subzone: $e");
      throwError("Failed to remove circuit from subzone: $e");
    }
  }

  List<CircuitModel> getCircuitsInSubZone(String subZoneId) {
    try {
      final SubZone? subZone = getSubZone(subZoneId);
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

  void addListeningAreaToSubZone(String areaId, String subZoneId) {
    try {
      projectManager.addListeningAreaToSubZone(areaId, subZoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add listening area to subzone: $e");
      throwError("Failed to add listening area to subzone: $e");
    }
  }

  void removeListeningAreaFromSubZone(String areaId, String subZoneId) {
    try {
      projectManager.removeListeningAreaFromSubZone(areaId, subZoneId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove listening area from subzone: $e");
      throwError("Failed to remove listening area from subzone: $e");
    }
  }

  List<ListeningArea> getListeningAreasInSubZone(String subZoneId) {
    try {
      return projectManager.getListeningAreasInSubZone(subZoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get listening areas for subzone: $e");
      throwError("Failed to get listening areas for subzone: $e");
      return <ListeningArea>[];
    }
  }

  void reOrderSubZoneInZone(String parentId, int oldIndex, int newIndex) {
    try {
      projectManager.reOrderSubZones(parentId, oldIndex, newIndex);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to reorder subzones in zone: $e");
      throwError("Failed to reorder subzones in zone: $e");
    }
  }
}
