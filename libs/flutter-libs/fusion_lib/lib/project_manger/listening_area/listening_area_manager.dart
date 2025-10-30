import 'package:fusion_lib/fusion_lib.dart';

extension ListeningAreaManager on ProjectManager {
  /// Add a new Listening Area
  void addListeningArea(ListeningArea listeningArea, String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addListeningArea(listeningArea, floorId);
  }

  /// Update a Listening area
  void updateListeningArea(ListeningArea listeningArea) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateListeningArea(listeningArea);
  }

  /// Remove Listening Area
  void removeListeningArea(String listeningAreaId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeListeningArea(listeningAreaId);
  }

  /// Get all the Listening area in a floor
  List<ListeningArea> getAllListeningAreaForFloor(String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getListeningAreasForFloor(floorId);
  }

  /// Add Listening Area to Zone
  void addListeningAreaToZone(String listeningAreaId, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.addListeningAreaToZone(listeningAreaId, zoneId);
  }

  void addMultipleAreasToAddZone(List<String> allAreasToAdd, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.addMultipleAreasToAddZone(allAreasToAdd, zoneId);
  }

  /// Remove Listening Area from Zone
  void removeListeningAreaFromZone(String listeningAreaId, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.removeListeningAreaFromZone(listeningAreaId, zoneId);
  }

  void removeMultipleListeningAreaFromZone(List<String> listeningAreaIds, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.removeMultipleListeningAreaFromZone(listeningAreaIds, zoneId);
  }

  FloorModel getFloorForListeningArea(String listeningAreaId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getFloorForListeningArea(listeningAreaId)!;
  }

  Zone? getZoneForListeningArea(String listeningAreaId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    Zone? zone = projectService!.getZoneForListeningArea(listeningAreaId);

    return zone;
  }

  //Get All Listening Area
  List<ListeningArea> getAllListeningAreas() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllListeningAreas();
  }

  //get Listening area by id
  ListeningArea getListeningAreaById(String listenAreaId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }

    return projectService!.getListeningAreaById(listenAreaId)!;
  }

  //get Available Listening Areas for Zone or subzone
  List<ListeningArea> getAvailableListeningAreasForZone({required String? id}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAvailableListeningAreasForZone(id);
  }

  //get Available Listening Areas for Zone or subzone
  List<ListeningArea> getAvailableListeningAreasForSubZone({String? subZoneId, required String parentZoneId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAvailableListeningAreasForSubZone(subZoneId: subZoneId, parentZone: parentZoneId);
  }
}
