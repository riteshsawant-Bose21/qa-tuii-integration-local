import 'package:fusion_lib/fusion_lib.dart';

extension HardwareManager on ProjectManager {
  //Add Hardware
  void addHardware(HardwareComponent hardware) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    if (projectService!.hardware.exists(hardware.id)) {
      throw Exception('Hardware with id ${hardware.id} already exists');
    }
    projectService!.hardware.add(hardware.id, hardware);
  }

  /// Remove Hardware
  void removeHardware(String hardwareId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.hardware.remove(hardwareId);
  }

  ///Update Hardware
  void updateHardware(HardwareComponent hardware) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    if (!projectService!.hardware.exists(hardware.id)) {
      throw Exception('Hardware with id ${hardware.id} does not exist');
    }
    projectService!.hardware.add(hardware.id, hardware);
  }

  List<HardwareComponent> getAllHardwareComponents() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.hardware.getAll();
  }

  /// Move Hardware
  ResponseCallback<bool> moveHardware(String hardwareId, {String? listeningAreaId, String? floorId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.moveHardware(hardwareId, listeningAreaId: listeningAreaId, floorId: floorId);

    return ResponseCallback.success(true);
  }

  List<HardwareComponent> getHardwareForListeningArea(String listeningAreaId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getHardwareForListeningArea(listeningAreaId);
  }

  List<HardwareComponent> getHardwareForFloor(String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllHardwareInFloor(floorId);
  }

  List<HardwareComponent> getHardwareInZone(String zoneId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getHardwareInZone(zoneId);
  }

  List<HardwareComponent> getAllNonPlacedHardwareInFloor(String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getHardwareForFloorDirect(floorId);
  }

  HardwareComponent getHardwareById(String hardwareId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    final hw = projectService!.getHardwareById(hardwareId);
    if (hw == null) {
      throw Exception('Hardware with id $hardwareId does not exist');
    }
    return hw;
  }
}
