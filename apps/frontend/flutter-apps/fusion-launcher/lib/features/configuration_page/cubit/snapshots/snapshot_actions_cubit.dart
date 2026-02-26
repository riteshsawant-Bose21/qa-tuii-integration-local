import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'snapshot_actions_state.dart';

/// Cubit for managing Snapshot Actions feature state and business logic
class SnapshotActionsCubit extends Cubit<SnapshotActionsState> {
  final ProjectViewModel _projectViewModel;

  SnapshotActionsCubit({
    required ProjectViewModel projectViewModel,
  }) : _projectViewModel = projectViewModel,
       super(SnapshotActionsState.initial());

  /// Load actions for a specific snapshot
  void loadActionsForSnapshot(String? snapshotId) {
    if (snapshotId == null) {
      emit(
        state.copyWith(
          actions: <SceneActionModel>[],
          clearSelectedSnapshotId: true,
        ),
      );
      return;
    }

    final List<SceneActionModel> actions = _projectViewModel.getSceneActionsForSnapshot(snapshotId);
    emit(
      state.copyWith(
        actions: actions,
        selectedSnapshotId: snapshotId,
      ),
    );
  }

  /// Sync state with ProjectViewModel (refresh current actions)
  void syncWithProjectViewModel() {
    if (state.selectedSnapshotId == null) return;

    final List<SceneActionModel> actions = _projectViewModel.getSceneActionsForSnapshot(state.selectedSnapshotId!);
    emit(state.copyWith(actions: actions));
  }

  /// Refresh data from ProjectViewModel
  void refresh() => syncWithProjectViewModel();

  /// Get actions for the selected snapshot (from state)
  List<SceneActionModel> getActionsForSelectedSnapshot() {
    return state.actions;
  }

  /// Get a specific action by ID from state
  SceneActionModel? getActionById(String actionId) {
    return state.getActionById(actionId);
  }

  /// Add action to selected snapshot
  void addAction() {
    if (state.selectedSnapshotId == null) return;

    final SceneActionModel action = SceneActionModel();
    _projectViewModel.addSceneActionToSnapshot(
      sceneId: state.selectedSnapshotId!,
      action: action,
    );
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

  /// Reorder actions in the selected snapshot
  void reorderActions(int oldIndex, int newIndex) {
    if (state.selectedSnapshotId == null) return;

    int adjustedNewIndex = newIndex;
    if (newIndex > oldIndex) adjustedNewIndex -= 1;

    _projectViewModel.reOderSceneActionsInSnapshot(
      sceneId: state.selectedSnapshotId!,
      oldIndex: oldIndex,
      newIndex: adjustedNewIndex,
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
    return super.close();
  }
}
