import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/controller_page_model.dart';

import 'configuration_control_state.dart';

/// ViewModel/Cubit for the Configuration Control feature.
///
/// Follows the same [serviceLocator] pattern as [MessagePlayerConfigCubit]:
/// [ProjectViewModel] is accessed via a lazy getter — no constructor injection needed.
class ConfigurationControlViewmodel extends Cubit<ConfigurationControlState> {
  late final StreamSubscription<ProjectViewModelState> _projectSubscription;

  ConfigurationControlViewmodel() : super(const ConfigControlInitial()) {
    _loadData();
    // Re-sync whenever the project changes externally (controllers added / removed / updated)
    _projectSubscription = _projectViewModel.stream.listen((_) => _sync());
  }

  /// Lazy reference — never hold a field copy, always read from the locator.
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  // ─── Convenience helper ────────────────────────────────────────────────────

  /// Returns the current loaded state, or null if the cubit is not yet loaded.
  ConfigControlLoaded? get _loaded {
    final ConfigurationControlState s = state;
    return s is ConfigControlLoaded ? s : null;
  }

  @override
  Future<void> close() {
    _projectSubscription.cancel();
    return super.close();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

  /// Loads (or reloads) data from the project view model.
  /// Optimized with lazy loading - only loads data needed for the current tab and controller type.
  void _loadData({String? preserveControllerId, ConfigControlTab? forTab}) {
    if (_loaded == null) emit(const ConfigControlLoading());

    /// Detect whether we are switching to a different controller.
    final bool isControllerSwitch =
        preserveControllerId != null && _loaded?.selectedControllerId != null && preserveControllerId != _loaded!.selectedControllerId;

    try {
      final List<FusionController> controllers = _projectViewModel.fusionControllers;

      if (controllers.isEmpty) {
        emit(const ConfigControlEmpty());
        return;
      }

      // Keep the previously selected controller
      final FusionController selected = _resolveController(controllers, preserveControllerId);
      final bool isPro = _isProController(selected);

      // Determine which tab's data to load
      final ConfigControlTab targetTab = forTab ?? _loaded?.currentTab ?? ConfigControlTab.zoneControl;

      // ── Always load: Core data needed for all tabs ────────────────────────
      final List<Zone> zones = _projectViewModel.zones;
      final Map<String, List<SubZone>> subZonesInZones = _buildSubZonesMap(zones);

      // Load zone selection from relationship
      final Set<String> assignedZoneIds = _projectViewModel.getAssignedZoneIds(selected.id);
      final Set<String> allSubZoneIds = _projectViewModel.subZones.map((SubZone s) => s.id).toSet();
      final Set<String> selectedZoneIds = <String>{};
      final Set<String> selectedSubZoneIds = <String>{};
      for (final String id in assignedZoneIds) {
        (allSubZoneIds.contains(id) ? selectedSubZoneIds : selectedZoneIds).add(id);
      }

      // Restore persisted display config (needed for settings tab, lightweight to load)
      final ControllerDisplayConfig displayCfg = _projectViewModel.getControllerDisplayConfig(selected.id);

      // ── Conditionally load: Tab-specific data ──────────────────────────────

      // Determine what data to load based on controller type and tab
      final bool shouldLoadSnapshots =
          isPro && (targetTab == ConfigControlTab.snapshotsScenes || (!isControllerSwitch && _loaded != null && _loaded!.sceneSets.isNotEmpty));
      final bool shouldLoadMessages =
          isPro && (targetTab == ConfigControlTab.message || (!isControllerSwitch && _loaded != null && _loaded!.messagePlayers.isNotEmpty));
      final bool shouldLoadSchedules =
          isPro && (targetTab == ConfigControlTab.schedule || (!isControllerSwitch && _loaded != null && _loaded!.allSchedules.isNotEmpty));

      // ── Load Snapshot/Scene data ─────────────────────────────────────────
      List<SceneSetModel> sceneSets;
      Map<String, List<SnapshotsModel>> snapshotsInSceneSets;
      List<SnapshotsModel> allSnapshots;
      Map<String, List<SnapshotsModel>> snapshotsPerPage;
      Set<String> usedSnapshotIds;
      Set<String> selectedSceneSetIds;
      String? selectedSceneSetId;
      List<SnapshotPageModel> snapshotPages;

      if (shouldLoadSnapshots) {
        sceneSets = _projectViewModel.getAllSceneSets();
        snapshotsInSceneSets = <String, List<SnapshotsModel>>{
          for (final SceneSetModel s in sceneSets) s.id: _projectViewModel.getSnapshotInSceneSet(sceneSetId: s.id),
        };
        allSnapshots = _projectViewModel.getAllSnapshots();
        snapshotsPerPage = _computeSnapshotsPerPage(snapshotsInSceneSets);
        usedSnapshotIds = _computeUsedSnapshotIds(snapshotsPerPage);

        // Load persisted pages from relationship
        final List<ControllerPageModel> controllerPages = _projectViewModel.getControllerPages(selected.id);
        final Set<String> validSceneSetIds = sceneSets.map((SceneSetModel s) => s.id).toSet();
        selectedSceneSetIds = <String>{};
        snapshotPages = <SnapshotPageModel>[];

        for (final ControllerPageModel page in controllerPages) {
          if (page.type == ControllerPageType.sceneSet && validSceneSetIds.contains(page.id)) {
            selectedSceneSetIds.add(page.id);
          } else if (page.type == ControllerPageType.snapshotPage) {
            final List<String> snapshotIds = _projectViewModel.getSnapshotIdsForPage(page.id).toList();
            snapshotPages.add(SnapshotPageModel(id: page.id, name: page.name, snapshotIds: snapshotIds));
          }
        }

        selectedSceneSetId =
            isControllerSwitch
                ? (sceneSets.isNotEmpty ? sceneSets.first.id : null)
                : (_loaded?.selectedSceneSetId ?? (sceneSets.isNotEmpty ? sceneSets.first.id : null));
      } else if (_loaded != null && _loaded!.sceneSets.isNotEmpty) {
        // Preserve previously loaded data
        sceneSets = _loaded!.sceneSets;
        snapshotsInSceneSets = _loaded!.snapshotsInSceneSets;
        allSnapshots = _loaded!.allSnapshots;
        snapshotsPerPage = _loaded!.snapshotsPerPage;
        usedSnapshotIds = _loaded!.usedSnapshotIds;
        selectedSceneSetIds = _loaded!.selectedSceneSetIds;
        selectedSceneSetId = _loaded!.selectedSceneSetId;
        snapshotPages = _loaded!.snapshotPages;
      } else {
        // Empty defaults
        sceneSets = const <SceneSetModel>[];
        snapshotsInSceneSets = const <String, List<SnapshotsModel>>{};
        allSnapshots = const <SnapshotsModel>[];
        snapshotsPerPage = const <String, List<SnapshotsModel>>{};
        usedSnapshotIds = const <String>{};
        selectedSceneSetIds = const <String>{};
        selectedSceneSetId = null;
        snapshotPages = const <SnapshotPageModel>[];
      }

      // ── Load Message data ────────────────────────────────────────────────
      List<Source> messagePlayers;
      Map<String, List<MessageModel>> messagesPerPlayer;
      Set<String> selectedMessagePlayerIds;
      String? selectedMessagePageId;
      Map<String, Set<String>> selectedMessageIdsPerPlayer;

      if (shouldLoadMessages) {
        messagePlayers =
            _projectViewModel.sources
                .where(
                  (Source s) =>
                      s.type == SourceType.paging &&
                      (s.pagingSourceType == PagingSourceType.messagePlayer || s.pagingSourceType == PagingSourceType.messagePlayerWithZoneSelect),
                )
                .toList();
        messagesPerPlayer = <String, List<MessageModel>>{
          for (final Source s in messagePlayers) s.id: _projectViewModel.getMessagesForSource(s.id),
        };

        // Load persisted message selections from relationship
        final List<ControllerPageModel> controllerPages = _projectViewModel.getControllerPages(selected.id);
        selectedMessagePlayerIds = <String>{};
        selectedMessageIdsPerPlayer = <String, Set<String>>{};

        for (final ControllerPageModel page in controllerPages.where((ControllerPageModel p) => p.type == ControllerPageType.message)) {
          selectedMessagePlayerIds.add(page.id);
          selectedMessageIdsPerPlayer[page.id] = _projectViewModel.getMessageIdsForPage(page.id);
        }

        // Prefer in-memory when syncing IF it has data
        final bool useInMemorySelections = !isControllerSwitch && _loaded != null && _loaded!.selectedMessageIdsPerPlayer.isNotEmpty;
        if (useInMemorySelections) {
          selectedMessagePlayerIds = _loaded!.selectedMessagePlayerIds;
          selectedMessageIdsPerPlayer = _loaded!.selectedMessageIdsPerPlayer;
          selectedMessagePageId = _loaded!.selectedMessagePageId;
        } else {
          selectedMessagePageId =
              selectedMessagePlayerIds.isNotEmpty
                  ? (isControllerSwitch ? selectedMessagePlayerIds.last : (_loaded?.selectedMessagePageId ?? selectedMessagePlayerIds.last))
                  : null;
        }
      } else if (_loaded != null && _loaded!.messagePlayers.isNotEmpty) {
        // Preserve previously loaded data
        messagePlayers = _loaded!.messagePlayers;
        messagesPerPlayer = _loaded!.messagesPerPlayer;
        selectedMessagePlayerIds = _loaded!.selectedMessagePlayerIds;
        selectedMessagePageId = _loaded!.selectedMessagePageId;
        selectedMessageIdsPerPlayer = _loaded!.selectedMessageIdsPerPlayer;
      } else {
        // Empty defaults
        messagePlayers = const <Source>[];
        messagesPerPlayer = const <String, List<MessageModel>>{};
        selectedMessagePlayerIds = const <String>{};
        selectedMessagePageId = null;
        selectedMessageIdsPerPlayer = const <String, Set<String>>{};
      }

      // ── Load Schedule data ───────────────────────────────────────────────
      List<ScheduleConfig> allSchedules;
      bool showUpcoming;
      ScheduleDisplayMode scheduleDisplayMode;
      Set<String> selectedScheduleIds;

      if (shouldLoadSchedules) {
        allSchedules = _projectViewModel.getAllSchedules();
        final ControllerSchedulePageConfig schedCfg = _projectViewModel.getControllerScheduleConfig(selected.id);
        showUpcoming = schedCfg.showUpcoming;
        scheduleDisplayMode = ScheduleDisplayModeX.fromKey(schedCfg.displayMode);
        selectedScheduleIds = _projectViewModel.getSelectedScheduleIds(selected.id);
      } else if (_loaded != null && _loaded!.allSchedules.isNotEmpty) {
        // Preserve previously loaded data
        allSchedules = _loaded!.allSchedules;
        showUpcoming = _loaded!.showUpcoming;
        scheduleDisplayMode = _loaded!.scheduleDisplayMode;
        selectedScheduleIds = _loaded!.selectedScheduleIds;
      } else {
        // Empty defaults
        allSchedules = const <ScheduleConfig>[];
        showUpcoming = false;
        scheduleDisplayMode = ScheduleDisplayMode.all;
        selectedScheduleIds = const <String>{};
      }

      emit(
        ConfigControlLoaded(
          controllers: controllers,
          zones: zones,
          subZonesInZones: subZonesInZones,
          // Snapshot/Scene data
          sceneSets: sceneSets,
          snapshotsInSceneSets: snapshotsInSceneSets,
          allSnapshots: allSnapshots,
          snapshotsPerPage: snapshotsPerPage,
          usedSnapshotIds: usedSnapshotIds,
          selectedSceneSetIds: selectedSceneSetIds,
          selectedSceneSetId: selectedSceneSetId,
          activeSnapshotId: isControllerSwitch ? null : _loaded?.activeSnapshotId,
          snapshotPages: snapshotPages,
          selectedSnapshotPageId: isControllerSwitch ? null : _loaded?.selectedSnapshotPageId,
          // Controller/Zone selection
          selectedControllerId: selected.id,
          selectedZoneIds: selectedZoneIds,
          selectedZoneId: selectedZoneIds.isNotEmpty ? selectedZoneIds.first : null,
          selectedSubZoneIds: selectedSubZoneIds,
          activeSubZoneId: selectedSubZoneIds.isNotEmpty ? selectedSubZoneIds.first : null,
          currentTab: _resolveTab(targetTab, selected),
          searchQuery: _loaded?.searchQuery ?? '',
          // Message player state
          messagePlayers: messagePlayers,
          messagesPerPlayer: messagesPerPlayer,
          selectedMessagePlayerIds: selectedMessagePlayerIds,
          selectedMessagePageId: selectedMessagePageId,
          selectedMessageIdsPerPlayer: selectedMessageIdsPerPlayer,
          // Schedule state
          allSchedules: allSchedules,
          showUpcoming: showUpcoming,
          scheduleDisplayMode: scheduleDisplayMode,
          selectedScheduleIds: selectedScheduleIds,
          // Display config
          screenMode: ScreenModeX.fromKey(displayCfg.screenMode),
          screenSaver: ScreenSaverOptionLabel.fromKey(displayCfg.screenSaver),
          sleepTime: displayCfg.sleepTime,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ConfigControl: failed to load data: $e');
      emit(ConfigControlError(message: 'Failed to load data: $e'));
    }
  }

  /// Called by the project subscription — re-loads while keeping current selection.
  void _sync() => _loadData(preserveControllerId: _loaded?.selectedControllerId);

  /// Public refresh — useful when the caller knows data has changed.
  void refresh() => _sync();

  // ─── Controller helpers (used by UI widgets) ───────────────────────────────

  String getControllerLocation(FusionController controller) {
    if (controller.locationEntity.listeningAreaId != null) {
      final String areaId = controller.locationEntity.listeningAreaId!;
      final Zone? zone = _projectViewModel.getZonesForListeningArea(areaId: areaId);
      if (zone != null) return zone.name;

      final SubZone? sub = _projectViewModel.getSubZoneForListeningArea(areaId: areaId);
      if (sub != null) {
        return sub.name;
      }
    }
    return _projectViewModel.getEquipLocationForHardware(hardwareId: controller.id)?.name ?? '--';
  }

  Zone? getZoneForController(FusionController controller) {
    if (controller.locationEntity.listeningAreaId != null) {
      final String areaId = controller.locationEntity.listeningAreaId!;
      final Zone? zone = _projectViewModel.getZonesForListeningArea(areaId: areaId);
      if (zone != null) return zone;

      final SubZone? sub = _projectViewModel.getSubZoneForListeningArea(areaId: areaId);
      if (sub != null) return _projectViewModel.getZoneForSubZone(subZoneId: sub.id);
    }
    return null;
  }

  // ─── Controller actions ────────────────────────────────────────────────────

  void selectController(String controllerId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    if (loaded.selectedControllerId == controllerId) return; // already selected

    // Reload ALL per-controller persisted data (pages, messages, schedule,
    // display config) for the newly selected controller.
    // _loadData detects the ID change and resets transient selections.
    _loadData(preserveControllerId: controllerId);
  }

  void addController(FusionController controller) {
    _projectViewModel.addHardware(hardware: controller);
    _loadData(preserveControllerId: _loaded?.selectedControllerId);
  }

  void deleteController(String controllerId) {
    _projectViewModel.removeHardware(hardwareId: controllerId);

    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final List<FusionController> remaining = loaded.controllers.where((FusionController c) => c.id != controllerId).toList();

    if (remaining.isEmpty) {
      emit(const ConfigControlEmpty());
      return;
    }

    // Keep selection unless the deleted controller was selected
    final String? keepId = loaded.selectedControllerId == controllerId ? null : loaded.selectedControllerId;
    _loadData(preserveControllerId: keepId);
  }

  // ─── Zone / subzone actions ────────────────────────────────────────────────

  void selectZone(String zoneId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    // For LT controllers (radio behavior): clear all selections and select only this zone
    if (!loaded.isProController) {
      final Set<String> singleSelection = <String>{zoneId};

      // Persist zone assignment to the controller
      if (loaded.selectedControllerId != null) {
        _projectViewModel.setAssignedZonesForController(
          controllerId: loaded.selectedControllerId!,
          zoneIds: singleSelection,
          autoSave: true,
        );
      }

      emit(
        loaded.copyWith(
          selectedZoneId: zoneId,
          activeSubZoneId: null,
          selectedZoneIds: singleSelection,
          selectedSubZoneIds: <String>{},
        ),
      );
    } else {
      // For Pro controllers: just set the active zone (not selection)
      emit(loaded.copyWith(selectedZoneId: zoneId, activeSubZoneId: null));
    }
  }

  void toggleZoneSelection(String zoneId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final Set<String> updated = Set<String>.from(loaded.selectedZoneIds);
    updated.contains(zoneId) ? updated.remove(zoneId) : updated.add(zoneId);

    // Persist zone assignments to the controller
    if (loaded.selectedControllerId != null) {
      final Set<String> allAssignedIds = Set<String>.from(updated);
      allAssignedIds.addAll(loaded.selectedSubZoneIds);
      _projectViewModel.setAssignedZonesForController(
        controllerId: loaded.selectedControllerId!,
        zoneIds: allAssignedIds,
        autoSave: true,
      );
    }

    emit(loaded.copyWith(selectedZoneIds: updated));
  }

  bool isZoneSelected(String zoneId) => _loaded?.selectedZoneIds.contains(zoneId) ?? false;

  void selectSubZone(String subZoneId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    // For LT controllers (radio behavior): clear all selections and select only this subzone
    if (!loaded.isProController) {
      final Set<String> singleSelection = <String>{subZoneId};

      // Persist zone assignment to the controller
      if (loaded.selectedControllerId != null) {
        _projectViewModel.setAssignedZonesForController(
          controllerId: loaded.selectedControllerId!,
          zoneIds: singleSelection,
          autoSave: true,
        );
      }

      emit(
        loaded.copyWith(
          activeSubZoneId: subZoneId,
          selectedZoneId: null,
          selectedZoneIds: <String>{},
          selectedSubZoneIds: singleSelection,
        ),
      );
    } else {
      // For Pro controllers: just set the active subzone (not selection)
      emit(loaded.copyWith(activeSubZoneId: subZoneId, selectedZoneId: null));
    }
  }

  void toggleSubZoneSelection(String subZoneId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final Set<String> updated = Set<String>.from(loaded.selectedSubZoneIds);
    updated.contains(subZoneId) ? updated.remove(subZoneId) : updated.add(subZoneId);

    // Persist zone assignments to the controller
    if (loaded.selectedControllerId != null) {
      final Set<String> allAssignedIds = Set<String>.from(loaded.selectedZoneIds);
      allAssignedIds.addAll(updated);
      _projectViewModel.setAssignedZonesForController(
        controllerId: loaded.selectedControllerId!,
        zoneIds: allAssignedIds,
        autoSave: true,
      );
    }

    emit(loaded.copyWith(selectedSubZoneIds: updated));
  }

  bool isSubZoneSelected(String subZoneId) => _loaded?.selectedSubZoneIds.contains(subZoneId) ?? false;

  // ─── Tab / search ──────────────────────────────────────────────────────────

  /// Change tab and lazy-load data if needed.
  void changeTab(ConfigControlTab tab) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    // Check if we need to load data for this tab
    final bool isPro = loaded.isProController;
    bool needsDataLoad = false;

    // Check if tab-specific data needs to be loaded
    // We need to load if:
    // 1. Controller is Pro
    // 2. Tab requires specific data
    // 3. Data hasn't been loaded yet (empty list AND not the current/previous tab)
    if (isPro) {
      if (tab == ConfigControlTab.snapshotsScenes && loaded.sceneSets.isEmpty) {
        needsDataLoad = true;
      } else if (tab == ConfigControlTab.message && loaded.messagePlayers.isEmpty) {
        needsDataLoad = true;
      } else if (tab == ConfigControlTab.schedule && loaded.allSchedules.isEmpty) {
        needsDataLoad = true;
      }
    }

    if (needsDataLoad) {
      // Load data for the new tab
      _loadData(preserveControllerId: loaded.selectedControllerId, forTab: tab);
    } else {
      // Just update the tab without reloading
      emit(loaded.copyWith(currentTab: tab));
    }
  }

  void updateSearchQuery(String query) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(searchQuery: query));
  }

  void clearSearch() => updateSearchQuery('');

  // ─── Scene set / snapshot actions ──────────────────────────────────────────

  /// Toggle checkbox in the SCENES panel.
  /// ONLY updates selectedSceneSetIds — does NOT change the active scene set.
  /// (SCENES checkboxes and SNAPSHOT PAGE are independent.)
  /// Persists via [RelationshipType.controllerPages].
  void toggleSceneSetSelection(String sceneSetId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final bool wasChecked = loaded.selectedSceneSetIds.contains(sceneSetId);
    final Set<String> updated = Set<String>.from(loaded.selectedSceneSetIds);

    if (wasChecked) {
      updated.remove(sceneSetId);
    } else {
      updated.add(sceneSetId);
    }

    // Persist: both scene sets and snapshot pages in one call
    if (loaded.selectedControllerId != null) {
      _persistControllerPages(
        controllerId: loaded.selectedControllerId!,
        selectedSceneSetIds: updated,
        snapshotPages: loaded.snapshotPages,
      );
    }

    if (!wasChecked) {
      // Checked ON → activate this scene set row in PAGES, clear any snapshot page selection
      emit(
        loaded.copyWith(
          selectedSceneSetIds: updated,
          selectedSceneSetId: sceneSetId,
          selectedSnapshotPageId: null,
        ),
      );
    } else {
      // Checked OFF → if it was the active row, clear it
      final bool wasActive = loaded.selectedSceneSetId == sceneSetId;
      emit(
        loaded.copyWith(
          selectedSceneSetIds: updated,
          selectedSceneSetId: wasActive ? null : loaded.selectedSceneSetId,
        ),
      );
    }
  }

  /// Select the active scene set (shown in PAGES panel & SNAPSHOT PAGE section).
  /// Clears selectedSnapshotPageId so only one row is active at a time in PAGES.
  void selectSceneSet(String sceneSetId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(
      loaded.copyWith(
        selectedSceneSetId: sceneSetId,
        activeSnapshotId: null,
        selectedSnapshotPageId: null,
      ),
    );
  }

  /// Set the active/recalled snapshot (radio button in VIRTUAL CONTROLLER).
  void setActiveSnapshot(String snapshotId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(activeSnapshotId: snapshotId));
  }

  /// Create a new snapshot page — a user-defined grouping of selected snapshots.
  /// Persisted on the [FusionController] model (snapshotPagesData) and linked
  /// via [RelationshipType.controllerPages].
  void createSnapshotPage({
    required String name,
    required List<String> selectedSnapshotIds,
  }) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final String pageName = name.trim().isEmpty ? 'Untitled_Snapshot' : name.trim();
    final SnapshotPageModel newPage = SnapshotPageModel(
      name: pageName,
      snapshotIds: selectedSnapshotIds,
    );

    final List<SnapshotPageModel> updatedPages = <SnapshotPageModel>[...loaded.snapshotPages, newPage];

    // Persist to the project (scene sets + snapshot pages in one call)
    if (loaded.selectedControllerId != null) {
      _persistControllerPages(
        controllerId: loaded.selectedControllerId!,
        selectedSceneSetIds: loaded.selectedSceneSetIds,
        snapshotPages: updatedPages,
      );
    }

    emit(
      loaded.copyWith(
        snapshotPages: updatedPages,
        selectedSnapshotPageId: newPage.id,
        selectedSceneSetId: null,
      ),
    );
  }

  /// Delete a snapshot page by ID.
  /// Persists the removal to [RelationshipType.controllerPages] and the
  /// controller model's [snapshotPagesData].
  void deleteSnapshotPage(String pageId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final List<SnapshotPageModel> updatedPages = loaded.snapshotPages.where((SnapshotPageModel p) => p.id != pageId).toList();

    // Persist the removal (scene sets + updated snapshot pages in one call)
    if (loaded.selectedControllerId != null) {
      _persistControllerPages(
        controllerId: loaded.selectedControllerId!,
        selectedSceneSetIds: loaded.selectedSceneSetIds,
        snapshotPages: updatedPages,
      );
    }

    emit(
      loaded.copyWith(
        snapshotPages: updatedPages,
        selectedSnapshotPageId: loaded.selectedSnapshotPageId == pageId ? null : loaded.selectedSnapshotPageId,
      ),
    );
  }

  /// Select a snapshot page in the PAGES panel.
  /// Clears selectedSceneSetId so only one row is active at a time.
  void selectSnapshotPage(String pageId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(selectedSnapshotPageId: pageId, selectedSceneSetId: null));
  }

  // ─── Schedule tab actions ─────────────────────────────────────────────────

  /// Toggle the "Show upcoming items" checkbox and persist.
  void toggleShowUpcoming() {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final bool next = !loaded.showUpcoming;
    _persistScheduleConfig(loaded.copyWith(showUpcoming: next));
    emit(loaded.copyWith(showUpcoming: next));
  }

  /// Set filter mode (Show none / Show all / Show selected) and persist.
  void setScheduleDisplayMode(ScheduleDisplayMode mode) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    _persistScheduleConfig(loaded.copyWith(scheduleDisplayMode: mode));
    emit(loaded.copyWith(scheduleDisplayMode: mode));
  }

  /// Toggle a schedule checkbox in "Show selected" mode and persist.
  void toggleScheduleItemSelection(String scheduleId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final Set<String> updated = Set<String>.from(loaded.selectedScheduleIds);
    updated.contains(scheduleId) ? updated.remove(scheduleId) : updated.add(scheduleId);
    final ConfigControlLoaded next = loaded.copyWith(selectedScheduleIds: updated);
    _persistScheduleConfig(next);
    emit(next);
  }

  /// Toggle the enabled/disabled status of a schedule and reload.
  void toggleScheduleStatus(ScheduleConfig schedule) {
    _projectViewModel.updateSchedule(schedule: schedule.copyWith(status: !schedule.status));
    _sync();
  }

  // ─── Persistence helpers (schedule config) ────────────────────────────────

  void _persistScheduleConfig(ConfigControlLoaded state) {
    if (state.selectedControllerId == null) return;
    _projectViewModel.setControllerScheduleConfig(
      controllerId: state.selectedControllerId!,
      config: ControllerSchedulePageConfig(
        displayMode: state.scheduleDisplayMode.key,
        showUpcoming: state.showUpcoming,
      ),
    );
    // Persist selected schedule IDs via the controllerSchedules relationship
    _projectViewModel.setSelectedScheduleIds(
      controllerId: state.selectedControllerId!,
      scheduleIds: state.selectedScheduleIds,
    );
  }

  // ─── Persistence helpers (display config) ─────────────────────────────────

  void _persistDisplayConfig(ConfigControlLoaded state) {
    if (state.selectedControllerId == null) return;
    _projectViewModel.setControllerDisplayConfig(
      controllerId: state.selectedControllerId!,
      config: ControllerDisplayConfig(
        screenMode: state.screenMode.key,
        screenSaver: state.screenSaver.key,
        sleepTime: state.sleepTime,
      ),
    );
  }

  /// Update screen mode for the selected controller and persist.
  void setScreenMode(ScreenMode mode) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final ConfigControlLoaded next = loaded.copyWith(screenMode: mode);
    _persistDisplayConfig(next);
    emit(next);
  }

  /// Update screen saver option for the selected controller and persist.
  void setScreenSaver(ScreenSaverOption option) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final ConfigControlLoaded next = loaded.copyWith(screenSaver: option);
    _persistDisplayConfig(next);
    emit(next);
  }

  /// Update screen sleep time for the selected controller and persist.
  void setSleepTime(int seconds) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final ConfigControlLoaded next = loaded.copyWith(sleepTime: seconds);
    _persistDisplayConfig(next);
    emit(next);
  }

  /// Toggle message-player checkbox.
  /// Checking ON  → adds a page to the PAGES panel and makes it active.
  /// Checking OFF → removes the corresponding page; if it was active, the last
  ///                remaining checked player becomes active (or none).
  void toggleMessagePlayerSelection(String playerId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final bool wasChecked = loaded.selectedMessagePlayerIds.contains(playerId);
    final Set<String> updated = Set<String>.from(loaded.selectedMessagePlayerIds);

    if (wasChecked) {
      updated.remove(playerId);
    } else {
      updated.add(playerId);
    }

    String? newPageId;
    if (!wasChecked) {
      newPageId = playerId;
    } else if (loaded.selectedMessagePageId == playerId) {
      newPageId = updated.isNotEmpty ? updated.last : null;
    } else {
      newPageId = loaded.selectedMessagePageId;
    }

    // Persist: rebuild message pages list from updated selections
    if (loaded.selectedControllerId != null) {
      _persistControllerMessagePages(
        controllerId: loaded.selectedControllerId!,
        selectedPlayerIds: updated,
        selectedMessageIdsPerPlayer: loaded.selectedMessageIdsPerPlayer,
      );
    }

    emit(
      loaded.copyWith(
        selectedMessagePlayerIds: updated,
        selectedMessagePageId: newPageId,
      ),
    );
  }

  /// Select a message-player page (highlights it in the PAGES panel).
  void selectMessagePage(String playerId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(selectedMessagePageId: playerId));
  }

  /// Toggle individual message checkbox for a given player.
  void toggleMessageSelection(String playerId, String messageId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final Map<String, Set<String>> updatedMap = <String, Set<String>>{
      for (final MapEntry<String, Set<String>> e in loaded.selectedMessageIdsPerPlayer.entries) e.key: Set<String>.from(e.value),
    };

    final Set<String> playerSet = Set<String>.from(updatedMap[playerId] ?? <String>{});
    if (playerSet.contains(messageId)) {
      playerSet.remove(messageId);
    } else {
      playerSet.add(messageId);
    }
    updatedMap[playerId] = playerSet;

    // Persist
    if (loaded.selectedControllerId != null) {
      _persistControllerMessagePages(
        controllerId: loaded.selectedControllerId!,
        selectedPlayerIds: loaded.selectedMessagePlayerIds,
        selectedMessageIdsPerPlayer: updatedMap,
      );
    }

    emit(loaded.copyWith(selectedMessageIdsPerPlayer: updatedMap));
  }

  /// Get snapshots for a specific scene set.
  List<SnapshotsModel> getSnapshotsForSceneSet(String sceneSetId) {
    return _projectViewModel.getSnapshotInSceneSet(sceneSetId: sceneSetId);
  }

  /// For each snapshot page, collect the SnapshotsModel linked as recall actions.
  Map<String, List<SnapshotsModel>> _computeSnapshotsPerPage(
    Map<String, List<SnapshotsModel>> snapshotsInSceneSets,
  ) {
    final Map<String, List<SnapshotsModel>> result = <String, List<SnapshotsModel>>{};
    for (final List<SnapshotsModel> pages in snapshotsInSceneSets.values) {
      for (final SnapshotsModel page in pages) {
        final List<SceneActionModel> actions = _projectViewModel.getSceneActionsForSnapshot(page.id);
        final List<SnapshotsModel> linked = <SnapshotsModel>[];
        for (final SceneActionModel action in actions) {
          if (action.actionType == SceneActionType.snapshot && action.item != null) {
            final SnapshotsModel? snap = _projectViewModel.getSnapshotById(sceneId: action.item!.itemId);
            if (snap != null) linked.add(snap);
          }
        }
        result[page.id] = linked;
      }
    }
    return result;
  }

  /// Collect all snapshot IDs that have been linked to any snapshot page.
  Set<String> _computeUsedSnapshotIds(Map<String, List<SnapshotsModel>> snapshotsPerPage) {
    final Set<String> usedIds = <String>{};
    for (final List<SnapshotsModel> linked in snapshotsPerPage.values) {
      for (final SnapshotsModel snap in linked) {
        usedIds.add(snap.id);
      }
    }
    return usedIds;
  }

  // ─── Query helpers (called by child widgets) ───────────────────────────────

  List<Zone> getZonesForController(String controllerId) => _loaded?.zones ?? <Zone>[];

  List<SubZone> getSubZonesForZone(String zoneId) => _loaded?.subZonesInZones[zoneId] ?? <SubZone>[];

  // ─── Private helpers ───────────────────────────────────────────────────────

  FusionController _resolveController(
    List<FusionController> controllers,
    String? preferredId,
  ) {
    if (preferredId != null) {
      final FusionController? match = controllers.where((FusionController c) => c.id == preferredId).firstOrNull;
      if (match != null) return match;
    }
    return controllers.first;
  }

  /// Returns true if [controller] is a Pro type (same logic as [ControlTabBar]).
  bool _isProController(FusionController controller) {
    final String sku = controller.sku.toLowerCase();
    final String name = controller.name.toLowerCase();
    return sku.contains('pro') || name.contains('pro');
  }

  /// Returns the tabs available for [controller].
  List<ConfigControlTab> _availableTabsFor(FusionController controller) {
    if (_isProController(controller)) return ConfigControlTab.values;
    return <ConfigControlTab>[ConfigControlTab.zoneControl, ConfigControlTab.settings];
  }

  /// Returns [tab] if it is available for [controller], otherwise [ConfigControlTab.zoneControl].
  ConfigControlTab _resolveTab(ConfigControlTab tab, FusionController controller) {
    final List<ConfigControlTab> available = _availableTabsFor(controller);
    return available.contains(tab) ? tab : ConfigControlTab.zoneControl;
  }

  Map<String, List<SubZone>> _buildSubZonesMap(List<Zone> zones) {
    return <String, List<SubZone>>{
      for (final Zone zone in zones) zone.id: _projectViewModel.getSubZonesForZone(parentZoneId: zone.id),
    };
  }

  // ─── Persistence helpers (controllerPages) ────────────────────────────────

  /// Persists scene-set and snapshot pages.
  /// Preserves existing message pages so they are not overwritten.
  /// Snapshot IDs are stored in the [controllerPageSnapshots] relationship.
  void _persistControllerPages({
    required String controllerId,
    required Set<String> selectedSceneSetIds,
    required List<SnapshotPageModel> snapshotPages,
  }) {
    final List<SceneSetModel> allSceneSets = _loaded?.sceneSets ?? <SceneSetModel>[];

    // Build scene-set and snapshot pages (no snapshotIds in the model)
    final List<ControllerPageModel> newPages = <ControllerPageModel>[
      for (final String id in selectedSceneSetIds)
        ControllerPageModel(
          id: id,
          type: ControllerPageType.sceneSet,
          name: allSceneSets.firstWhere((SceneSetModel s) => s.id == id, orElse: () => SceneSetModel(id: id, name: id)).name,
        ),
      for (final SnapshotPageModel p in snapshotPages) ControllerPageModel(id: p.id, type: ControllerPageType.snapshotPage, name: p.name),
    ];

    // Preserve existing message pages
    final List<ControllerPageModel> existingMessagePages =
        _projectViewModel.getControllerPages(controllerId).where((ControllerPageModel p) => p.type == ControllerPageType.message).toList();

    _projectViewModel.setControllerPages(
      controllerId: controllerId,
      pages: <ControllerPageModel>[...newPages, ...existingMessagePages],
    );

    // Update snapshot ID relationships for each snapshot page
    for (final SnapshotPageModel p in snapshotPages) {
      _projectViewModel.setSnapshotIdsForPage(pageId: p.id, snapshotIds: p.snapshotIds.toSet());
    }
  }

  // ─── Persistence helpers (message pages) ──────────────────────────────────

  /// Persists message-player pages.
  /// Preserves existing scene-set and snapshot pages so they are not overwritten.
  /// Selected message IDs are stored in the [controllerPageMessages] relationship.
  void _persistControllerMessagePages({
    required String controllerId,
    required Set<String> selectedPlayerIds,
    required Map<String, Set<String>> selectedMessageIdsPerPlayer,
  }) {
    final List<ControllerPageModel> newMessagePages = <ControllerPageModel>[
      for (final String sourceId in selectedPlayerIds) ControllerPageModel(id: sourceId, type: ControllerPageType.message, name: ''),
    ];

    // Preserve existing non-message pages
    final List<ControllerPageModel> existingOtherPages =
        _projectViewModel.getControllerPages(controllerId).where((ControllerPageModel p) => p.type != ControllerPageType.message).toList();

    _projectViewModel.setControllerPages(
      controllerId: controllerId,
      pages: <ControllerPageModel>[...existingOtherPages, ...newMessagePages],
    );

    // Update message ID relationships for each player
    for (final String sourceId in selectedPlayerIds) {
      _projectViewModel.setMessageIdsForPage(
        pageId: sourceId,
        messageIds: selectedMessageIdsPerPlayer[sourceId] ?? <String>{},
      );
    }
  }
}
