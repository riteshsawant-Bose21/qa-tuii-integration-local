import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension FloorViewModel on ProjectViewModel {
  //get Floor by id
  FloorModel? getFloor(String floorId) {
    try {
      return projectManager.getFloorById(floorId);
    } catch (e) {
      return null;
    }
  }

  void updateFloor(FloorModel floor) {
    try {
      final ResponseCallback<bool> responseCallback = projectManager.updateFloor(floor);
      if (responseCallback.success) {
        updateProject();
      } else {
        FusionLogger.log(tag: LogTag.project, message: "Failed to update floor: ${responseCallback.message}");
        throwError(responseCallback.message);
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update floor: $e");
    }
  }

  void addFloor(FloorModel floor) {
    try {
      final ResponseCallback<bool> responseCallback = projectManager.addFloor(floor);
      if (responseCallback.success) {
        updateProject();
      } else {
        FusionLogger.log(tag: LogTag.project, message: "Failed to add floor: ${responseCallback.message}");
        throwError(responseCallback.message);
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add floor: $e");
    }
  }

  void removeFloor(String floorId) {
    try {
      final ResponseCallback<bool> responseCallback = projectManager.removeFloor(floorId);
      if (responseCallback.success) {
        updateProject();
      } else {
        FusionLogger.log(tag: LogTag.project, message: "Failed to remove floor: ${responseCallback.message}");
        throwError(responseCallback.message);
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove floor: $e");
    }
  }

  List<FloorModel> getAllFloors() {
    try {
      return projectManager.getAllFloors();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all floors: $e");
      return <FloorModel>[];
    }
  }

  //Get Floor by id
  FloorModel getFloorById(String floorId) {
    try {
      return projectManager.getFloorById(floorId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get floor by id: $e");
      rethrow;
    }
  }
}
