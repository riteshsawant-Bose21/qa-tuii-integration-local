import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// A user-created snapshot page — groups selected snapshots under a name.
/// Displayed in the SNAPSHOT PAGE list and on the wall controller.
class SnapshotPageModel extends Equatable {
  final String id;
  final String name;
  final List<String> snapshotIds;

  SnapshotPageModel({
    String? id,
    required this.name,
    required this.snapshotIds,
  }) : id = id ?? "SNAPPAGE${DateTime.now().millisecondsSinceEpoch}";

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'snapshotIds': snapshotIds,
  };

  factory SnapshotPageModel.fromJson(Map<String, dynamic> json) {
    return SnapshotPageModel(
      id: json['id'] as String,
      name: json['name'] as String,
      snapshotIds: (json['snapshotIds'] as List<dynamic>).cast<String>(),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, snapshotIds];
}

/// Enum representing the available tabs in Configuration Control
enum ConfigControlTab {
  zoneControl,
  snapshotsScenes,
  schedule,
  message,
  settings,
}

/// Screen mode for the controller settings tab.
enum ScreenMode { light, dark }

/// Screen saver option for the controller settings tab.
enum ScreenSaverOption { dateAndTime, qrCode, homeScreen, blackScreen }

extension ScreenSaverOptionLabel on ScreenSaverOption {
  String get label {
    switch (this) {
      case ScreenSaverOption.dateAndTime:
        return 'Date and time';
      case ScreenSaverOption.qrCode:
        return 'QR Code';
      case ScreenSaverOption.homeScreen:
        return 'Home screen';
      case ScreenSaverOption.blackScreen:
        return 'Black screen';
    }
  }

  String get key => name; // 'dateAndTime' | 'qrCode' | 'homeScreen' | 'blackScreen'

  static ScreenSaverOption fromKey(String key) {
    return ScreenSaverOption.values.firstWhere(
      (ScreenSaverOption o) => o.name == key,
      orElse: () => ScreenSaverOption.qrCode,
    );
  }
}

extension ScreenModeX on ScreenMode {
  String get key => name; // 'light' | 'dark'

  static ScreenMode fromKey(String key) {
    return ScreenMode.values.firstWhere(
      (ScreenMode m) => m.name == key,
      orElse: () => ScreenMode.dark,
    );
  }
}

/// Schedule filter mode for the Schedule tab.
enum ScheduleDisplayMode {
  none,
  all,
  selected,
}

extension ScheduleDisplayModeX on ScheduleDisplayMode {
  String get key => name; // 'none' | 'all' | 'selected'

  static ScheduleDisplayMode fromKey(String key) {
    return ScheduleDisplayMode.values.firstWhere(
      (ScheduleDisplayMode m) => m.name == key,
      orElse: () => ScheduleDisplayMode.all,
    );
  }
}

/// Base state class for the Configuration Control feature
sealed class ConfigurationControlState extends Equatable {
  const ConfigurationControlState();

  /// Get controllers list (empty for non-loaded states)
  List<FusionController> get controllers => <FusionController>[];

  /// Get zones list (empty for non-loaded states)
  List<Zone> get zones => <Zone>[];

  /// Get sub-zones map for each zone (empty for non-loaded states)
  Map<String, List<SubZone>> get subZonesInZones => <String, List<SubZone>>{};

  /// Get scene sets list (empty for non-loaded states)
  List<SceneSetModel> get sceneSets => <SceneSetModel>[];

  /// Get snapshots map per scene set (empty for non-loaded states)
  Map<String, List<SnapshotsModel>> get snapshotsInSceneSets => <String, List<SnapshotsModel>>{};

  /// Get all standalone snapshots (empty for non-loaded states)
  List<SnapshotsModel> get allSnapshots => <SnapshotsModel>[];

  /// Snapshots linked to each snapshot page (pageId → linked snapshots list)
  Map<String, List<SnapshotsModel>> get snapshotsPerPage => <String, List<SnapshotsModel>>{};

  /// Snapshot IDs that are already assigned to some snapshot page (used/unavailable)
  Set<String> get usedSnapshotIds => <String>{};

  /// User-created snapshot pages (each page has a name + linked snapshot IDs)
  List<SnapshotPageModel> get snapshotPages => <SnapshotPageModel>[];

  // ── Message Player tab ──────────────────────────────────────────────────────

  /// All message-player sources available in the project.
  List<Source> get messagePlayers => <Source>[];

  /// IDs of message players whose checkbox is checked.
  Set<String> get selectedMessagePlayerIds => <String>{};

  /// The currently active/highlighted page in the PAGES panel (message tab).
  String? get selectedMessagePageId => null;

  /// Messages grouped by message-player source ID.
  Map<String, List<MessageModel>> get messagesPerPlayer => <String, List<MessageModel>>{};

  /// Selected message IDs per player (checkbox state).
  Map<String, Set<String>> get selectedMessageIdsPerPlayer => <String, Set<String>>{};

  // ── Schedule tab ────────────────────────────────────────────────────────────

  /// All schedules loaded from the project.
  List<ScheduleConfig> get allSchedules => <ScheduleConfig>[];

  /// Whether "Show upcoming items" is checked.
  bool get showUpcoming => false;

  /// Active filter mode in the Schedule tab.
  ScheduleDisplayMode get scheduleDisplayMode => ScheduleDisplayMode.all;

  /// Schedule IDs checked in "Show selected" mode.
  Set<String> get selectedScheduleIds => <String>{};

  /// Get selected controller ID
  String? get selectedControllerId => null;

  /// Get selected zone ID
  String? get selectedZoneId => null;

  /// Get current tab
  ConfigControlTab get currentTab => ConfigControlTab.zoneControl;

  /// Get search query
  String get searchQuery => '';

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet
class ConfigControlInitial extends ConfigurationControlState {
  const ConfigControlInitial();
}

/// Loading state - fetching data
class ConfigControlLoading extends ConfigurationControlState {
  const ConfigControlLoading();
}

/// Empty state - no controllers in project
class ConfigControlEmpty extends ConfigurationControlState {
  const ConfigControlEmpty();
}

/// Loaded state - controllers and zones successfully loaded
class ConfigControlLoaded extends ConfigurationControlState {
  @override
  final List<FusionController> controllers;

  @override
  final List<Zone> zones;

  @override
  final Map<String, List<SubZone>> subZonesInZones;

  @override
  final List<SceneSetModel> sceneSets;

  @override
  final Map<String, List<SnapshotsModel>> snapshotsInSceneSets;

  /// All standalone snapshots
  @override
  final List<SnapshotsModel> allSnapshots;

  /// Snapshots linked to each snapshot page (pageId → linked snapshots)
  @override
  final Map<String, List<SnapshotsModel>> snapshotsPerPage;

  /// Snapshot IDs already assigned to some snapshot page
  @override
  final Set<String> usedSnapshotIds;

  /// User-created snapshot pages
  @override
  final List<SnapshotPageModel> snapshotPages;

  // ── Message Player tab ─────────────────────────────────────────────────────

  @override
  final List<Source> messagePlayers;

  @override
  final Set<String> selectedMessagePlayerIds;

  @override
  final String? selectedMessagePageId;

  @override
  final Map<String, List<MessageModel>> messagesPerPlayer;

  @override
  final Map<String, Set<String>> selectedMessageIdsPerPlayer;

  // ── Schedule tab ──────────────────────────────────────────────────────────

  @override
  final List<ScheduleConfig> allSchedules;

  @override
  final bool showUpcoming;

  @override
  final ScheduleDisplayMode scheduleDisplayMode;

  @override
  final Set<String> selectedScheduleIds;

  @override
  final String? selectedControllerId;

  @override
  final String? selectedZoneId;

  @override
  final ConfigControlTab currentTab;

  @override
  final String searchQuery;

  /// Selected zone IDs for Pro (checkbox multi-select)
  final Set<String> selectedZoneIds;

  /// Selected subzone IDs for Pro (checkbox multi-select)
  final Set<String> selectedSubZoneIds;

  /// Active subzone ID for LT (radio single-select)
  final String? activeSubZoneId;

  /// Selected scene set IDs (checkbox multi-select in SCENES panel)
  final Set<String> selectedSceneSetIds;

  /// Currently focused/active scene set ID (shows in PAGES panel + VIRTUAL CONTROLLER)
  final String? selectedSceneSetId;

  /// Currently active/recalled snapshot ID (radio button in VIRTUAL CONTROLLER)
  final String? activeSnapshotId;

  /// Currently selected snapshot page ID (highlighted in SNAPSHOT PAGE list)
  final String? selectedSnapshotPageId;

  // ── Display / Settings tab ────────────────────────────────────────────────

  /// Screen mode for the controller settings tab (per-controller).
  final ScreenMode screenMode;

  /// Screen saver option for the controller settings tab (per-controller).
  final ScreenSaverOption screenSaver;

  /// Screen sleep time in seconds for the controller settings tab (per-controller).
  final int sleepTime;

  const ConfigControlLoaded({
    required this.controllers,
    required this.zones,
    this.subZonesInZones = const <String, List<SubZone>>{},
    this.sceneSets = const <SceneSetModel>[],
    this.snapshotsInSceneSets = const <String, List<SnapshotsModel>>{},
    this.allSnapshots = const <SnapshotsModel>[],
    this.snapshotsPerPage = const <String, List<SnapshotsModel>>{},
    this.usedSnapshotIds = const <String>{},
    this.snapshotPages = const <SnapshotPageModel>[],
    this.messagePlayers = const <Source>[],
    this.selectedMessagePlayerIds = const <String>{},
    this.selectedMessagePageId,
    this.messagesPerPlayer = const <String, List<MessageModel>>{},
    this.selectedMessageIdsPerPlayer = const <String, Set<String>>{},
    this.allSchedules = const <ScheduleConfig>[],
    this.showUpcoming = false,
    this.scheduleDisplayMode = ScheduleDisplayMode.all,
    this.selectedScheduleIds = const <String>{},
    this.selectedControllerId,
    this.selectedZoneId,
    this.currentTab = ConfigControlTab.zoneControl,
    this.searchQuery = '',
    this.selectedZoneIds = const <String>{},
    this.selectedSubZoneIds = const <String>{},
    this.activeSubZoneId,
    this.selectedSceneSetIds = const <String>{},
    this.selectedSceneSetId,
    this.activeSnapshotId,
    this.selectedSnapshotPageId,
    this.screenMode = ScreenMode.dark,
    this.screenSaver = ScreenSaverOption.qrCode,
    this.sleepTime = 30,
  });

  /// Create a copy with updated values
  ConfigControlLoaded copyWith({
    List<FusionController>? controllers,
    List<Zone>? zones,
    Map<String, List<SubZone>>? subZonesInZones,
    List<SceneSetModel>? sceneSets,
    Map<String, List<SnapshotsModel>>? snapshotsInSceneSets,
    List<SnapshotsModel>? allSnapshots,
    Map<String, List<SnapshotsModel>>? snapshotsPerPage,
    Set<String>? usedSnapshotIds,
    List<SnapshotPageModel>? snapshotPages,
    List<Source>? messagePlayers,
    Set<String>? selectedMessagePlayerIds,
    String? selectedMessagePageId,
    Map<String, List<MessageModel>>? messagesPerPlayer,
    Map<String, Set<String>>? selectedMessageIdsPerPlayer,
    List<ScheduleConfig>? allSchedules,
    bool? showUpcoming,
    ScheduleDisplayMode? scheduleDisplayMode,
    Set<String>? selectedScheduleIds,
    String? selectedControllerId,
    String? selectedZoneId,
    ConfigControlTab? currentTab,
    String? searchQuery,
    Set<String>? selectedZoneIds,
    Set<String>? selectedSubZoneIds,
    String? activeSubZoneId,
    Set<String>? selectedSceneSetIds,
    String? selectedSceneSetId,
    String? activeSnapshotId,
    String? selectedSnapshotPageId,
    bool clearSelectedControllerId = false,
    bool clearSelectedZoneId = false,
    bool clearActiveSubZoneId = false,
    bool clearSelectedSceneSetId = false,
    bool clearActiveSnapshotId = false,
    bool clearSelectedSnapshotPageId = false,
    bool clearSelectedMessagePageId = false,
    ScreenMode? screenMode,
    ScreenSaverOption? screenSaver,
    int? sleepTime,
  }) {
    return ConfigControlLoaded(
      controllers: controllers ?? this.controllers,
      zones: zones ?? this.zones,
      subZonesInZones: subZonesInZones ?? this.subZonesInZones,
      sceneSets: sceneSets ?? this.sceneSets,
      snapshotsInSceneSets: snapshotsInSceneSets ?? this.snapshotsInSceneSets,
      allSnapshots: allSnapshots ?? this.allSnapshots,
      snapshotsPerPage: snapshotsPerPage ?? this.snapshotsPerPage,
      usedSnapshotIds: usedSnapshotIds ?? this.usedSnapshotIds,
      snapshotPages: snapshotPages ?? this.snapshotPages,
      messagePlayers: messagePlayers ?? this.messagePlayers,
      selectedMessagePlayerIds: selectedMessagePlayerIds ?? this.selectedMessagePlayerIds,
      selectedMessagePageId: clearSelectedMessagePageId ? null : (selectedMessagePageId ?? this.selectedMessagePageId),
      messagesPerPlayer: messagesPerPlayer ?? this.messagesPerPlayer,
      selectedMessageIdsPerPlayer: selectedMessageIdsPerPlayer ?? this.selectedMessageIdsPerPlayer,
      allSchedules: allSchedules ?? this.allSchedules,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      scheduleDisplayMode: scheduleDisplayMode ?? this.scheduleDisplayMode,
      selectedScheduleIds: selectedScheduleIds ?? this.selectedScheduleIds,
      selectedControllerId: clearSelectedControllerId ? null : (selectedControllerId ?? this.selectedControllerId),
      selectedZoneId: clearSelectedZoneId ? null : (selectedZoneId ?? this.selectedZoneId),
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedZoneIds: selectedZoneIds ?? this.selectedZoneIds,
      selectedSubZoneIds: selectedSubZoneIds ?? this.selectedSubZoneIds,
      activeSubZoneId: clearActiveSubZoneId ? null : (activeSubZoneId ?? this.activeSubZoneId),
      selectedSceneSetIds: selectedSceneSetIds ?? this.selectedSceneSetIds,
      selectedSceneSetId: clearSelectedSceneSetId ? null : (selectedSceneSetId ?? this.selectedSceneSetId),
      activeSnapshotId: clearActiveSnapshotId ? null : (activeSnapshotId ?? this.activeSnapshotId),
      selectedSnapshotPageId: clearSelectedSnapshotPageId ? null : (selectedSnapshotPageId ?? this.selectedSnapshotPageId),
      screenMode: screenMode ?? this.screenMode,
      screenSaver: screenSaver ?? this.screenSaver,
      sleepTime: sleepTime ?? this.sleepTime,
    );
  }

  /// Get filtered controllers based on search query
  List<FusionController> get filteredControllers {
    if (searchQuery.isEmpty) {
      return controllers;
    }
    final String query = searchQuery.toLowerCase();
    return controllers.where((FusionController c) => c.name.toLowerCase().contains(query)).toList();
  }

  /// Get the currently selected controller
  FusionController? get selectedController {
    if (selectedControllerId == null) return null;
    try {
      return controllers.firstWhere((FusionController c) => c.id == selectedControllerId);
    } catch (_) {
      return null;
    }
  }

  /// Check if the selected controller is a Pro type
  bool get isProController {
    final FusionController? controller = selectedController;
    if (controller == null) return false;
    final String sku = controller.sku.toLowerCase();
    final String name = controller.name.toLowerCase();
    return sku.contains('pro') || name.contains('pro');
  }

  /// Get zones associated with the selected controller
  List<Zone> get controllerZones {
    // For now, return all zones. In future, this can be filtered based on controller-zone mapping
    return zones;
  }

  @override
  List<Object?> get props => <Object?>[
    controllers,
    zones,
    subZonesInZones,
    sceneSets,
    snapshotsInSceneSets,
    allSnapshots,
    snapshotsPerPage,
    usedSnapshotIds,
    snapshotPages,
    messagePlayers,
    selectedMessagePlayerIds,
    selectedMessagePageId,
    messagesPerPlayer,
    selectedMessageIdsPerPlayer,
    allSchedules,
    showUpcoming,
    scheduleDisplayMode,
    selectedScheduleIds,
    selectedControllerId,
    selectedZoneId,
    currentTab,
    searchQuery,
    selectedZoneIds,
    selectedSubZoneIds,
    activeSubZoneId,
    selectedSceneSetIds,
    selectedSceneSetId,
    activeSnapshotId,
    selectedSnapshotPageId,
    screenMode,
    screenSaver,
    sleepTime,
  ];
}

/// Error state - failed to load data
class ConfigControlError extends ConfigurationControlState {
  final String message;

  const ConfigControlError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
