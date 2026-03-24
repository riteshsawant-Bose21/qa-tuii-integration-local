import 'package:fusion_lib/fusion_lib.dart';

extension EquipLocationService on ProjectService {
  void addEquipLocation(EquipLocation equipLocation) {
    if (equipLocations.exists(equipLocation.id)) {
      throw Exception('EquipLocation with id ${equipLocation.id} already exists');
    }
    equipLocations.add(equipLocation.id, equipLocation);
  }

  void removeEquipLocation(String equipLocationId) {
    //remove all hardware in the equip location
    final hardwareIds = relationships.getChildren(
      RelationshipType.equipLocation,
      equipLocationId,
    );
    final copyOfHardwareList = List<String>.from(hardwareIds);
    for (final hw in copyOfHardwareList) {
      removeHardware(hw);
    }
    equipLocations.remove(equipLocationId);
    relationships.removeAllRelationships(equipLocationId);
  }

  void updateEquipLocation(EquipLocation equipLocation) {
    if (!equipLocations.exists(equipLocation.id)) {
      throw Exception('EquipLocation with id ${equipLocation.id} does not exist');
    }
    equipLocations.add(equipLocation.id, equipLocation);
  }

  List<EquipLocation> getAllEquipLocations() {
    return equipLocations.getAll();
  }

  EquipLocation getEquipLocationById(String equipLocationId) {
    final equipLocation = equipLocations.get(equipLocationId);
    if (equipLocation == null) {
      throw Exception('EquipLocation with id $equipLocationId does not exist');
    }
    return equipLocation;
  }

  void addHardwareToEquipLocation(String hardwareId, String equipLocationId) {
    final currentEquipLocation = relationships.getParent(
      RelationshipType.equipLocation,
      hardwareId,
    );
    if (currentEquipLocation != null) {
      relationships.unlink(RelationshipType.equipLocation, currentEquipLocation, hardwareId);
    }
    relationships.link(
      RelationshipType.equipLocation,
      equipLocationId,
      hardwareId,
    );
  }

  EquipLocation? getEquipLocationForHardware(String hardwareId) {
    final equipLocationId = relationships.getParent(
      RelationshipType.equipLocation,
      hardwareId,
    );
    if (equipLocationId == null) {
      return null;
    }
    final equipLocation = equipLocations.get(equipLocationId);

    return equipLocation;
  }

  List<HardwareComponent> getHardwareForEquipLocation(String equipLocationId) {
    final hardwareIds = relationships.getChildren(
      RelationshipType.equipLocation,
      equipLocationId,
    );
    final hardwareList = hardwareIds.map((hwId) => hardware.get(hwId)).whereType<HardwareComponent>().toList();
    return hardwareList;
  }

  void removeHardwareFromEquipLocation(String hardwareId, String equipLocationId) {
    relationships.unlink(
      RelationshipType.equipLocation,
      equipLocationId,
      hardwareId,
    );
  }
}
