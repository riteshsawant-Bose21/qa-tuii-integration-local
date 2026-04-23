import 'package:fusion_lib/fusion_logger/logger.dart';
import 'package:fusion_lib/models/project_entities/wall_model.dart';
import 'package:fusion_lib/project_manger/wall/wall_manager.dart';

import '../project_view_model.dart';

extension WallViewModel on ProjectViewModel {
  void addWall({required Wall wall, required String floorId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addWall(wall, floorId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add wall: $e");
    }
  }

  void removeWall({required String wallId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeWall(wallId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove wall: $e");
    }
  }

  //get Wall by id
  Wall getWall({required String wallId}) {
    try {
      return projectManager.getWallById(wallId);
    } catch (e) {
      throw Exception("wall not found: $e");
    }
  }

  void updateWall({required Wall wall, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateWall(wall);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update wall: $e");
      throwError("Failed to update wall: $e");
    }
  }

  List<Wall> getAllWalls() {
    try {
      return projectManager.getAllWalls();
    } catch (e) {
      throw Exception("failed to get walls: $e");
    }
  }

  List<Wall> getWallsForFloor({required String floorId}) {
    try {
      return projectManager.getWallsForFloor(floorId);
    } catch (e) {
      throw Exception("failed to get walls for floor: $e");
    }
  }
}
