import '../../fusion_lib.dart';

extension ZoneManager on ProjectManager {
  //Add Zone
  void addZone(Zone zone) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addZone(zone);
  }

  /// Remove Zone
  void removeZone(String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeZone(zoneId);
  }

  ///Update Zone
  void updateZone(Zone updatedZone) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateZone(updatedZone);
  }

  List<Zone> getAllZones() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.zones.getAll();
  }

  // /// Add Speaker to Zone
  // void addSpeakerToZone(String speakerId, String zoneId) {
  //   if (projectService == null) {
  //     throw Exception('No project is currently open');
  //   }
  //   projectService!.addSpeakerToZone(speakerId, zoneId);
  // }
  //
  // /// Remove Speaker from Zone
  // void removeSpeakerFromZone(String speakerId, String zoneId) {
  //   if (projectService == null) {
  //     throw Exception('No project is currently open');
  //   }
  //   projectService!.removeSpeakerFromZone(speakerId, zoneId);
  // }

  // Get Zone by Id
  Zone getZoneById(String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getZoneById(zoneId)!;
  }

  List<ListeningArea> getListeningAreasForZone(String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getListeningAreasInZone(zoneId);
  }

  //Add Source Set to Zone
  void addSourceSetToZone(String sourceSetId, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addSourceSetToZone(sourceSetId, zoneId);
  }

  //Remove Source Set from Zone
  void removeSourceSetFromZone(String sourceSetId, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeSourceSetFromZone(sourceSetId, zoneId);
  }

  // Get Source Sets in Zone
  List<SourceSet> getSourceSetsInZone(String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getSourceSetsInZone(zoneId);
  }

  //add all missing methods from zone_service.dart
  void addCircuitToZone(String circuitId, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addCircuitToZone(circuitId, zoneId);
  }

  void removeCircuitFromZone(String circuitId, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeCircuitFromZone(circuitId, zoneId);
  }

  List<CircuitModel> getCircuitsInZone(String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getCircuitsInZone(zoneId);
  }

  void reOrderZones({required String zoneIdToMove, required String zoneAtNewIndex}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    Map<String, Zone> reorderedList = projectService!.reOrderZones(
      zoneIdToMove: zoneIdToMove,
      zoneAtNewIndexId: zoneAtNewIndex,
    );

    projectService = projectService!.copyWith(
      zones: projectService!.zones.copyWith(reorderedList),
    );
  }

  void addSourceToZone(String sourceId, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addSourceToZone(sourceId, zoneId);
  }

  void removeSourceFromZone(String sourceId, String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeSourceFromZone(sourceId, zoneId);
  }

  List<Source> getSourcesInZone(String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getSourcesInZone(zoneId);
  }

  List<Source> getSourcesAndSourceSetSourcesInZone(String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);
  }

  void addPrioritySourceToZone({required String sourceId, required String zoneId, required int priority}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addPrioritySourceToZone(sourceId: sourceId, zoneId: zoneId, priority: priority);
  }

  void removePrioritySourceFromZone({required String sourceId, required String zoneId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removePrioritySourceFromZone(sourceId: sourceId, zoneId: zoneId);
  }

  List<String> getPrioritySourcesInZone(String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getPrioritySourcesInZone(zoneId);
  }
}
