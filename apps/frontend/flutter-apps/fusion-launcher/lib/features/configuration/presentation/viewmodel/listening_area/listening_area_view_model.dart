import 'package:fusion_lib/fusion_lib.dart';

import '../project_view_model.dart';

extension ListeningAreaViewModel on ProjectViewModel {
  //get ListeningArea by id
  ListeningArea getListeningArea({required String areaId}) {
    try {
      return projectManager.getListeningAreaById(areaId);
    } catch (e) {
      throw Exception("listening area not found: $e");
    }
  }

  void updateListeningArea({required ListeningArea area, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateListeningArea(area);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update listening area: $e");
      throwError("Failed to update listening area: $e");
    }
  }

  void addListeningArea({required ListeningArea area, required String floorId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addListeningArea(area, floorId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add listening area: $e");
    }
  }

  void removeListeningArea({required String areaId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeListeningArea(areaId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove listening area: $e");
    }
  }

  List<ListeningArea> getAllListeningAreas() {
    try {
      return projectManager.getAllListeningAreas();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all listening areas: $e");
      return <ListeningArea>[];
    }
  }

  Zone? getZonesForListeningArea({required String areaId}) {
    try {
      return projectManager.getZoneForListeningArea(areaId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get zones for listening area: $e");
      return null;
    }
  }

  // SubZone? getSubZoneForListeningArea({required String areaId}){
  //   try{
  //     return projectManager.getSubZoneForListeningArea(areaId);
  //   }catch (e) {
  //     FusionLogger.log(tag: LogTag.project, message: "Failed to get subzone for listening area: $e");
  //     return null;
  //   }
  // }

  FloorModel? getFloorForListeningArea({required String areaId}) {
    try {
      return projectManager.getFloorForListeningArea(areaId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get floor for listening area: $e");
      return null;
    }
  }

  //get Listening Areas for Floor id
  List<ListeningArea> getListeningAreasForFloor({required String floorId}) {
    try {
      return projectManager.getAllListeningAreaForFloor(floorId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get listening areas for floor: $e");
      return <ListeningArea>[];
    }
  }

  ListeningArea? getListeningAreaForHardware({required String hardwareId}) {
    try {
      final HardwareComponent hardwareComponent = projectManager.getHardwareById(hardwareId);
      final String? laId = hardwareComponent.locationEntity.listeningAreaId;
      if (laId != null) {
        return projectManager.getListeningAreaById(laId);
      } else {
        return null;
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get listening area for hardware: $e");
      return null;
    }
  }

  List<ListeningArea> getAvailableListeningAreasForZone({String? zoneId}) {
    try {
      return projectManager.getAvailableListeningAreasForZone(id: zoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get available listening areas for zone: $e");
      return <ListeningArea>[];
    }
  }

  List<ListeningArea> getAvailableListeningAreasForSubZone({required String parentZoneId, String? subZoneId}) {
    try {
      return projectManager.getAvailableListeningAreasForSubZone(subZoneId: subZoneId, parentZoneId: parentZoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get available listening areas for zone: $e");
      return <ListeningArea>[];
    }
  }

  Map<String, String> getListeningAreaToZoneMap() {
    try {
      final List<ListeningArea> allListeningAreas = getAllListeningAreas();
      final Map<String, String> laToZoneMap = <String, String>{};

      for (final ListeningArea la in allListeningAreas) {
        final Zone? zone = getZonesForListeningArea(areaId: la.id);
        if (zone != null) {
          laToZoneMap[la.id] = zone.id;
        }
      }

      return laToZoneMap;
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get listening area to zone map: $e");
      return <String, String>{};
    }
  }

  String getFullPathForListeningArea({required String areaId}) {
    final FloorModel? floor = getFloorForListeningArea(areaId: areaId);
    final ListeningArea listeningArea = getListeningArea(areaId: areaId);
    return "${floor?.name}/${listeningArea.name}";
  }

  String getFullPathForHardware({required String hardwareId}) {
    final ListeningArea? listeningArea = getListeningAreaForHardware(hardwareId: hardwareId);
    final FloorModel? floor = getFloorForHardware(hardwareId: hardwareId);
    if (listeningArea == null) {
      return floor?.name ?? "";
    }
    return "${floor?.name}/${listeningArea.name}";
  }
}
