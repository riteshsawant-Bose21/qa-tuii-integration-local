/// Type of a page stored on a [FusionController].
enum ControllerPageType {
  /// A scene-set page — references an existing [SceneSetModel] by ID.
  sceneSet,

  /// A user-created snapshot page — has its own name + list of snapshot IDs
  /// (IDs are stored in the [RelationshipType.controllerPageSnapshots] relationship).
  snapshotPage,

  /// A message-player page — page ID equals the source/player ID.
  /// Selected message IDs are stored in the [RelationshipType.controllerPageMessages] relationship.
  message,
}

/// A persisted page entry on a [FusionController].
///
/// Represents scene-set selections, user-created snapshot pages, and
/// message-player pages in a single typed model stored in
/// [ControllerPageRepository].
///
/// Item links (snapshot IDs, message IDs) are NOT stored here — they live in
/// the [RelationshipManager] under the appropriate [RelationshipType].
class ControllerPageModel {
  /// For [ControllerPageType.sceneSet]    — the scene-set ID.
  /// For [ControllerPageType.snapshotPage] — a generated unique page ID.
  /// For [ControllerPageType.message]     — the message-player source ID.
  final String id;

  /// Whether this entry is a scene-set row, a user-created snapshot page,
  /// or a message-player page.
  final ControllerPageType type;

  /// Display name shown in the PAGES panel.
  final String name;

  const ControllerPageModel({
    required this.id,
    required this.type,
    required this.name,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'name': name,
  };

  factory ControllerPageModel.fromJson(Map<String, dynamic> json) {
    return ControllerPageModel(
      id: json['id'] as String,
      type: ControllerPageType.values.firstWhere(
        (ControllerPageType e) => e.name == json['type'],
        orElse: () => ControllerPageType.snapshotPage,
      ),
      name: json['name'] as String? ?? '',
    );
  }
}

// ─── Schedule page config ─────────────────────────────────────────────────────

/// Persisted schedule-tab settings for a [FusionController].
///
/// Stores which filter mode is active and whether upcoming events are shown.
/// Selected schedule IDs are stored separately in the
/// [RelationshipType.controllerSchedules] relationship (controller → schedule IDs).
class ControllerSchedulePageConfig {
  /// 'none' | 'all' | 'selected'
  final String displayMode;

  /// Whether the "Show upcoming items" checkbox is checked.
  final bool showUpcoming;

  const ControllerSchedulePageConfig({
    this.displayMode = 'all',
    this.showUpcoming = false,
  });

  ControllerSchedulePageConfig copyWith({
    String? displayMode,
    bool? showUpcoming,
  }) {
    return ControllerSchedulePageConfig(
      displayMode: displayMode ?? this.displayMode,
      showUpcoming: showUpcoming ?? this.showUpcoming,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'displayMode': displayMode,
    'showUpcoming': showUpcoming,
  };

  factory ControllerSchedulePageConfig.fromJson(Map<String, dynamic> json) {
    return ControllerSchedulePageConfig(
      displayMode: json['displayMode'] as String? ?? 'all',
      showUpcoming: json['showUpcoming'] as bool? ?? false,
    );
  }
}

// ─── Display config ───────────────────────────────────────────────────────────

/// Persisted display/settings-tab configuration for a [FusionController].
///
/// Stores the screen mode ('light'|'dark'), screen-saver option, and sleep time
/// so each controller retains its own settings independently.
class ControllerDisplayConfig {
  /// 'light' | 'dark'
  final String screenMode;

  /// 'dateAndTime' | 'qrCode' | 'homeScreen' | 'blackScreen'
  final String screenSaver;

  /// Screen sleep time in seconds (5–300).
  final int sleepTime;

  const ControllerDisplayConfig({
    this.screenMode = 'dark',
    this.screenSaver = 'qrCode',
    this.sleepTime = 30,
  });

  ControllerDisplayConfig copyWith({
    String? screenMode,
    String? screenSaver,
    int? sleepTime,
  }) {
    return ControllerDisplayConfig(
      screenMode: screenMode ?? this.screenMode,
      screenSaver: screenSaver ?? this.screenSaver,
      sleepTime: sleepTime ?? this.sleepTime,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'screenMode': screenMode,
    'screenSaver': screenSaver,
    'sleepTime': sleepTime,
  };

  factory ControllerDisplayConfig.fromJson(Map<String, dynamic> json) {
    return ControllerDisplayConfig(
      screenMode: json['screenMode'] as String? ?? 'dark',
      screenSaver: json['screenSaver'] as String? ?? 'qrCode',
      sleepTime: (json['sleepTime'] as num?)?.toInt() ?? 30,
    );
  }
}
