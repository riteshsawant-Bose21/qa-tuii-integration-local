import 'package:fusion_lib/fusion_lib.dart';

import '../project_view_model.dart';

extension WiringConnectionViewModel on ProjectViewModel {
  void addWiringConnection(WiringConnectionModel connection) {
    projectManager.addWiringConnection(connection);
  }

  void removeWiringConnection(String connectionId) {
    projectManager.removeWiringConnection(connectionId);
  }

  void updateWiringConnection(WiringConnectionModel connection) {
    projectManager.updateWiringConnection(connection);
  }

  List<WiringConnectionModel> getAllWiringConnections() {
    return projectManager.getAllWiringConnections();
  }

  WiringConnectionModel? getConnectionForDevice(String deviceId) {
    return projectManager.getConnectionForDevice(deviceId);
  }
}
