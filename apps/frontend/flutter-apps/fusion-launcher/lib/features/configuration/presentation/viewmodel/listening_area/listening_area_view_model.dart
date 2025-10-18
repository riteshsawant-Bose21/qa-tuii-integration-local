import 'package:fusion_lib/fusion_lib.dart';

import '../project_view_model.dart';

extension ListeningAreaViewModel on ProjectViewModel {
  //get ListeningArea by id
  ListeningArea getListeningArea(String areaId) {
    try {
      return projectManager.getListeningAreaById(areaId);
    } catch (e) {
      throw Exception("listening area not found: $e");
    }
  }

  void updateListeningArea(ListeningArea area) {
    try {
      projectManager.updateListeningArea(area);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update listening area: $e");
      throwError("Failed to update listening area: $e");
    }
  }

  void addListeningArea(ListeningArea area, String floorId) {
    try {
      projectManager.addListeningArea(area, floorId);

      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add listening area: $e");
    }
  }

  void removeListeningArea(String areaId) {
    try {
      projectManager.removeListeningArea(areaId);
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

  Zone? getZonesForListeningArea(String areaId) {
    try {
      return projectManager.getZoneForListeningArea(areaId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get zones for listening area: $e");
      return null;
    }
  }

  FloorModel? getFloorForListeningArea(String areaId) {
    try {
      return projectManager.getFloorForListeningArea(areaId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get floor for listening area: $e");
      return null;
    }
  }

  //get Listening Areas for Floor id
  List<ListeningArea> getListeningAreasForFloor(String floorId) {
    try {
      return projectManager.getAllListeningAreaForFloor(floorId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get listening areas for floor: $e");
      return <ListeningArea>[];
    }
  }

  ListeningArea? getListeningAreaForHardware(String hardwareId) {
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

  List<ListeningArea> getAvailableListeningAreasForZoneOrSubZone({required String id}) {
    try {
      return projectManager.getAvailableListeningAreasForZoneOrSubZone(id: id);
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
        final Zone? zone = getZonesForListeningArea(la.id);
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
}
