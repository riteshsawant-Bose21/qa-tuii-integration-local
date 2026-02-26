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
    emit(
      state.copyWith(
        snapshots: _projectViewModel.getAllSnapshots(),
        selectedSnapshotId: _projectViewModel.selectedSnapshotId,
      ),
    );
  }

  /// Refresh data from ProjectViewModel
  void refresh() => syncWithProjectViewModel();

  /// Set the selected snapshot ID
  void selectSnapshot(String? snapshotId) {
    _projectViewModel.setSelectedSnapshotId(snapshotId);
    emit(
      state.copyWith(
        selectedSnapshotId: snapshotId,
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
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final List<SnapshotsModel> snapshots = state.snapshots;
    if (oldIndex >= 0 && oldIndex < snapshots.length && adjustedNewIndex >= 0 && adjustedNewIndex < snapshots.length) {
      final String snapshotToMove = snapshots[oldIndex].id;
      final String snapshotAtNewIndex = snapshots[adjustedNewIndex].id;
      _projectViewModel.reOderSnapshots(
        sceneIdToMove: snapshotToMove,
        sceneIdAtNewIndex: snapshotAtNewIndex,
      );
      _projectViewModel.setSelectedSnapshotId(snapshotToMove);
      syncWithProjectViewModel();
    }
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

  /// ==================== Drag and Drop Operations ====================

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

    // Remove from all scene sets
    final List<SceneSetModel> allSceneSets = _projectViewModel.getAllSceneSets();
    for (final SceneSetModel sceneSet in allSceneSets) {
      final List<SnapshotsModel> scenesInSet = _projectViewModel.getSnapshotInSceneSet(sceneSetId: sceneSet.id);
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

  /// Check if a drop should be accepted on snapshots section
  bool shouldAcceptDropOnSnapshots() => state.draggingFromSection == DragSection.scenes;

  /// ==================== UI State Management ====================

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

  @override
  Future<void> close() {
    _projectViewModel.setSelectedSnapshotId(null);
    return super.close();
  }
}
