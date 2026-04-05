/// Type of a page stored on a [FusionController].
enum ControllerPageType {
  /// A scene-set page — references an existing [SceneSetModel] by ID.
  sceneSet,

  /// A user-created snapshot page — has its own name + list of snapshot IDs.
  snapshotPage,
}

/// A persisted page entry on a [FusionController].
///
/// Represents BOTH scene-set selections (checkbox) and user-created snapshot
/// pages in a single, typed model stored in [FusionController.pages].
class ControllerPageModel {
  /// For [ControllerPageType.sceneSet] — the scene-set ID.
  /// For [ControllerPageType.snapshotPage] — a generated unique page ID.
  final String id;

  /// Whether this entry is a scene-set row or a user-created snapshot page.
  final ControllerPageType type;

  /// Display name shown in the PAGES panel.
  final String name;

  /// Snapshot IDs included in this page.
  /// Only meaningful for [ControllerPageType.snapshotPage]; empty for scene sets.
  final List<String> snapshotIds;

  const ControllerPageModel({
    required this.id,
    required this.type,
    required this.name,
    this.snapshotIds = const <String>[],
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'name': name,
    'snapshotIds': snapshotIds,
  };

  factory ControllerPageModel.fromJson(Map<String, dynamic> json) {
    return ControllerPageModel(
      id: json['id'] as String,
      type: ControllerPageType.values.firstWhere(
        (ControllerPageType e) => e.name == json['type'],
        orElse: () => ControllerPageType.snapshotPage,
      ),
      name: json['name'] as String,
      snapshotIds: (json['snapshotIds'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    );
  }
}
