import 'package:fusion_lib/fusion_lib.dart';

import '../project_view_model.dart';

extension WiringConnectionViewModel on ProjectViewModel {
  void addWiringConnection({required WiringConnectionModel connection, bool autoSave = true}) {
    try {
      projectManager.addWiringConnection(connection);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add wiring connection: $e");
      throwError("Failed to add wiring connection: $e");
    }
  }

  void removeWiringConnection({required String connectionId, bool autoSave = true}) {
    try {
      projectManager.removeWiringConnection(connectionId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove wiring connection: $e");
      throwError("Failed to remove wiring connection: $e");
    }
  }

  void updateWiringConnection({required WiringConnectionModel connection, bool autoSave = true}) {
    try {
      projectManager.updateWiringConnection(connection);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update wiring connection: $e");
      throwError("Failed to update wiring connection: $e");
    }
  }

  List<WiringConnectionModel> getAllWiringConnections() {
    try {
      return projectManager.getAllWiringConnections();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all wiring connections: $e");
      return <WiringConnectionModel>[];
    }
  }

  List<WiringConnectionModel>? getConnectionForDevice({required String deviceId}) {
    try {
      return projectManager.getConnectionForDevice(deviceId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get connections for device: $e");
      return null;
    }
  }
}
