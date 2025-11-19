import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension FucntionsViewModel on ProjectViewModel {
  void addFunctionToZone({required ZoneFunctions function, required String zoneId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addFunctionToZone(function: function, zoneId: zoneId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add function to zone : $ex");
      throwError("Failed to add function to zone : $ex");
    }
  }

  void removeFunction({required String functionId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeFunction(
        functionId: functionId,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove function  : $ex");
      throwError("Failed to remove function : $ex");
    }
  }

  ZoneFunctions? getFunctionById({required String functionId}) {
    try {
      return projectManager.getZoneFunctionById(
        functionId: functionId,
      );
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get function  : $ex");
      throwError("Failed to get function : $ex");
      return null;
    }
  }

  ZoneFunctions? getZoneFunctionForZone({required String zoneId}) {
    try {
      return projectManager.getZoneFunction(
        zoneId: zoneId,
      );
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get function for zone : $ex");
      throwError("Failed to get function for zone : $ex");
      return null;
    }
  }

  void updateZoneGain({required String zoneId, required double gain, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateZoneGain(
        zoneId: zoneId,
        gain: gain,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update zone gain : $ex");
      throwError("Failed to update zone gain : $ex");
    }
  }

  void muteZone({required String zoneId, required bool isMuted, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.muteZone(
        zoneId: zoneId,
        isMuted: isMuted,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to mute/unmute zone : $ex");
      throwError("Failed to mute/unmute zone : $ex");
    }
  }

  void updateSourceGain({required String sourceId, required double gain, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSourceGain(
        sourceId: sourceId,
        gain: gain,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update source gain : $ex");
      throwError("Failed to update source gain : $ex");
    }
  }

  void muteSource({required String sourceId, required bool isMuted, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.muteSource(
        sourceId: sourceId,
        isMuted: isMuted,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to mute/unmute source : $ex");
      throwError("Failed to mute/unmute source : $ex");
    }
  }

  void updateSourceMix({required String sourceId, required double leftMix, required double rightMix, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateSourceMix(
        sourceId: sourceId,
        leftMix: leftMix,
        rightMix: rightMix,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update source mix : $ex");
      throwError("Failed to update source mix : $ex");
    }
  }
}
