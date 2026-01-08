import 'package:fusion_lib/fusion_lib.dart';

extension HardwareManager on ProjectManager {
  //Add Hardware
  void addHardware(HardwareComponent hardware, {bool addToCircuit = true}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }

    projectService!.addHardware(hw: hardware, addToCircuit: addToCircuit);
  }

  /// Remove Hardware
  void removeHardware(String hardwareId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeHardware(hardwareId);
  }

  ///Update Hardware
  void updateHardware(HardwareComponent hardware) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    if (!projectService!.hardware.exists(hardware.id)) {
      throw Exception('Hardware with id ${hardware.id} does not exist');
    }
    projectService!.updateHardware(hardware);
  }

  List<HardwareComponent> getAllHardwareComponents() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllHardware();
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

  List<HardwareComponent> getAllHardwareInFloorWithPosition(String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllHardwareInFloorWithPosition(floorId: floorId);
  }

  List<HardwareComponent> getAllHardwareInFloorWithoutPosition(String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllHardwareInFloorWithoutPosition(floorId: floorId);
  }

  List<HardwareComponent> getAllHardwareInListeningAreaWithPosition(String listeningAreaId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllHardwareInListeningAreaWithPosition(listeningAreaId: listeningAreaId);
  }

  List<HardwareComponent> getAllHardwareInListeningAreaWithoutPosition(String listeningAreaId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllHardwareInListeningAreaWithoutPosition(listeningAreaId: listeningAreaId);
  }

  List<HardwareComponent> getHardwareForFloor(String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllHardwareInFloor(floorId);
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

  //update hardware location
  void updateHardwareLocation(String hardwareId, LocationModel newLocation) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateHardwareLocation(hardwareId, newLocation);
  }

  //add hardware to circuit
  void addHardwareAndCreateCircuit(HardwareComponent hw, String circuitId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    addHardware(hw, addToCircuit: false);
    projectService!.addHardwareToCircuit(hw.id, circuitId);
  }

  //get zone for hardware
  Zone? getZoneForHardware(String hardwareId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getZoneForHardware(hardwareId);
  }

  SubZone? getSubZoneForHardware(String hardwareId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getSubZoneForHardware(hardwareId);
  }

  CircuitModel? getCircuitForHardware(String hardwareId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getCircuitForHardware(hardwareId);
  }

  void reOrderHardware({required String hardwareIdToMove, required String hardwareAtNewIndex}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    Map<String, HardwareComponent> reorderedList = projectService!.reOrderHardware(
      hwToMoveId: hardwareIdToMove,
      hwAtNewIndexId: hardwareAtNewIndex,
    );

    projectService = projectService!.copyWith(
      hardware: projectService!.hardware.copyWith(reorderedList),
    );
  }
}
