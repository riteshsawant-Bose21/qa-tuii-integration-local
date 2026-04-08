import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

const Object _kClear = Object();

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

  /// Wake function option for the controller settings tab (per-controller).
  final WakeFunctionOption wakeFunction;

  /// Selected zone for wake function (if wakeFunction == zone).
  final String? wakeZoneId;

  // ignore: prefer_const_constructors_in_immutables
  ConfigControlLoaded({
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
    this.wakeFunction = WakeFunctionOption.lastScreen,
    this.wakeZoneId,
  });

  // ── Computed / cached properties ───────────────────────────────────────────

  /// Filtered controllers matching [searchQuery] — computed once per instance.
  late final List<FusionController> filteredControllers =
      searchQuery.isEmpty ? controllers : controllers.where((FusionController c) => c.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

  /// The currently selected [FusionController], or `null` if not found.
  late final FusionController? selectedController = controllers.where((FusionController c) => c.id == selectedControllerId).firstOrNull;

  /// Whether the selected controller is a Pro type (SKU or name contains "pro").
  late final bool isProController = () {
    final FusionController? c = selectedController;
    if (c == null) return false;
    final String sku = c.sku.toLowerCase();
    final String name = c.name.toLowerCase();
    return sku.contains('pro') || name.contains('pro');
  }();

  /// Zones associated with the selected controller.
  // TODO(future): filter by controller-zone mapping when available.
  List<Zone> get controllerZones => zones;

  // ── copyWith ───────────────────────────────────────────────────────────────

  /// Returns a copy with updated values.
  ///
  /// Nullable fields use the [_kClear] sentinel:
  /// - **Omit** the parameter → keeps the existing value.
  /// - Pass **`null`** → explicitly sets the field to `null`.
  /// - Pass a **value** → sets the field to that value.
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
    Object? selectedMessagePageId = _kClear,
    Map<String, List<MessageModel>>? messagesPerPlayer,
    Map<String, Set<String>>? selectedMessageIdsPerPlayer,
    List<ScheduleConfig>? allSchedules,
    bool? showUpcoming,
    ScheduleDisplayMode? scheduleDisplayMode,
    Set<String>? selectedScheduleIds,
    Object? selectedControllerId = _kClear,
    Object? selectedZoneId = _kClear,
    ConfigControlTab? currentTab,
    String? searchQuery,
    Set<String>? selectedZoneIds,
    Set<String>? selectedSubZoneIds,
    Object? activeSubZoneId = _kClear,
    Set<String>? selectedSceneSetIds,
    Object? selectedSceneSetId = _kClear,
    Object? activeSnapshotId = _kClear,
    Object? selectedSnapshotPageId = _kClear,
    ScreenMode? screenMode,
    ScreenSaverOption? screenSaver,
    int? sleepTime,
    WakeFunctionOption? wakeFunction,
    String? wakeZoneId,
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
      selectedMessagePageId: identical(selectedMessagePageId, _kClear) ? this.selectedMessagePageId : selectedMessagePageId as String?,
      messagesPerPlayer: messagesPerPlayer ?? this.messagesPerPlayer,
      selectedMessageIdsPerPlayer: selectedMessageIdsPerPlayer ?? this.selectedMessageIdsPerPlayer,
      allSchedules: allSchedules ?? this.allSchedules,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      scheduleDisplayMode: scheduleDisplayMode ?? this.scheduleDisplayMode,
      selectedScheduleIds: selectedScheduleIds ?? this.selectedScheduleIds,
      selectedControllerId: identical(selectedControllerId, _kClear) ? this.selectedControllerId : selectedControllerId as String?,
      selectedZoneId: identical(selectedZoneId, _kClear) ? this.selectedZoneId : selectedZoneId as String?,
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedZoneIds: selectedZoneIds ?? this.selectedZoneIds,
      selectedSubZoneIds: selectedSubZoneIds ?? this.selectedSubZoneIds,
      activeSubZoneId: identical(activeSubZoneId, _kClear) ? this.activeSubZoneId : activeSubZoneId as String?,
      selectedSceneSetIds: selectedSceneSetIds ?? this.selectedSceneSetIds,
      selectedSceneSetId: identical(selectedSceneSetId, _kClear) ? this.selectedSceneSetId : selectedSceneSetId as String?,
      activeSnapshotId: identical(activeSnapshotId, _kClear) ? this.activeSnapshotId : activeSnapshotId as String?,
      selectedSnapshotPageId: identical(selectedSnapshotPageId, _kClear) ? this.selectedSnapshotPageId : selectedSnapshotPageId as String?,
      screenMode: screenMode ?? this.screenMode,
      screenSaver: screenSaver ?? this.screenSaver,
      sleepTime: sleepTime ?? this.sleepTime,
      wakeFunction: wakeFunction ?? this.wakeFunction,
      wakeZoneId: wakeZoneId ?? this.wakeZoneId,
    );
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
    wakeFunction,
    wakeZoneId,
  ];
}

/// Error state - failed to load data
class ConfigControlError extends ConfigurationControlState {
  final String message;

  const ConfigControlError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}

// Wake function options for the controller settings tab.
enum WakeFunctionOption { lastScreen, homeScreen, zone }

extension WakeFunctionOptionLabel on WakeFunctionOption {
  String get label {
    switch (this) {
      case WakeFunctionOption.lastScreen:
        return 'Last screen visited';
      case WakeFunctionOption.homeScreen:
        return 'Home screen';
      case WakeFunctionOption.zone:
        return 'zone';
    }
  }
}
