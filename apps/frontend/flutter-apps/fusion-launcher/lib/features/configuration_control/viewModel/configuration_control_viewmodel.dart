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

  // ─── Service-locator accessor (same pattern as MessagePlayerConfigCubit) ───

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
  ///
  /// Pass [preserveControllerId] to keep the current selection; otherwise the
  /// first controller is selected.
  /// When [preserveControllerId] differs from the currently selected controller
  /// (i.e. the user deliberately switched controllers) transient UI selections
  /// (active scene set, active snapshot, selected pages) are reset so the new
  /// controller starts with a clean slate while still restoring its own
  /// persisted data.
  void _loadData({String? preserveControllerId}) {
    if (_loaded == null) emit(const ConfigControlLoading());

    // Detect whether we are switching to a different controller.
    final bool isControllerSwitch =
        preserveControllerId != null && _loaded?.selectedControllerId != null && preserveControllerId != _loaded!.selectedControllerId;

    try {
      final List<FusionController> controllers = _projectViewModel.fusionControllers;

      if (controllers.isEmpty) {
        emit(const ConfigControlEmpty());
        return;
      }

      final List<Zone> zones = _projectViewModel.zones;
      final Map<String, List<SubZone>> subZonesInZones = _buildSubZonesMap(zones);

      // Load scene sets and snapshots
      final List<SceneSetModel> sceneSets = _projectViewModel.getAllSceneSets();
      final Map<String, List<SnapshotsModel>> snapshotsInSceneSets = _buildSnapshotsInSceneSetsMap(sceneSets);
      final List<SnapshotsModel> allSnapshots = _projectViewModel.getAllSnapshots();
      final Map<String, List<SnapshotsModel>> snapshotsPerPage = _computeSnapshotsPerPage(snapshotsInSceneSets);
      final Set<String> usedSnapshotIds = _computeUsedSnapshotIds(snapshotsPerPage);

      // Load message players
      // Load message players
      final List<Source> messagePlayers =
          _projectViewModel.sources
              .where(
                (Source s) =>
                    s.type == SourceType.paging &&
                    (s.pagingSourceType == PagingSourceType.messagePlayer || s.pagingSourceType == PagingSourceType.messagePlayerWithZoneSelect),
              )
              .toList();
      final Map<String, List<MessageModel>> messagesPerPlayer = <String, List<MessageModel>>{
        for (final Source s in messagePlayers) s.id: _projectViewModel.getMessagesForSource(s.id),
      };

      // Load schedules
      final List<ScheduleConfig> allSchedules = _projectViewModel.getAllSchedules();

      // Keep the previously selected controller when syncing; fall back to first.
      final FusionController selected = _resolveController(controllers, preserveControllerId);
      final _ZoneSelection sel = _buildZoneSelection(selected);

      // Restore persisted schedule config for selected controller
      final ControllerSchedulePageConfig schedCfg = _loadPersistedScheduleConfig(selected);

      // Restore persisted display config (screen mode/saver/sleep) for selected controller
      final ControllerDisplayConfig displayCfg = _loadPersistedDisplayConfig(selected);

      // ── Restore persisted pages data for the selected controller ──────────
      final _PersistedPages persisted = _loadPersistedPages(selected, sceneSets);
      final _PersistedMessagePages persistedMsg = _loadPersistedMessagePages(selected);

      emit(
        ConfigControlLoaded(
          controllers: controllers,
          zones: zones,
          subZonesInZones: subZonesInZones,
          sceneSets: sceneSets,
          snapshotsInSceneSets: snapshotsInSceneSets,
          allSnapshots: allSnapshots,
          snapshotsPerPage: snapshotsPerPage,
          usedSnapshotIds: usedSnapshotIds,
          selectedControllerId: selected.id,
          selectedZoneIds: sel.zoneIds,
          selectedZoneId: sel.zoneId,
          selectedSubZoneIds: sel.subZoneIds,
          activeSubZoneId: sel.activeSubZoneId,
          currentTab: _resolveTab(_loaded?.currentTab ?? ConfigControlTab.zoneControl, selected),
          searchQuery: _loaded?.searchQuery ?? '',
          // Restore persisted scene-set checkbox selections
          selectedSceneSetIds: persisted.selectedSceneSetIds,
          // When switching controllers reset transient selections; otherwise preserve.
          selectedSceneSetId:
              isControllerSwitch
                  ? (sceneSets.isNotEmpty ? sceneSets.first.id : null)
                  : (_loaded?.selectedSceneSetId ?? (sceneSets.isNotEmpty ? sceneSets.first.id : null)),
          activeSnapshotId: isControllerSwitch ? null : _loaded?.activeSnapshotId,
          // Restore persisted snapshot pages
          snapshotPages: persisted.snapshotPages,
          selectedSnapshotPageId: isControllerSwitch ? null : _loaded?.selectedSnapshotPageId,
          // Message player state (restore persisted selections)
          messagePlayers: messagePlayers,
          messagesPerPlayer: messagesPerPlayer,
          selectedMessagePlayerIds: persistedMsg.selectedMessagePlayerIds,
          selectedMessagePageId:
              persistedMsg.selectedMessagePlayerIds.isNotEmpty
                  ? (isControllerSwitch
                      ? persistedMsg.selectedMessagePlayerIds.last
                      : (_loaded?.selectedMessagePageId ?? persistedMsg.selectedMessagePlayerIds.last))
                  : null,
          selectedMessageIdsPerPlayer: persistedMsg.selectedMessageIdsPerPlayer,
          // Schedule state (restore persisted config)
          allSchedules: allSchedules,
          showUpcoming: schedCfg.showUpcoming,
          scheduleDisplayMode: ScheduleDisplayModeX.fromKey(schedCfg.displayMode),
          selectedScheduleIds: Set<String>.from(schedCfg.selectedScheduleIds),
          // Display config (restore per-controller settings)
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
        final Zone? parent = _projectViewModel.getZoneForSubZone(subZoneId: sub.id);
        return parent != null ? '${parent.name} > ${sub.name}' : sub.name;
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
    emit(loaded.copyWith(selectedZoneId: zoneId, clearActiveSubZoneId: true));
  }

  void toggleZoneSelection(String zoneId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final Set<String> updated = Set<String>.from(loaded.selectedZoneIds);
    updated.contains(zoneId) ? updated.remove(zoneId) : updated.add(zoneId);
    emit(loaded.copyWith(selectedZoneIds: updated));
  }

  bool isZoneSelected(String zoneId) => _loaded?.selectedZoneIds.contains(zoneId) ?? false;

  void selectSubZone(String subZoneId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(activeSubZoneId: subZoneId, clearSelectedZoneId: true));
  }

  void toggleSubZoneSelection(String subZoneId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final Set<String> updated = Set<String>.from(loaded.selectedSubZoneIds);
    updated.contains(subZoneId) ? updated.remove(subZoneId) : updated.add(subZoneId);
    emit(loaded.copyWith(selectedSubZoneIds: updated));
  }

  bool isSubZoneSelected(String subZoneId) => _loaded?.selectedSubZoneIds.contains(subZoneId) ?? false;

  // ─── Tab / search ──────────────────────────────────────────────────────────

  void changeTab(ConfigControlTab tab) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(currentTab: tab));
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
          clearSelectedSnapshotPageId: true,
        ),
      );
    } else {
      // Checked OFF → if it was the active row, clear it
      final bool wasActive = loaded.selectedSceneSetId == sceneSetId;
      emit(
        loaded.copyWith(
          selectedSceneSetIds: updated,
          clearSelectedSceneSetId: wasActive,
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
        clearActiveSnapshotId: true,
        clearSelectedSnapshotPageId: true,
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
        clearSelectedSceneSetId: true,
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
        clearSelectedSnapshotPageId: loaded.selectedSnapshotPageId == pageId,
      ),
    );
  }

  /// Select a snapshot page in the PAGES panel.
  /// Clears selectedSceneSetId so only one row is active at a time.
  void selectSnapshotPage(String pageId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(selectedSnapshotPageId: pageId, clearSelectedSceneSetId: true));
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

  ControllerSchedulePageConfig _loadPersistedScheduleConfig(FusionController controller) {
    return _projectViewModel.getControllerScheduleConfig(controller.id);
  }

  void _persistScheduleConfig(ConfigControlLoaded state) {
    if (state.selectedControllerId == null) return;
    _projectViewModel.setControllerScheduleConfig(
      controllerId: state.selectedControllerId!,
      config: ControllerSchedulePageConfig(
        displayMode: state.scheduleDisplayMode.key,
        showUpcoming: state.showUpcoming,
        selectedScheduleIds: state.selectedScheduleIds.toList(),
      ),
    );
  }

  // ─── Persistence helpers (display config) ─────────────────────────────────

  ControllerDisplayConfig _loadPersistedDisplayConfig(FusionController controller) {
    return _projectViewModel.getControllerDisplayConfig(controller.id);
  }

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
        clearSelectedMessagePageId: newPageId == null,
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

  /// Reload only scene set / snapshot data and re-emit.
  void _reloadSceneData() {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    try {
      final List<SceneSetModel> sceneSets = _projectViewModel.getAllSceneSets();
      final Map<String, List<SnapshotsModel>> snapshotsInSceneSets = _buildSnapshotsInSceneSetsMap(sceneSets);
      final List<SnapshotsModel> allSnapshots = _projectViewModel.getAllSnapshots();
      final Map<String, List<SnapshotsModel>> snapshotsPerPage = _computeSnapshotsPerPage(snapshotsInSceneSets);
      final Set<String> usedSnapshotIds = _computeUsedSnapshotIds(snapshotsPerPage);
      emit(
        loaded.copyWith(
          sceneSets: sceneSets,
          snapshotsInSceneSets: snapshotsInSceneSets,
          allSnapshots: allSnapshots,
          snapshotsPerPage: snapshotsPerPage,
          usedSnapshotIds: usedSnapshotIds,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ConfigControl: failed to reload scene data: $e');
    }
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

  Map<String, List<SnapshotsModel>> _buildSnapshotsInSceneSetsMap(List<SceneSetModel> sceneSets) {
    return <String, List<SnapshotsModel>>{
      for (final SceneSetModel s in sceneSets) s.id: _projectViewModel.getSnapshotInSceneSet(sceneSetId: s.id),
    };
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

  _ZoneSelection _buildZoneSelection(FusionController controller) {
    // Read from ControllerViewModel → ControllerManager → ControllerService
    // (RelationshipType.controllerZones) — the authoritative source.
    // Falls back to model's assignedZoneIds for backward compatibility.
    final Set<String> relZoneIds = _projectViewModel.getAssignedZoneIds(controller.id);
    final Set<String> assigned = relZoneIds.isNotEmpty ? relZoneIds : controller.assignedZoneIds;

    final Set<String> allSubZoneIds = _projectViewModel.subZones.map((SubZone s) => s.id).toSet();

    final Set<String> zoneIds = <String>{};
    final Set<String> subZoneIds = <String>{};

    for (final String id in assigned) {
      (allSubZoneIds.contains(id) ? subZoneIds : zoneIds).add(id);
    }

    return _ZoneSelection(
      zoneIds: zoneIds,
      zoneId: zoneIds.isNotEmpty ? zoneIds.first : null,
      subZoneIds: subZoneIds,
      activeSubZoneId: subZoneIds.isNotEmpty ? subZoneIds.first : null,
    );
  }

  Map<String, List<SubZone>> _buildSubZonesMap(List<Zone> zones) {
    return <String, List<SubZone>>{
      for (final Zone zone in zones) zone.id: _projectViewModel.getSubZonesForZone(parentZoneId: zone.id),
    };
  }

  // ─── Persistence helpers (controllerPages relationship) ────────────────────

  /// Restores the pages state for [controller] from [FusionController.pages] —
  /// partitions [ControllerPageType.sceneSet] entries into [selectedSceneSetIds]
  /// and [ControllerPageType.snapshotPage] entries into [snapshotPages].
  _PersistedPages _loadPersistedPages(
    FusionController controller,
    List<SceneSetModel> sceneSets,
  ) {
    final List<ControllerPageModel> allPages = _projectViewModel.getControllerPages(controller.id);

    // Valid scene-set IDs (guard against stale IDs if sets were deleted)
    final Set<String> validSceneSetIds = sceneSets.map((SceneSetModel s) => s.id).toSet();

    final Set<String> selectedSceneSetIds = <String>{};
    final List<SnapshotPageModel> snapshotPages = <SnapshotPageModel>[];

    for (final ControllerPageModel page in allPages) {
      if (page.type == ControllerPageType.sceneSet) {
        if (validSceneSetIds.contains(page.id)) {
          selectedSceneSetIds.add(page.id);
        }
      } else {
        snapshotPages.add(
          SnapshotPageModel(
            id: page.id,
            name: page.name,
            snapshotIds: page.snapshotIds,
          ),
        );
      }
    }

    return _PersistedPages(
      selectedSceneSetIds: selectedSceneSetIds,
      snapshotPages: snapshotPages,
    );
  }

  /// Persists both scene-set selections and snapshot pages as a unified
  /// [ControllerPageModel] list on the controller model.
  ///
  /// Scene sets need [sceneSets] to resolve their display names.
  void _persistControllerPages({
    required String controllerId,
    required Set<String> selectedSceneSetIds,
    required List<SnapshotPageModel> snapshotPages,
  }) {
    // Resolve scene-set names from the current loaded state
    final List<SceneSetModel> allSceneSets = _loaded?.sceneSets ?? <SceneSetModel>[];

    final List<ControllerPageModel> pages = <ControllerPageModel>[
      // Scene-set entries (type = sceneSet) — snapshotIds = snapshots inside the scene set
      for (final String id in selectedSceneSetIds)
        ControllerPageModel(
          id: id,
          type: ControllerPageType.sceneSet,
          name:
              allSceneSets
                  .firstWhere(
                    (SceneSetModel s) => s.id == id,
                    orElse: () => SceneSetModel(id: id, name: id),
                  )
                  .name,
          snapshotIds: (_loaded?.snapshotsInSceneSets[id] ?? <SnapshotsModel>[]).map((SnapshotsModel s) => s.id).toList(),
        ),

      // Snapshot-page entries (type = snapshotPage)
      for (final SnapshotPageModel p in snapshotPages)
        ControllerPageModel(
          id: p.id,
          type: ControllerPageType.snapshotPage,
          name: p.name,
          snapshotIds: p.snapshotIds,
        ),
    ];

    _projectViewModel.setControllerPages(
      controllerId: controllerId,
      pages: pages,
    );
  }
  // ─── Persistence helpers (controllerMessagePages relationship) ────────────

  /// Restores the message-pages state for [controller] from [FusionController.messagePages].
  _PersistedMessagePages _loadPersistedMessagePages(FusionController controller) {
    final List<ControllerMessagePageModel> allPages = _projectViewModel.getControllerMessagePages(controller.id);

    final Set<String> selectedPlayerIds = <String>{};
    final Map<String, Set<String>> selectedMessageIdsPerPlayer = <String, Set<String>>{};

    for (final ControllerMessagePageModel page in allPages) {
      selectedPlayerIds.add(page.sourceId);
      selectedMessageIdsPerPlayer[page.sourceId] = Set<String>.from(page.selectedMessageIds);
    }

    return _PersistedMessagePages(
      selectedMessagePlayerIds: selectedPlayerIds,
      selectedMessageIdsPerPlayer: selectedMessageIdsPerPlayer,
    );
  }

  /// Persists message-player selections and per-player message checkboxes as a
  /// [ControllerMessagePageModel] list on the controller model.
  void _persistControllerMessagePages({
    required String controllerId,
    required Set<String> selectedPlayerIds,
    required Map<String, Set<String>> selectedMessageIdsPerPlayer,
  }) {
    final List<ControllerMessagePageModel> pages = <ControllerMessagePageModel>[
      for (final String sourceId in selectedPlayerIds)
        ControllerMessagePageModel(
          sourceId: sourceId,
          selectedMessageIds: (selectedMessageIdsPerPlayer[sourceId] ?? <String>{}).toList(),
        ),
    ];

    _projectViewModel.setControllerMessagePages(
      controllerId: controllerId,
      messagePages: pages,
    );
  }
}

// ─── Private value objects ─────────────────────────────────────────────────────

class _PersistedPages {
  final Set<String> selectedSceneSetIds;
  final List<SnapshotPageModel> snapshotPages;

  const _PersistedPages({
    required this.selectedSceneSetIds,
    required this.snapshotPages,
  });
}

class _PersistedMessagePages {
  final Set<String> selectedMessagePlayerIds;
  final Map<String, Set<String>> selectedMessageIdsPerPlayer;

  const _PersistedMessagePages({
    required this.selectedMessagePlayerIds,
    required this.selectedMessageIdsPerPlayer,
  });
}

class _ZoneSelection {
  final Set<String> zoneIds;
  final String? zoneId;
  final Set<String> subZoneIds;
  final String? activeSubZoneId;

  const _ZoneSelection({
    required this.zoneIds,
    required this.zoneId,
    required this.subZoneIds,
    required this.activeSubZoneId,
  });
}
