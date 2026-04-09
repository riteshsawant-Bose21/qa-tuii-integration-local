import 'package:fusion_lib/fusion_lib.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';

class ConnectionManager {
  final Map<String, WiringConnectionModel> _connectionsByPort = <String, WiringConnectionModel>{};

  void syncWithProjectManager(ProjectViewModel projectManager) {
    _connectionsByPort.clear();
    final List<WiringConnectionModel> updatedConnections = projectManager.getAllWiringConnections();
    for (final WiringConnectionModel connection in updatedConnections) {
      _connectionsByPort[connection.portId] = connection;
      _connectionsByPort[connection.targetPortId] = connection;
    }
  }

  WiringConnectionModel? getConnectionForPort(String portId) {
    return _connectionsByPort[portId];
  }
}
