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
  void removeFloor(String floorId) {
    List<HardwareComponent> allHardwareComponents = getAllHardwareInFloor(floorId);

    //delete Hardware in the floor
    for (final hw in allHardwareComponents) {
      removeHardware(hw.id);
    }

    floors.remove(floorId);
    final areas = relationships.getChildren(RelationshipType.floorAreas, floorId);
    relationships.removeAllRelationships(floorId);

    for (final areaId in areas) {
      removeListeningArea(areaId);
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

  FloorModel? getFloorForHardware({required String hardwareId}) {
    final floorIds = relationships.getParents(RelationshipType.hardwareFloor, hardwareId);
    if (floorIds.isNotEmpty) {
      final floorId = floorIds.first;
      final floor = floors.get(floorId);
      return floor;
    }
    return null;
  }

  // List<ListeningArea> getListeningAreasForFloor(String floorId) {
  //   final ids = relationships.getChildren(RelationshipType.floorListening, floorId);
  //   return ids.map((id) => listeningAreas.get(id)).where((a) => a != null).cast<ListeningArea>().toList();
  // }
}
