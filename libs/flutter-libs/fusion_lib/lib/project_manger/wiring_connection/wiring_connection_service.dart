import 'package:fusion_lib/fusion_lib.dart';

extension WiringConnectionService on ProjectService {
  /// Add wiring connection into repo; create relationships based on its LocationModel.
  void addWiringConnection(WiringConnectionModel connection) {
    if (wiringConnection.exists(connection.id)) {
      throw Exception('WiringConnection ${connection.id} already exists');
    }

    wiringConnection.add(connection.id, connection);

    // Link to the relevant parent(s). Use wiringConnectionDevice relationship type.
    relationships.link(RelationshipType.wiringConnectionDevice, connection.deviceId, connection.id);
    relationships.link(RelationshipType.wiringConnectionDevice, connection.targetDeviceId, connection.id);
  }

  /// Remove wiring connection and all relationships to/from it.
  void removeWiringConnection(String connectionId) {
    if (!wiringConnection.exists(connectionId)) return;
    // Remove relationship links
    relationships.removeAllRelationships(connectionId);
    // Remove repo entry
    wiringConnection.remove(connectionId);
  }

  void updateWiringConnection(WiringConnectionModel connection) {
    if (!wiringConnection.exists(connection.id)) {
      throw Exception('WiringConnection with id ${connection.id} does not exist');
    }
    wiringConnection.add(connection.id, connection);
  }

  List<WiringConnectionModel> getAllWiringConnections() {
    return wiringConnection.getAll();
  }

  WiringConnectionModel? getConnectionForDevice(String deviceId) {
    final connectionIds = relationships.getChildren(RelationshipType.wiringConnectionDevice, deviceId);
    if (connectionIds.isNotEmpty) {
      final connectionId = connectionIds.first;
      final connection = wiringConnection.get(connectionId);
      if (connection != null) {
        return connection;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}
