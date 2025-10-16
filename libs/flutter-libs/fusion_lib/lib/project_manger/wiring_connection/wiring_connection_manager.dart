import 'package:fusion_lib/fusion_lib.dart';

extension WiringConnectionManager on ProjectManager {
  //Add Wiring Connection
  void addWiringConnection(WiringConnectionModel connection) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    if (projectService!.wiringConnection.exists(connection.id)) {
      throw Exception('WiringConnection with id ${connection.id} already exists');
    }
    projectService!.addWiringConnection(connection);
  }

  /// Remove Wiring Connection
  void removeWiringConnection(String connectionId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeWiringConnection(connectionId);
  }

  ///Update Wiring Connection
  void updateWiringConnection(WiringConnectionModel connection) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateWiringConnection(connection);
  }

  List<WiringConnectionModel> getAllWiringConnections() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllWiringConnections();
  }

  WiringConnectionModel? getConnectionForDevice(String deviceId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getConnectionForDevice(deviceId);
  }
}
