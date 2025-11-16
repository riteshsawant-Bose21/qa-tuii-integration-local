import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/project_manger/functions/functions_service.dart';

extension ZoneFunctionManager on ProjectManager {
  void addFunctionToZone({required ZoneFunctions function, required String zoneId}) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    projectService!.addFunctionToZone(function: function, zoneId: zoneId);
  }

  void removeFunction({required String functionId}) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    projectService!.removeFunction(functionId: functionId);
  }

  ZoneFunctions? getZoneFunction({required String zoneId}) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    return projectService!.getZoneFunction(zoneId: zoneId);
  }

  ZoneFunctions? getZoneFunctionById({required String functionId}) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    return projectService!.getZoneFunctionById(functionId: functionId);
  }

  void updateZoneGain({required String zoneId, required double gain}) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    projectService!.updateZoneGain(zoneId: zoneId, gain: gain);
  }

  void muteZone({required String zoneId, required bool isMuted}) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    projectService!.muteZone(zoneId: zoneId, isMuted: isMuted);
  }

  void updateSourceGain({required String sourceId, required double gain}) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    projectService!.updateSourceGain(sourceId: sourceId, gain: gain);
  }

  void muteSource({required String sourceId, required bool isMuted}) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    projectService!.muteSource(sourceId: sourceId, isMuted: isMuted);
  }

  void updateSourceMix({required String sourceId, required double leftMix, required double rightMix}) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    projectService!.updateSourceMix(sourceId: sourceId, leftMix: leftMix, rightMix: rightMix);
  }
}
