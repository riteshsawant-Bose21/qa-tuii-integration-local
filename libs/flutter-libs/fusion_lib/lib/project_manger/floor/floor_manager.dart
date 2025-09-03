import 'package:fusion_lib/fusion_lib.dart';

extension FloorManager on ProjectManager {
  /// ---------------------------------------------------------------
  ///   Floors Management
  /// ---------------------------------------------------------------

  /// Add a new floor to the current project
  ResponseCallback<bool> addFloor(FloorModel floor) {
    if (projectService == null) {
      return ResponseCallback.failure("No project is currently loaded.");
    }
    try {
      projectService!.addFloor(floor);
      return ResponseCallback.success(true);
    } catch (e) {
      return ResponseCallback.failure("Error adding floor: $e");
    }
  }

  /// Remove a floor from the current project by ID
  ResponseCallback<bool> removeFloor(String floorId) {
    if (projectService == null) {
      return ResponseCallback.failure("No project is currently loaded.");
    }
    try {
      projectService!.removeFloor(floorId);
      return ResponseCallback.success(true);
    } catch (e) {
      return ResponseCallback.failure("Error removing floor: $e");
    }
  }

  /// Update an existing floor in the current project
  ResponseCallback<bool> updateFloor(FloorModel updatedFloor) {
    if (projectService == null) {
      return ResponseCallback.failure("No project is currently loaded.");
    }
    try {
      projectService!.updateFloor(updatedFloor);
      return ResponseCallback.success(true);
    } catch (e) {
      return ResponseCallback.failure("Error updating floor: $e");
    }
  }

  /// Get all the floors
  List<FloorModel> getAllFloors() {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    return projectService!.getAllFloors();
  }

  /// Get Floor by Id
  FloorModel getFloorById(String floorId) {
    if (projectService == null) {
      throw Exception("No project is currently loaded.");
    }
    return projectService!.getFloorById(floorId);
  }
}
