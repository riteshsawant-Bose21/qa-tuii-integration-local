import 'package:fusion_lib/models/project_entities/wall_model.dart';
import 'package:fusion_lib/project_manger/project/project_service.dart';

import '../project/project_relationship_manager.dart';

extension WallService on ProjectService {
  void addWall(Wall wall, String floorId, {bool overwriteIfLinked = false}) {
    // Validate floor exists
    if (!floors.exists(floorId)) {
      throw Exception('Floor $floorId not found');
    }

    // If area exists as repo entry, you may want to throw or update. We throw here.
    if (walls.exists(wall.id)) {
      throw Exception('ListeningArea ${wall.id} already exists in repository');
    }

    // If the area is already linked to a floor (shouldn't be since we didn't store it yet),
    // guard against external data cases (e.g., when loading pre-linked objects).
    final existingFloor = relationships.getParent(RelationshipType.floorWalls, wall.id);

    if (existingFloor != null) {
      if (!overwriteIfLinked) {
        throw Exception('ListeningArea ${wall.id} is already linked to floor $existingFloor');
      } else {
        // unlink previous relationship (move)
        relationships.unlink(RelationshipType.floorWalls, existingFloor, wall.id);
      }
    }

    // Add to repo and create the single floor relationship
    walls.add(wall.id, wall);

    relationships.link(RelationshipType.floorWalls, floorId, wall.id);
  }

  void removeWall(String wallId) {
    // Validate wall exists
    if (!walls.exists(wallId)) {
      throw Exception('Wall $wallId not found');
    }

    // Remove all relationships (e.g., to floor)
    relationships.removeAllRelationships(wallId);

    // Remove from repo
    walls.remove(wallId);
  }

  void updateWall(Wall wall) {
    // Validate wall exists
    if (!walls.exists(wall.id)) {
      throw Exception('Wall ${wall.id} not found');
    }

    walls.add(wall.id, wall);
  }

  List<Wall> getWallsForFloor(String floorId) {
    final wallIds = relationships.getChildren(RelationshipType.floorWalls, floorId);
    return wallIds.map((id) => walls.get(id)).whereType<Wall>().toList();
  }

  Wall getWallById(String wallId) {
    final wall = walls.get(wallId);
    if (wall == null) {
      throw Exception('Wall $wallId not found');
    }
    return wall;
  }

  List<Wall> getAllWalls() {
    return walls.getAll();
  }
}
