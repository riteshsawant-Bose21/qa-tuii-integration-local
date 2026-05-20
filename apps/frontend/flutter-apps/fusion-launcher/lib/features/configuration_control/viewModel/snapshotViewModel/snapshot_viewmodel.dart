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
      // Load persisted pages from relationships
      final List<ControllerPageModel> controllerPages = _projectViewModel.getControllerPages(controllerId);
      final Set<String> validSceneSetIds = sceneSets.map((SceneSetModel s) => s.id).toSet();

      final Set<String> selectedSceneSetIds = <String>{};
      final List<SnapshotPageModel> snapshotPages = <SnapshotPageModel>[];
      final List<ControllerPageModel> orderedPageEntries = <ControllerPageModel>[];

      for (final ControllerPageModel page in controllerPages) {
        if (page.type == ControllerPageType.sceneSet && validSceneSetIds.contains(page.id)) {
          selectedSceneSetIds.add(page.id);
          orderedPageEntries.add(page);
        } else if (page.type == ControllerPageType.snapshotPage) {
          final List<String> snapshotIds = _projectViewModel.getSnapshotIdsForPage(page.id).toList();
          snapshotPages.add(SnapshotPageModel(id: page.id, name: page.name, snapshotIds: snapshotIds));
          orderedPageEntries.add(page);
        }
      }

      final String? selectedSceneSetId = sceneSets.isNotEmpty ? sceneSets.first.id : null;

      // Compute used IDs including user-created snapshot pages
      final Set<String> finalUsedIds = _computeUsedSnapshotIdsFromPages(snapshotPages, snapshotsPerPage);

      emit(
        SnapshotLoaded(
          sceneSets: sceneSets,
          snapshotsInSceneSets: snapshotsInSceneSets,
          allSnapshots: allSnapshots,
          snapshotsPerPage: snapshotsPerPage,
          usedSnapshotIds: finalUsedIds,
          selectedSceneSetIds: selectedSceneSetIds,
          selectedSceneSetId: selectedSceneSetId,
          snapshotPages: snapshotPages,
          orderedPageEntries: orderedPageEntries,
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

    // Update ordered page entries
    final List<ControllerPageModel> updatedOrder = List<ControllerPageModel>.from(loaded.orderedPageEntries);
    if (wasChecked) {
      updatedOrder.removeWhere((ControllerPageModel p) => p.id == sceneSetId);
    } else {
      final String sceneSetName =
          loaded.sceneSets.firstWhere((SceneSetModel s) => s.id == sceneSetId, orElse: () => SceneSetModel(id: sceneSetId, name: sceneSetId)).name;
      updatedOrder.add(ControllerPageModel(id: sceneSetId, type: ControllerPageType.sceneSet, name: sceneSetName));
    }

    // Persist
    if (loaded.controllerId != null) {
      _persistControllerPages(
        controllerId: loaded.controllerId!,
        orderedPageEntries: updatedOrder,
      );
    }

    if (!wasChecked) {
      // Checked ON → activate this scene set in PAGES
      emit(
        loaded.copyWith(
          selectedSceneSetIds: updated,
          orderedPageEntries: updatedOrder,
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
          orderedPageEntries: updatedOrder,
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
    final List<ControllerPageModel> updatedOrder = <ControllerPageModel>[
      ...loaded.orderedPageEntries,
      ControllerPageModel(id: newPage.id, type: ControllerPageType.snapshotPage, name: pageName),
    ];

    // Persist
    if (loaded.controllerId != null) {
      _persistControllerPages(
        controllerId: loaded.controllerId!,
        orderedPageEntries: updatedOrder,
        snapshotPagesOverride: updatedPages,
      );
    }

    // Recompute used snapshot IDs including new page
    final Set<String> updatedUsedIds = _computeUsedSnapshotIdsFromPages(updatedPages, loaded.snapshotsPerPage);

    emit(
      loaded.copyWith(
        snapshotPages: updatedPages,
        usedSnapshotIds: updatedUsedIds,
        orderedPageEntries: updatedOrder,
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
    final List<ControllerPageModel> updatedOrder = loaded.orderedPageEntries.where((ControllerPageModel p) => p.id != pageId).toList();

    // Persist
    if (loaded.controllerId != null) {
      _persistControllerPages(
        controllerId: loaded.controllerId!,
        orderedPageEntries: updatedOrder,
        snapshotPagesOverride: updatedPages,
      );
    }

    // Recompute used snapshot IDs after deletion
    final Set<String> updatedUsedIds = _computeUsedSnapshotIdsFromPages(updatedPages, loaded.snapshotsPerPage);

    emit(
      loaded.copyWith(
        snapshotPages: updatedPages,
        usedSnapshotIds: updatedUsedIds,
        orderedPageEntries: updatedOrder,
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

  /// Reorder pages in the PAGES panel.
  void reorderPages(int oldIndex, int newIndex) {
    final SnapshotLoaded? loaded = _loaded;
    if (loaded == null) return;

    final List<ControllerPageModel> updatedOrder = List<ControllerPageModel>.from(loaded.orderedPageEntries);
    if (newIndex > oldIndex) newIndex--;
    final ControllerPageModel item = updatedOrder.removeAt(oldIndex);
    updatedOrder.insert(newIndex, item);

    if (loaded.controllerId != null) {
      _persistControllerPages(
        controllerId: loaded.controllerId!,
        orderedPageEntries: updatedOrder,
      );
    }

    // Select the moved item
    if (item.type == ControllerPageType.sceneSet) {
      emit(loaded.copyWith(orderedPageEntries: updatedOrder, selectedSceneSetId: item.id, selectedSnapshotPageId: null));
    } else {
      emit(loaded.copyWith(orderedPageEntries: updatedOrder, selectedSnapshotPageId: item.id, selectedSceneSetId: null));
    }
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

  /// Compute used snapshot IDs from both scene-set pages and user-created snapshot pages.
  Set<String> _computeUsedSnapshotIdsFromPages(
    List<SnapshotPageModel> snapshotPages,
    Map<String, List<SnapshotsModel>> snapshotsPerPage,
  ) {
    final Set<String> usedIds = _computeUsedSnapshotIds(snapshotsPerPage);
    for (final SnapshotPageModel page in snapshotPages) {
      usedIds.addAll(page.snapshotIds);
    }
    return usedIds;
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

  /// Persists scene-set and snapshot pages in order.
  void _persistControllerPages({
    required String controllerId,
    required List<ControllerPageModel> orderedPageEntries,
    List<SnapshotPageModel>? snapshotPagesOverride,
  }) {
    // Preserve existing message pages
    final List<ControllerPageModel> existingMessagePages =
        _projectViewModel.getControllerPages(controllerId).where((ControllerPageModel p) => p.type == ControllerPageType.message).toList();

    _projectViewModel.setControllerPages(
      controllerId: controllerId,
      pages: <ControllerPageModel>[...orderedPageEntries, ...existingMessagePages],
    );

    // Update snapshot ID relationships for each snapshot page
    final List<SnapshotPageModel> snapshotPages = snapshotPagesOverride ?? _loaded?.snapshotPages ?? <SnapshotPageModel>[];
    for (final SnapshotPageModel p in snapshotPages) {
      _projectViewModel.setSnapshotIdsForPage(pageId: p.id, snapshotIds: p.snapshotIds.toSet());
    }
  }
}
