import 'package:fusion_lib/fusion_lib.dart';

extension FloorService on ProjectService {
  //Add Floor
  void addFloor(FloorModel floor) {
    if (floors.exists(floor.id)) {
      throw Exception('Floor with id ${floor.id} already exists');
    }
    floors.add(floor.id, floor);
  }

  /// Remove Floor
  void removeFloor(String floorId, {bool cascade = true}) {
    floors.remove(floorId);
    final areas = relationships.getChildren(RelationshipType.floorListening, floorId);
    relationships.removeAllRelationships(floorId);
    if (cascade) {
      for (final areaId in areas) {
        removeListeningArea(areaId);
      }
    }
  }

  ///Update Floor
  void updateFloor(FloorModel floor) {
    if (!floors.exists(floor.id)) {
      throw Exception('Floor with id ${floor.id} does not exist');
    }
    floors.add(floor.id, floor);
  }

  List<FloorModel> getAllFloors() {
    return floors.getAll();
  }

  FloorModel getFloorById(String floorId) {
    final floor = floors.get(floorId);
    if (floor == null) {
      throw Exception('Floor with id $floorId does not exist');
    }
    return floor;
  }

  // List<ListeningArea> getListeningAreasForFloor(String floorId) {
  //   final ids = relationships.getChildren(RelationshipType.floorListening, floorId);
  //   return ids.map((id) => listeningAreas.get(id)).where((a) => a != null).cast<ListeningArea>().toList();
  // }
}
