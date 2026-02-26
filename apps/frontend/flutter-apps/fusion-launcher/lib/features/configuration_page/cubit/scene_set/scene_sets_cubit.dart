import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/scene_set/scene_sets_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Cubit for managing Scene Sets feature state and business logic
class SceneSetsCubit extends Cubit<SceneSetsState> {
  final ProjectViewModel _projectViewModel;

  SceneSetsCubit({
    required ProjectViewModel projectViewModel,
  }) : _projectViewModel = projectViewModel,
       super(const SceneSetsInitial()) {
    _loadSceneSets();
  }

  /// Load scene sets from ProjectViewModel
  void _loadSceneSets() {
    emit(const SceneSetsLoading());

    try {
      final List<SceneSetModel> sceneSets = _projectViewModel.getAllSceneSets();
      emit(
        SceneSetsLoaded(
          sceneSets: sceneSets,
        ),
      );
    } catch (e) {
      emit(SceneSetsError(message: e.toString()));
    }
  }

  /// Sync state with ProjectViewModel
  void syncWithProjectViewModel() {
    final SceneSetsState currentState = state;

    try {
      final List<SceneSetModel> sceneSets = _projectViewModel.getAllSceneSets();

      if (currentState is SceneSetsLoaded) {
        emit(currentState.copyWith(sceneSets: sceneSets));
      } else {
        emit(SceneSetsLoaded(sceneSets: sceneSets));
      }
    } catch (e) {
      emit(SceneSetsError(message: e.toString()));
    }
  }

  /// Refresh data from ProjectViewModel
  void refresh() => syncWithProjectViewModel();

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
  void reorderSnapshotsInSceneSet({
    required String sceneSetId,
    required int oldIndex,
    required int newIndex,
    String? draggingSnapshotId,
  }) {
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    _projectViewModel.reOrderSnapshotInSceneSet(
      sceneSetId: sceneSetId,
      oldIndex: oldIndex,
      newIndex: adjustedNewIndex,
    );
    if (draggingSnapshotId != null) {
      _projectViewModel.setSelectedSnapshotId(draggingSnapshotId);
    }
    syncWithProjectViewModel();
  }

  /// Handle drop on a scene set
  void handleDropOnSceneSet({
    required String sceneSetId,
    required SnapshotsModel snapshot,
    required bool isDraggingFromScenes,
  }) {
    final List<SnapshotsModel> scenesInSet = getSnapshotsInSceneSet(sceneSetId);
    final bool alreadyInSet = scenesInSet.any((SnapshotsModel s) => s.id == snapshot.id);

    if (alreadyInSet) return;

    _projectViewModel.addNewSnapshotToSceneSet(sceneSetId: sceneSetId, scene: snapshot);
    _projectViewModel.setSelectedSnapshotId(snapshot.id);

    if (isDraggingFromScenes) {
      // Remove from all other scene sets
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
    syncWithProjectViewModel();
  }

  /// Check if a drop should be accepted on a scene set
  bool shouldAcceptDropOnSceneSet({
    required String sceneSetId,
    required String snapshotId,
    required bool isDraggingFromSnapshots,
    required bool isDraggingFromScenes,
  }) {
    if (isDraggingFromSnapshots) return true;
    if (isDraggingFromScenes) {
      final List<SnapshotsModel> scenesInSet = getSnapshotsInSceneSet(sceneSetId);
      return !scenesInSet.any((SnapshotsModel s) => s.id == snapshotId);
    }
    return false;
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
