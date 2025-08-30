import 'package:fusion_lib/fusion_lib.dart';

import '../project_view_model.dart';

extension ListeningAreaViewModel on ProjectViewModel {
  //get ListeningArea by id
  ListeningArea? getListeningArea(String areaId) {
    try {
      return projectManager.getListeningAreaById(areaId);
    } catch (e) {
      return null;
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
}
