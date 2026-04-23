import 'package:fusion_lib/models/project_entities/wall_model.dart';

import '../../fusion_lib.dart';

extension WallManager on ProjectManager {
  void addWall(Wall wall, String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addWall(wall, floorId);
  }

  void updateWall(Wall wall) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateWall(wall);
  }

  void removeWall(String wallId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeWall(wallId);
  }

  Wall getWallById(String wallId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getWallById(wallId);
  }

  List<Wall> getWallsForFloor(String floorId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getWallsForFloor(floorId);
  }

  List<Wall> getAllWalls() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllWalls();
  }
}
