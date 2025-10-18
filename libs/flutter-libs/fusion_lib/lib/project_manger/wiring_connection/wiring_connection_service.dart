import 'package:fusion_lib/fusion_lib.dart';

extension WiringConnectionService on ProjectService {
  /// Add wiring connection into repo; create relationships based on its LocationModel.
  void addWiringConnection(WiringConnectionModel connection) {
    if (wiringConnection.exists(connection.id)) {
      throw Exception('WiringConnection ${connection.id} already exists');
    }

    wiringConnection.add(connection.id, connection);

    // Link to the relevant parent(s). Use wiringConnectionDevice relationship type.
    relationships.link(RelationshipType.wireConnection, connection.deviceId, connection.id);
    relationships.link(RelationshipType.wireConnection, connection.targetDeviceId, connection.id);
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

  List<WiringConnectionModel>? getConnectionForDevice(String deviceId) {
    final connectionIds = relationships.getChildren(RelationshipType.wireConnection, deviceId);
    if (connectionIds.isNotEmpty) {
      return connectionIds.map((id) => wiringConnection.get(id)).whereType<WiringConnectionModel>().toList();
    } else {
      return null;
    }
  }
}
