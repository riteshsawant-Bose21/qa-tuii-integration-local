/// -------------------
/// Relationship Manager
/// -------------------
enum RelationshipType {
  floorAreas,
  zoneAreas,
  zoneSourceSet,
  zoneSources,
  zoneSubZones,
  sourceSetSources,
  hardwareLocation,
  hardwareFloor,
  circuitHardware,
  zoneCircuits,
  wireConnection,
  processingBlock,
  prioritySources,
  priorityIndex,
  zoneFunctions,
}

class RelationshipManager {
  final Map<RelationshipType, Map<String, Set<String>>> _parentToChildren = {};
  final Map<RelationshipType, Map<String, Set<String>>> _childToParents = {};

  void link(RelationshipType type, String parentId, String childId) {
    _parentToChildren.putIfAbsent(type, () => {}).putIfAbsent(parentId, () => <String>{}).add(childId);

    _childToParents.putIfAbsent(type, () => {}).putIfAbsent(childId, () => <String>{}).add(parentId);
  }

  void unlink(RelationshipType type, String parentId, String childId) {
    _parentToChildren[type]?[parentId]?.remove(childId);
    _childToParents[type]?[childId]?.remove(parentId);
  }

  void reOrder(RelationshipType type, String parentId, List<String> newOrder) {
    if (!_parentToChildren.containsKey(type)) return;
    if (!_parentToChildren[type]!.containsKey(parentId)) return;

    _parentToChildren[type]?[parentId] = Set<String>.from(newOrder);
  }

  Set<String> getChildren(RelationshipType type, String parentId) => _parentToChildren[type]?[parentId] ?? {};

  Set<String> getParents(RelationshipType type, String childId) => _childToParents[type]?[childId] ?? {};

  String? getParent(RelationshipType type, String childId) {
    final parents = getParents(type, childId);
    return parents.isNotEmpty ? parents.first : null;
  }

  void removeAllRelationships(String entityId) {
    for (final parents in _parentToChildren.values) {
      parents.remove(entityId);
      for (final children in parents.values) {
        children.remove(entityId);
      }
    }
    for (final children in _childToParents.values) {
      children.remove(entityId);
      for (final parents in children.values) {
        parents.remove(entityId);
      }
    }
  }

  /// --- JSON Support ---
  Map<String, dynamic> toJson() {
    return {
      "parentToChildren": _parentToChildren.map((type, map) => MapEntry(type.toString(), map.map((k, v) => MapEntry(k, v.toList())))),
      "childToParents": _childToParents.map((type, map) => MapEntry(type.toString(), map.map((k, v) => MapEntry(k, v.toList())))),
    };
  }

  void fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    _parentToChildren.clear();
    _childToParents.clear();

    final parentJson = json["parentToChildren"] as Map<String, dynamic>? ?? {};
    final childJson = json["childToParents"] as Map<String, dynamic>? ?? {};

    for (final entry in parentJson.entries) {
      final type = RelationshipType.values.firstWhere((e) => e.toString() == entry.key);
      _parentToChildren[type] = {};
      (entry.value as Map<String, dynamic>).forEach((k, v) {
        _parentToChildren[type]![k] = Set<String>.from(v);
      });
    }

    for (final entry in childJson.entries) {
      final type = RelationshipType.values.firstWhere((e) => e.toString() == entry.key);
      _childToParents[type] = {};
      (entry.value as Map<String, dynamic>).forEach((k, v) {
        _childToParents[type]![k] = Set<String>.from(v);
      });
    }
  }
}
