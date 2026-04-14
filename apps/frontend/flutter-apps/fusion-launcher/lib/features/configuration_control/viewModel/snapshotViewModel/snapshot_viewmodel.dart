import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'snapshot_state.dart';

/// ViewModel/Cubit for the Snapshots/Scenes tab panel.
///
/// Manages scene set selections, snapshot pages, and active snapshot state.
/// Loads and persists data using [ProjectViewModel] relationships.
class SnapshotViewModel extends Cubit<SnapshotState> {
  SnapshotViewModel() : super(const SnapshotInitial());

  /// Lazy reference to ProjectViewModel.
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  /// Get current loaded state, or null if not loaded.
  SnapshotLoaded? get _loaded {
    final SnapshotState s = state;
    return s is SnapshotLoaded ? s : null;
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  /// Loads snapshot/scene data for the specified controller.
  void loadData(String controllerId) {
    emit(const SnapshotLoading());

    try {
      // Load scene sets and snapshots
      final List<SceneSetModel> sceneSets = _projectViewModel.getAllSceneSets();
      final Map<String, List<SnapshotsModel>> snapshotsInSceneSets = <String, List<SnapshotsModel>>{
        for (final SceneSetModel s in sceneSets) s.id: _projectViewModel.getSnapshotInSceneSet(sceneSetId: s.id),
      };
      final List<SnapshotsModel> allSnapshots = _projectViewModel.getAllSnapshots();

      // Compute snapshots per page and used IDs
      final Map<String, List<SnapshotsModel>> snapshotsPerPage = _computeSnapshotsPerPage(snapshotsInSceneSets);
      final Set<String> usedSnapshotIds = _computeUsedSnapshotIds(snapshotsPerPage);

      // Load persisted pages from relationships
      final List<ControllerPageModel> controllerPages = _projectViewModel.getControllerPages(controllerId);
      final Set<String> validSceneSetIds = sceneSets.map((SceneSetModel s) => s.id).toSet();

      final Set<String> selectedSceneSetIds = <String>{};
      final List<SnapshotPageModel> snapshotPages = <SnapshotPageModel>[];

      for (final ControllerPageModel page in controllerPages) {
        if (page.type == ControllerPageType.sceneSet && validSceneSetIds.contains(page.id)) {
          selectedSceneSetIds.add(page.id);
        } else if (page.type == ControllerPageType.snapshotPage) {
          final List<String> snapshotIds = _projectViewModel.getSnapshotIdsForPage(page.id).toList();
          snapshotPages.add(SnapshotPageModel(id: page.id, name: page.name, snapshotIds: snapshotIds));
        }
      }

      final String? selectedSceneSetId = sceneSets.isNotEmpty ? sceneSets.first.id : null;

      emit(
        SnapshotLoaded(
          sceneSets: sceneSets,
          snapshotsInSceneSets: snapshotsInSceneSets,
          allSnapshots: allSnapshots,
          snapshotsPerPage: snapshotsPerPage,
          usedSnapshotIds: usedSnapshotIds,
          selectedSceneSetIds: selectedSceneSetIds,
          selectedSceneSetId: selectedSceneSetId,
          snapshotPages: snapshotPages,
          controllerId: controllerId,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'SnapshotViewModel: failed to load data: $e');
      emit(SnapshotError(message: 'Failed to load snapshot data: $e'));
    }
  }

  /// Reloads data from persistence.
  void refresh() {
    final SnapshotLoaded? loaded = _loaded;
    if (loaded?.controllerId != null) {
      loadData(loaded!.controllerId!);
    }
  }

  // ─── Scene Set Actions ─────────────────────────────────────────────────────

  /// Toggle checkbox in the SCENES panel.
  void toggleSceneSetSelection(String sceneSetId) {
    final SnapshotLoaded? loaded = _loaded;
    if (loaded == null) return;

    final bool wasChecked = loaded.selectedSceneSetIds.contains(sceneSetId);
    final Set<String> updated = Set<String>.from(loaded.selectedSceneSetIds);

    if (wasChecked) {
      updated.remove(sceneSetId);
    } else {
      updated.add(sceneSetId);
    }

    // Persist
    if (loaded.controllerId != null) {
      _persistControllerPages(
        controllerId: loaded.controllerId!,
        selectedSceneSetIds: updated,
        snapshotPages: loaded.snapshotPages,
      );
    }

    if (!wasChecked) {
      // Checked ON → activate this scene set in PAGES
      emit(
        loaded.copyWith(
          selectedSceneSetIds: updated,
          selectedSceneSetId: sceneSetId,
          selectedSnapshotPageId: null,
        ),
      );
    } else {
      // Checked OFF → clear if it was active
      final bool wasActive = loaded.selectedSceneSetId == sceneSetId;
      emit(
        loaded.copyWith(
          selectedSceneSetIds: updated,
          selectedSceneSetId: wasActive ? null : loaded.selectedSceneSetId,
        ),
      );
    }
  }

  /// Select the active scene set in PAGES panel.
  void selectSceneSet(String sceneSetId) {
    final SnapshotLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(
      loaded.copyWith(
        selectedSceneSetId: sceneSetId,
        activeSnapshotId: null,
        selectedSnapshotPageId: null,
      ),
    );
  }

  // ─── Snapshot Actions ──────────────────────────────────────────────────────

  /// Set the active/recalled snapshot (radio button in VC).
  void setActiveSnapshot(String snapshotId) {
    final SnapshotLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(activeSnapshotId: snapshotId));
  }

  // ─── Snapshot Page Actions ─────────────────────────────────────────────────

  /// Create a new snapshot page.
  void createSnapshotPage({
    required String name,
    required List<String> selectedSnapshotIds,
  }) {
    final SnapshotLoaded? loaded = _loaded;
    if (loaded == null) return;

    final String pageName = name.trim().isEmpty ? 'Untitled_Snapshot' : name.trim();
    final SnapshotPageModel newPage = SnapshotPageModel(
      name: pageName,
      snapshotIds: selectedSnapshotIds,
    );

    final List<SnapshotPageModel> updatedPages = <SnapshotPageModel>[...loaded.snapshotPages, newPage];

    // Persist
    if (loaded.controllerId != null) {
      _persistControllerPages(
        controllerId: loaded.controllerId!,
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
  void deleteSnapshotPage(String pageId) {
    final SnapshotLoaded? loaded = _loaded;
    if (loaded == null) return;

    final List<SnapshotPageModel> updatedPages = loaded.snapshotPages.where((SnapshotPageModel p) => p.id != pageId).toList();

    // Persist
    if (loaded.controllerId != null) {
      _persistControllerPages(
        controllerId: loaded.controllerId!,
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
  void selectSnapshotPage(String pageId) {
    final SnapshotLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(selectedSnapshotPageId: pageId, selectedSceneSetId: null));
  }

  // ─── Computed Helpers ──────────────────────────────────────────────────────

  /// Compute snapshots linked to each snapshot page via recall actions.
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

  /// Collect all snapshot IDs linked to any snapshot page.
  Set<String> _computeUsedSnapshotIds(Map<String, List<SnapshotsModel>> snapshotsPerPage) {
    final Set<String> usedIds = <String>{};
    for (final List<SnapshotsModel> linked in snapshotsPerPage.values) {
      for (final SnapshotsModel snap in linked) {
        usedIds.add(snap.id);
      }
    }
    return usedIds;
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

  /// Persists scene-set and snapshot pages.
  void _persistControllerPages({
    required String controllerId,
    required Set<String> selectedSceneSetIds,
    required List<SnapshotPageModel> snapshotPages,
  }) {
    final List<SceneSetModel> allSceneSets = _loaded?.sceneSets ?? <SceneSetModel>[];

    // Build scene-set and snapshot pages
    final List<ControllerPageModel> newPages = <ControllerPageModel>[
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
}
