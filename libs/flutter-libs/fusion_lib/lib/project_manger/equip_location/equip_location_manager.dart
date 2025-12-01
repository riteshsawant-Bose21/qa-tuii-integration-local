import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/project_manger/equip_location/equip_location_service.dart';

extension EquipLocationManager on ProjectManager {
  //Add EquipLocation
  void addEquipLocation(EquipLocation equipLocation) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addEquipLocation(equipLocation);
  }

  /// Remove EquipLocation
  void removeEquipLocation(String equipLocationId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeEquipLocation(equipLocationId);
  }

  ///Update EquipLocation
  void updateEquipLocation(EquipLocation updatedEquipLocation) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateEquipLocation(updatedEquipLocation);
  }

  List<EquipLocation> getAllEquipLocations() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllEquipLocations();
  }

  // Get EquipLocation by Id
  EquipLocation getEquipLocationById(String equipLocationId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getEquipLocationById(equipLocationId);
  }

  void addHardwareToEquipLocation(String hardwareId, String equipLocationId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addHardwareToEquipLocation(hardwareId, equipLocationId);
  }

  List<HardwareComponent> getHardwareForEquipLocation(String equipLocationId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getHardwareForEquipLocation(equipLocationId);
  }

  void removeHardwareFromEquipLocation(String hardwareId, String equipLocationId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeHardwareFromEquipLocation(hardwareId, equipLocationId);
  }
}
