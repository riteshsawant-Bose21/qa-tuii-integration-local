import '../snapshot_api/snapshots_request.dart';

class SceneSetRequestDto {
  final List<SceneSetDto> sceneSets;

  SceneSetRequestDto({required this.sceneSets});

  factory SceneSetRequestDto.fromJson(Map<String, dynamic> json) {
    return SceneSetRequestDto(
      sceneSets: (json['scene_sets'] as List<dynamic>).map((dynamic item) => SceneSetDto.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scene_sets': sceneSets.map((SceneSetDto item) => item.toJson()).toList(),
    };
  }

  SceneSetRequestDto copyWith({List<SceneSetDto>? sceneSets}) {
    return SceneSetRequestDto(sceneSets: sceneSets ?? this.sceneSets);
  }

  @override
  String toString() => 'SceneSetRequestDto(sceneSets: $sceneSets)';
}

/// Represents a single scene set containing multiple scenes.
class SceneSetDto {
  final String setId;
  final String name;
  final String? defaultScene;
  final List<SnapshotItemDto> scenes;

  SceneSetDto({
    required this.setId,
    required this.name,
    this.defaultScene,
    required this.scenes,
  });

  factory SceneSetDto.fromJson(Map<String, dynamic> json) {
    return SceneSetDto(
      setId: json['set_id'] as String,
      name: json['name'] as String,
      defaultScene: json['default_scene'] as String?,
      scenes: (json['scenes'] as List<dynamic>).map((dynamic item) => SnapshotItemDto.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'set_id': setId,
      'name': name,
      'default_scene': defaultScene,
      'scenes': scenes.map((SnapshotItemDto item) => item.toJson()).toList(),
    };
  }

  SceneSetDto copyWith({
    String? setId,
    String? name,
    String? defaultScene,
    List<SnapshotItemDto>? scenes,
  }) {
    return SceneSetDto(
      setId: setId ?? this.setId,
      name: name ?? this.name,
      defaultScene: defaultScene ?? this.defaultScene,
      scenes: scenes ?? this.scenes,
    );
  }

  /// Get a scene by its ID.
  SnapshotItemDto? getSceneById(String id) {
    try {
      return scenes.firstWhere((SnapshotItemDto scene) => scene.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get the default scene object.
  SnapshotItemDto? get defaultSceneObject {
    if (defaultScene == null) return null;
    return getSceneById(defaultScene!);
  }

  @override
  String toString() => 'SceneSet(setId: $setId, name: $name, defaultScene: $defaultScene, scenes: $scenes)';
}
