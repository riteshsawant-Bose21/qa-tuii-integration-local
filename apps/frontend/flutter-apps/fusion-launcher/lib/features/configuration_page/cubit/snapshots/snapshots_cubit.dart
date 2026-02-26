import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'snapshots_state.dart';

/// Cubit for managing Snapshots feature state and business logic
class SnapshotsCubit extends Cubit<SnapshotsState> {
  final ProjectViewModel _projectViewModel;

  SnapshotsCubit({
    required ProjectViewModel projectViewModel,
  }) : _projectViewModel = projectViewModel,
       super(SnapshotsState.initial()) {
    syncWithProjectViewModel();
  }

  /// Sync state with ProjectViewModel
  void syncWithProjectViewModel() {
    final String? selectedId = _projectViewModel.selectedSnapshotId;
    final List<SceneActionModel> actions = selectedId != null ? _projectViewModel.getSceneActionsForSnapshot(selectedId) : <SceneActionModel>[];

    emit(
      state.copyWith(
        snapshots: _projectViewModel.getAllSnapshots(),
        sceneSets: _projectViewModel.getAllSceneSets(),
        selectedSnapshotId: selectedId,
        actions: actions,
      ),
    );
  }

  /// Refresh data from ProjectViewModel
  void refresh() => syncWithProjectViewModel();

  /// Set the selected snapshot ID
  void selectSnapshot(String? snapshotId) {
    _projectViewModel.setSelectedSnapshotId(snapshotId);
    final List<SceneActionModel> actions = snapshotId != null ? _projectViewModel.getSceneActionsForSnapshot(snapshotId) : <SceneActionModel>[];

    emit(
      state.copyWith(
        selectedSnapshotId: snapshotId,
        actions: actions,
        clearSelectedSnapshotId: snapshotId == null,
      ),
    );
  }

  /// Clear the selected snapshot
  void clearSelection() => selectSnapshot(null);

  /// Add a new snapshot
  void addSnapshot() {
    final SnapshotsModel newSnapshot = SnapshotsModel(
      name: "New Snapshot ${state.snapshots.length + 1}",
    );
    _projectViewModel.addNewSnapshots(scene: newSnapshot);
    _projectViewModel.setSelectedSnapshotId(newSnapshot.id);

    final SceneActionModel action = SceneActionModel();
    _projectViewModel.addSceneActionToSnapshot(sceneId: newSnapshot.id, action: action);
    syncWithProjectViewModel();
  }

  /// Delete a snapshot
  void deleteSnapshot(String snapshotId) {
    _projectViewModel.removeSnapshots(sceneId: snapshotId);
    if (state.selectedSnapshotId == snapshotId) {
      _projectViewModel.setSelectedSnapshotId(null);
    }
    syncWithProjectViewModel();
  }

  /// Duplicate a snapshot
  void duplicateSnapshot(String snapshotId) {
    _projectViewModel.duplicateSnapshot(sceneId: snapshotId);
    syncWithProjectViewModel();
  }

  /// Update/rename a snapshot
  void updateSnapshot(SnapshotsModel snapshot) {
    _projectViewModel.updateSnapshots(scene: snapshot);
    syncWithProjectViewModel();
  }

  /// Reorder snapshots in the list
  void reorderSnapshots(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final List<SnapshotsModel> snapshots = state.snapshots;
    if (oldIndex >= 0 && oldIndex < snapshots.length && newIndex >= 0 && newIndex < snapshots.length) {
      final String snapshotToMove = snapshots[oldIndex].id;
      final String snapshotAtNewIndex = snapshots[newIndex].id;
      _projectViewModel.reOderSnapshots(
        sceneIdToMove: snapshotToMove,
        sceneIdAtNewIndex: snapshotAtNewIndex,
      );
      _projectViewModel.setSelectedSnapshotId(snapshotToMove);
      syncWithProjectViewModel();
    }
  }

  /// Add a new scene set
  void addSceneSet() {
    final SceneSetModel newSceneSet = SceneSetModel(
      name: "New Scene Set ${state.sceneSets.length + 1}",
    );
    _projectViewModel.addNewSceneSet(sceneSet: newSceneSet);
    syncWithProjectViewModel();
  }

  /// Delete a scene set
  void deleteSceneSet(String sceneSetId) {
    _projectViewModel.removeSceneSet(sceneSetId: sceneSetId);
    _projectViewModel.setSelectedSnapshotId(null);
    syncWithProjectViewModel();
  }

  /// Duplicate a scene set
  void duplicateSceneSet(String sceneSetId) {
    _projectViewModel.duplicateSceneSet(sceneSetId: sceneSetId);
    syncWithProjectViewModel();
  }

  /// Update/rename a scene set
  void updateSceneSet(SceneSetModel sceneSet) {
    _projectViewModel.updateSceneSet(sceneSet: sceneSet);
    syncWithProjectViewModel();
  }

  /// Get snapshots for a scene set
  List<SnapshotsModel> getSnapshotsInSceneSet(String sceneSetId) {
    return _projectViewModel.getSnapshotInSceneSet(sceneSetId: sceneSetId);
  }

  /// Add new snapshot to a scene set
  void addSnapshotToSceneSet(String sceneSetId) {
    final List<SnapshotsModel> existingSnapshots = getSnapshotsInSceneSet(sceneSetId);
    final SnapshotsModel newSnapshot = SnapshotsModel(
      name: "New Snapshot ${existingSnapshots.length + 1}",
    );
    _projectViewModel.addNewSnapshotToSceneSet(sceneSetId: sceneSetId, scene: newSnapshot);
    final SceneActionModel action = SceneActionModel();
    _projectViewModel.addSceneActionToSnapshot(sceneId: newSnapshot.id, action: action);
    _projectViewModel.setSelectedSnapshotId(newSnapshot.id);
    syncWithProjectViewModel();
  }

  /// Reorder snapshots within a scene set
  void reorderSnapshotsInSceneSet(String sceneSetId, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    _projectViewModel.reOrderSnapshotInSceneSet(
      sceneSetId: sceneSetId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (state.draggingSnapshotId != null) {
      _projectViewModel.setSelectedSnapshotId(state.draggingSnapshotId);
    }
    syncWithProjectViewModel();
  }

  /// Start dragging a snapshot
  void startDrag(String snapshotId, DragSection fromSection) {
    emit(
      state.copyWith(
        draggingSnapshotId: snapshotId,
        draggingFromSection: fromSection,
      ),
    );
  }

  /// End dragging
  void endDrag() {
    emit(
      state.copyWith(
        clearDraggingSnapshotId: true,
        clearDraggingFromSection: true,
      ),
    );
  }

  /// Handle drop on snapshots section
  void handleDropOnSnapshots(SnapshotsModel snapshot) {
    if (state.draggingFromSection != DragSection.scenes) return;
    final bool alreadyInList = state.snapshots.any((SnapshotsModel s) => s.id == snapshot.id);
    if (!alreadyInList) {
      _projectViewModel.addNewSnapshots(scene: snapshot);
    }
    _projectViewModel.setSelectedSnapshotId(snapshot.id);
    for (final SceneSetModel sceneSet in state.sceneSets) {
      final List<SnapshotsModel> scenesInSet = getSnapshotsInSceneSet(sceneSet.id);
      if (scenesInSet.any((SnapshotsModel s) => s.id == snapshot.id)) {
        _projectViewModel.removeSnapshotFromSceneSet(
          sceneSetId: sceneSet.id,
          sceneId: snapshot.id,
        );
      }
    }
    endDrag();
    syncWithProjectViewModel();
  }

  /// Handle drop on a scene set
  void handleDropOnSceneSet(String sceneSetId, SnapshotsModel snapshot) {
    final List<SnapshotsModel> scenesInSet = getSnapshotsInSceneSet(sceneSetId);
    final bool alreadyInSet = scenesInSet.any((SnapshotsModel s) => s.id == snapshot.id);
    if (alreadyInSet) {
      endDrag();
      return;
    }
    _projectViewModel.addNewSnapshotToSceneSet(sceneSetId: sceneSetId, scene: snapshot);
    _projectViewModel.setSelectedSnapshotId(snapshot.id);
    if (state.draggingFromSection == DragSection.scenes) {
      for (final SceneSetModel sceneSet in state.sceneSets) {
        if (sceneSet.id != sceneSetId) {
          final List<SnapshotsModel> scenesInOtherSet = getSnapshotsInSceneSet(sceneSet.id);
          if (scenesInOtherSet.any((SnapshotsModel s) => s.id == snapshot.id)) {
            _projectViewModel.removeSnapshotFromSceneSet(
              sceneSetId: sceneSet.id,
              sceneId: snapshot.id,
            );
          }
        }
      }
    }
    endDrag();
    syncWithProjectViewModel();
  }

  /// Check if a drop should be accepted on snapshots section
  bool shouldAcceptDropOnSnapshots() => state.draggingFromSection == DragSection.scenes;

  /// Check if a drop should be accepted on a scene set
  bool shouldAcceptDropOnSceneSet(String sceneSetId, String snapshotId) {
    if (state.draggingFromSection == DragSection.snapshots) return true;
    if (state.draggingFromSection == DragSection.scenes) {
      final List<SnapshotsModel> scenesInSet = getSnapshotsInSceneSet(sceneSetId);
      return !scenesInSet.any((SnapshotsModel s) => s.id == snapshotId);
    }
    return false;
  }

  /// Update the height of the sources panel
  void updateSourcesHeight(double delta, double screenHeight) {
    final double minHeight = screenHeight * 0.15;
    final double maxHeight = screenHeight * 0.5;
    final double newHeight = (state.sourcesHeight + delta).clamp(minHeight, maxHeight);
    emit(state.copyWith(sourcesHeight: newHeight));
  }

  /// Initialize sources height based on screen size
  void initializeSourcesHeight(double screenHeight) {
    final double totalHeight = screenHeight;
    final double initialHeight = (totalHeight - 100) * 0.4;
    emit(state.copyWith(sourcesHeight: initialHeight));
  }

  /// Get actions for the selected snapshot (from state)
  List<SceneActionModel> getActionsForSelectedSnapshot() {
    return state.actions;
  }

  /// Get a specific action by ID from state
  SceneActionModel? getActionById(String actionId) {
    return state.getActionById(actionId);
  }

  /// Get the selected snapshot model
  SnapshotsModel? getSelectedSnapshotModel() {
    if (state.selectedSnapshotId == null) return null;
    return _projectViewModel.getSnapshotById(sceneId: state.selectedSnapshotId!);
  }

  /// Get the scene set for the selected snapshot
  SceneSetModel? getSceneSetForSelectedSnapshot() {
    if (state.selectedSnapshotId == null) return null;
    return _projectViewModel.getSceneSetForSnapshot(snapshotId: state.selectedSnapshotId!);
  }

  /// Add action to selected snapshot
  void addActionToSelectedSnapshot() {
    if (state.selectedSnapshotId == null) return;
    final SceneActionModel action = SceneActionModel();
    _projectViewModel.addSceneActionToSnapshot(
      sceneId: state.selectedSnapshotId!,
      action: action,
    );
    syncWithProjectViewModel();
  }

  /// Reorder actions in the selected snapshot
  void reorderActionsInSelectedSnapshot(int oldIndex, int newIndex) {
    if (state.selectedSnapshotId == null) return;
    if (newIndex > oldIndex) newIndex -= 1;
    _projectViewModel.reOderSceneActionsInSnapshot(
      sceneId: state.selectedSnapshotId!,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    syncWithProjectViewModel();
  }

  // ==================== Action Row Operations ====================

  /// Update action type for a specific action
  void updateActionType({required String actionId, required SceneActionType actionType}) {
    _projectViewModel.updateSceneActionType(actionId: actionId, actionType: actionType);
    syncWithProjectViewModel();
  }

  /// Update action item for a specific action
  void updateActionItem({required String actionId, required SceneItem item}) {
    _projectViewModel.updateSceneActionItem(actionId: actionId, item: item);
    syncWithProjectViewModel();
  }

  /// Update action param for a specific action
  void updateActionParam({required String actionId, required SceneParam param}) {
    _projectViewModel.updateSceneActionParam(actionId: actionId, param: param);
    syncWithProjectViewModel();
  }

  /// Update action value for a specific action
  void updateActionValue({required String actionId, required SceneValue value}) {
    _projectViewModel.updateSceneActionValue(actionId: actionId, value: value);
    syncWithProjectViewModel();
  }

  /// Delete a specific action
  void deleteAction({required String actionId}) {
    _projectViewModel.removeSceneAction(actionId: actionId);
    syncWithProjectViewModel();
  }

  /// Duplicate a specific action
  void duplicateAction({required String actionId}) {
    _projectViewModel.duplicateSceneAction(actionId: actionId);
    syncWithProjectViewModel();
  }

  // ==================== Dropdown Data Getters ====================

  /// Get scene action types for dropdown
  List<SceneActionType> getSceneActionTypes({bool isFromSnapshot = true}) {
    return _projectViewModel.getSceneActionTypes(isFromSnapshot: isFromSnapshot);
  }

  /// Get action items by type for dropdown
  List<SceneItemDropdown> getActionItemsByType(SceneActionType actionType) {
    return _projectViewModel.getActionItemsByType(actionType);
  }

  /// Get params by action type and item for dropdown
  List<SceneParam> getParamsByActionTypeAndItem({
    required SceneActionType actionType,
    required SceneItem item,
  }) {
    return _projectViewModel.getParamsByActionTypeAndItem(actionType: actionType, item: item);
  }

  /// Get scene value dropdown items
  List<SceneValueDropdown> getSceneValueDropdownItems(String actionId) {
    return _projectViewModel.getSceneValueDropdownItems(actionId);
  }

  @override
  Future<void> close() {
    _projectViewModel.setSelectedSnapshotId(null);
    return super.close();
  }
}
