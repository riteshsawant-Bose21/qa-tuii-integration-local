import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

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
  void _loadData({String? preserveControllerId}) {
    if (_loaded == null) emit(const ConfigControlLoading());

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

      // Keep the previously selected controller when syncing; fall back to first.
      final FusionController selected = _resolveController(controllers, preserveControllerId);
      final _ZoneSelection sel = _buildZoneSelection(selected);

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
          currentTab: _loaded?.currentTab ?? ConfigControlTab.zoneControl,
          searchQuery: _loaded?.searchQuery ?? '',
          // Checkboxes: preserve or start empty (no auto-check on first load)
          selectedSceneSetIds: _loaded?.selectedSceneSetIds ?? const <String>{},
          // Active scene (drives SNAPSHOT PAGE + VC): preserve or default to first
          selectedSceneSetId: _loaded?.selectedSceneSetId ?? (sceneSets.isNotEmpty ? sceneSets.first.id : null),
          activeSnapshotId: _loaded?.activeSnapshotId,
          snapshotPages: _loaded?.snapshotPages ?? const <SnapshotPageModel>[],
          selectedSnapshotPageId: _loaded?.selectedSnapshotPageId,
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

    final FusionController? controller = loaded.controllers.where((FusionController c) => c.id == controllerId).firstOrNull;
    if (controller == null) return;

    final _ZoneSelection sel = _buildZoneSelection(controller);
    emit(
      loaded.copyWith(
        selectedControllerId: controllerId,
        selectedZoneIds: sel.zoneIds,
        selectedZoneId: sel.zoneId,
        selectedSubZoneIds: sel.subZoneIds,
        activeSubZoneId: sel.activeSubZoneId,
      ),
    );
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
  void toggleSceneSetSelection(String sceneSetId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    final Set<String> updated = Set<String>.from(loaded.selectedSceneSetIds);
    if (updated.contains(sceneSetId)) {
      updated.remove(sceneSetId);
    } else {
      updated.add(sceneSetId);
    }
    // Only the checkbox state changes — active scene set stays the same
    emit(loaded.copyWith(selectedSceneSetIds: updated));
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
  /// This does NOT create any entity in the project; it only lives in
  /// ConfigControl state and is shown on the wall controller.
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

    emit(
      loaded.copyWith(
        snapshotPages: updatedPages,
        selectedSnapshotPageId: newPage.id,
      ),
    );
  }

  /// Delete a snapshot page by ID.
  void deleteSnapshotPage(String pageId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final List<SnapshotPageModel> updatedPages = loaded.snapshotPages.where((SnapshotPageModel p) => p.id != pageId).toList();

    emit(
      loaded.copyWith(
        snapshotPages: updatedPages,
        clearSelectedSnapshotPageId: loaded.selectedSnapshotPageId == pageId,
      ),
    );
  }

  /// Select a snapshot page in the SNAPSHOT PAGE list.
  void selectSnapshotPage(String pageId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(selectedSnapshotPageId: pageId));
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
}

// ─── Private value object ──────────────────────────────────────────────────────

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
