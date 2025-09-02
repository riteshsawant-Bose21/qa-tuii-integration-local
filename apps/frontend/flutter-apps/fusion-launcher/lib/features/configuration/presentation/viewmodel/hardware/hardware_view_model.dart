import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension HardwareViewModel on ProjectViewModel {
  //get Hardware by id
  HardwareComponent? getHardware(String hardwareId) {
    try {
      return projectManager.getHardwareById(hardwareId);
    } catch (e) {
      return null;
    }
  }

  void updateHardware(HardwareComponent hardware) {
    try {
      projectManager.updateHardware(hardware);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update hardware: $e");
      throwError("Failed to update hardware: $e");
    }
  }

  void addHardware(HardwareComponent hardware) {
    try {
      projectManager.addHardware(hardware);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add hardware: $e");
    }
  }

  void removeHardware(String hardwareId) {
    try {
      projectManager.removeHardware(hardwareId);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove hardware: $e");
    }
  }

  List<HardwareComponent> getAllHardware() {
    try {
      return projectManager.getAllHardwareComponents();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all hardware: $e");
      return <HardwareComponent>[];
    }
  }

  List<HardwareComponent> getHardwareForListeningArea(String listeningAreaId) {
    try {
      return projectManager.getHardwareForListeningArea(listeningAreaId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get hardware for listening area: $e");
      return <HardwareComponent>[];
    }
  }

  List<HardwareComponent> getHardwareForFloor(String floorId) {
    try {
      return projectManager.getHardwareForFloor(floorId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get hardware for floor: $e");
      return <HardwareComponent>[];
    }
  }

  ResponseCallback<bool> moveHardware(String hardwareId, {String? listeningAreaId, String? floorId}) {
    try {
      final ResponseCallback<bool> responseCallback = projectManager.moveHardware(hardwareId, listeningAreaId: listeningAreaId, floorId: floorId);
      updateProject();
      return responseCallback;
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to move hardware: $e");
      return ResponseCallback<bool>.failure("Failed to move hardware: $e");
    }
  }

  List<HardwareComponent> getSpeakersInZone(String zoneId) {
    try {
      return projectManager.getHardwareInZone(zoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get speakers for zone: $e");
      return <HardwareComponent>[];
    }
  }

  // Update hardware location
  void updateHardwareLocation(String hardwareId, LocationModel newLocation) {
    try {
      projectManager.updateHardwareLocation(hardwareId, newLocation);
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update hardware location: $e");
      throwError("Failed to update hardware location: $e");
    }
  }
}
