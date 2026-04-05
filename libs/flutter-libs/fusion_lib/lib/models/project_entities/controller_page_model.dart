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

/// A persisted message-player page entry on a [FusionController].
///
/// Stores which message-player source is checked, and which of its
/// messages the user has selected (checked) in the MESSAGE LIST panel.
class ControllerMessagePageModel {
  /// The message-player [Source] ID.
  final String sourceId;

  /// IDs of messages whose checkbox is checked for this player.
  final List<String> selectedMessageIds;

  const ControllerMessagePageModel({
    required this.sourceId,
    this.selectedMessageIds = const <String>[],
  });

  ControllerMessagePageModel copyWith({
    String? sourceId,
    List<String>? selectedMessageIds,
  }) {
    return ControllerMessagePageModel(
      sourceId: sourceId ?? this.sourceId,
      selectedMessageIds: selectedMessageIds ?? this.selectedMessageIds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sourceId': sourceId,
    'selectedMessageIds': selectedMessageIds,
  };

  factory ControllerMessagePageModel.fromJson(Map<String, dynamic> json) {
    return ControllerMessagePageModel(
      sourceId: json['sourceId'] as String,
      selectedMessageIds: (json['selectedMessageIds'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    );
  }
}

// ─── Schedule page config ─────────────────────────────────────────────────────

/// Persisted schedule-tab settings for a [FusionController].
///
/// Stores which filter mode is active, whether upcoming events are shown, and
/// which specific scheduler IDs are selected (when in "selected" mode).
class ControllerSchedulePageConfig {
  /// 'none' | 'all' | 'selected'
  final String displayMode;

  /// Whether the "Show upcoming items" checkbox is checked.
  final bool showUpcoming;

  /// Schedule IDs that are checked when [displayMode] == 'selected'.
  final List<String> selectedScheduleIds;

  const ControllerSchedulePageConfig({
    this.displayMode = 'all',
    this.showUpcoming = false,
    this.selectedScheduleIds = const <String>[],
  });

  ControllerSchedulePageConfig copyWith({
    String? displayMode,
    bool? showUpcoming,
    List<String>? selectedScheduleIds,
  }) {
    return ControllerSchedulePageConfig(
      displayMode: displayMode ?? this.displayMode,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      selectedScheduleIds: selectedScheduleIds ?? this.selectedScheduleIds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'displayMode': displayMode,
    'showUpcoming': showUpcoming,
    'selectedScheduleIds': selectedScheduleIds,
  };

  factory ControllerSchedulePageConfig.fromJson(Map<String, dynamic> json) {
    return ControllerSchedulePageConfig(
      displayMode: json['displayMode'] as String? ?? 'all',
      showUpcoming: json['showUpcoming'] as bool? ?? false,
      selectedScheduleIds: (json['selectedScheduleIds'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    );
  }
}
