import 'package:fusion_lib/fusion_lib.dart';

extension SubZoneManager on ProjectManager {
  //Add SubZone
  void addSubZone(SubZone subZone) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addSubZone(subZone);
  }

  /// Remove SubZone
  void removeSubZone(String subZoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeSubZone(subZoneId);
  }

  ///Update SubZone
  void updateSubZone(SubZone updatedSubZone) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateSubZone(updatedSubZone);
  }

  List<SubZone> getAllSubZones() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllSubZones();
  }

  // Get SubZone by Id
  SubZone getSubZoneById(String subZoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getSubZoneById(subZoneId)!;
  }

  void addSubZoneToZone(String subZoneId, String parentZoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addSubZoneToZone(subZoneId, parentZoneId);
  }

  void removeSubZoneFromZone(String subZoneId, String parentZoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeSubZoneFromZone(subZoneId, parentZoneId);
  }

  List<ListeningArea> getListeningAreasInSubZone(String subZoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getListeningAreasInSubZone(subZoneId);
  }

  List<SubZone> getSubZonesForZone(String parentZoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getSubZones(parentZoneId);
  }

  //add Circuit to SubZone
  void addCircuitToSubZone(String subZoneId, String circuitId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addCircuitToSubZone(subZoneId, circuitId);
  }

  //remove Circuit from SubZone
  void removeCircuitFromSubZone(String subZoneId, String circuitId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeCircuitFromSubZone(subZoneId, circuitId);
  }

  void addListeningAreaToSubZone(String listeningAreaId, String subZoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.addListeningAreaToSubZone(listeningAreaId, subZoneId);
  }

  void removeListeningAreaFromSubZone(String listeningAreaId, String subZoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.removeListeningAreaFromSubZone(listeningAreaId, subZoneId);
  }

  void reOrderSubZones(String parentId, int oldIndex, int newIndex) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.reOrderSubZonesInZone(parentId, oldIndex, newIndex);
  }

  Zone getZoneForSubZone({required String subZoneId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getZoneForSubZone(subZoneId: subZoneId);
  }
}
