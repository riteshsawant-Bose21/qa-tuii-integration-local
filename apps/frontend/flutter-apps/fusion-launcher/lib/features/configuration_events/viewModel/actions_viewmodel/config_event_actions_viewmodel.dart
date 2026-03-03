import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'config_event_actions_state.dart';

/// Cubit for managing Event Actions feature state and business logic
class ConfigEventActionsViewmodel extends Cubit<ConfigEventActionsState> {
  final ProjectViewModel _projectViewModel;

  ConfigEventActionsViewmodel({required ProjectViewModel projectViewModel}) : _projectViewModel = projectViewModel, super(const EventActionsInitial());

  /// Load actions for a specific event
  void loadActionsForEvent(String? eventId) {
    if (eventId == null) {
      emit(const EventActionsInitial());
      return;
    }
    emit(EventActionsLoading(selectedEventId: eventId));
    try {
      final List<SceneActionModel> actions = _projectViewModel.getEventActionsForEvent(eventId);
      emit(EventActionsLoaded(actions: actions, selectedEventId: eventId));
    } catch (e) {
      emit(EventActionsError(message: e.toString(), selectedEventId: eventId));
    }
  }

  /// Sync state with ProjectViewModel
  void syncWithProjectViewModel() {
    final ConfigEventActionsState currentState = state;
    if (currentState.selectedEventId == null) return;
    try {
      final List<SceneActionModel> actions = _projectViewModel.getEventActionsForEvent(currentState.selectedEventId!);
      emit(EventActionsLoaded(actions: actions, selectedEventId: currentState.selectedEventId));
    } catch (e) {
      emit(EventActionsError(message: e.toString(), selectedEventId: currentState.selectedEventId));
    }
  }

  void refresh() => syncWithProjectViewModel();

  List<SceneActionModel> getActionsForSelectedEvent() => state.actions;

  SceneActionModel? getActionById(String actionId) => state.getActionById(actionId);

  void addAction() {
    final ConfigEventActionsState currentState = state;
    if (currentState.selectedEventId == null) return;
    final SceneActionModel action = SceneActionModel();
    _projectViewModel.addActionToEvent(eventId: currentState.selectedEventId!, action: action);
    syncWithProjectViewModel();
  }

  void deleteAction({required String actionId}) {
    final ConfigEventActionsState currentState = state;
    if (currentState.selectedEventId == null) return;
    _projectViewModel.removeActionFromEvent(actionId: actionId, eventId: currentState.selectedEventId!);
    syncWithProjectViewModel();
  }

  void duplicateAction({required String actionId}) {
    final ConfigEventActionsState currentState = state;
    if (currentState.selectedEventId == null) return;
    _projectViewModel.duplicateActionInEvent(eventId: currentState.selectedEventId!, actionId: actionId);
    syncWithProjectViewModel();
  }

  void reorderActions(int oldIndex, int newIndex) {
    // Event actions reordering is not currently supported in the project
    // This is a placeholder for future implementation
    syncWithProjectViewModel();
  }

  // ==================== Action Row Operations ====================

  void updateActionType({required String actionId, required SceneActionType actionType}) {
    _projectViewModel.updateSceneActionType(actionId: actionId, actionType: actionType);
    syncWithProjectViewModel();
  }

  void updateActionItem({required String actionId, required SceneItem item}) {
    _projectViewModel.updateSceneActionItem(actionId: actionId, item: item);
    syncWithProjectViewModel();
  }

  void updateActionParam({required String actionId, required SceneParam param, String? eventId}) {
    _projectViewModel.updateSceneActionParam(actionId: actionId, param: param, eventId: eventId);
    syncWithProjectViewModel();
  }

  void updateActionValue({required String actionId, required SceneValue value}) {
    _projectViewModel.updateSceneActionValue(actionId: actionId, value: value);
    syncWithProjectViewModel();
  }

  // ==================== Dropdown Data Getters ====================

  List<SceneActionType> getSceneActionTypes({bool isFromSnapshot = false, String? eventId}) {
    return _projectViewModel.getSceneActionTypes(isFromSnapshot: isFromSnapshot, eventId: eventId);
  }

  List<SceneItemDropdown> getActionItemsByType(SceneActionType actionType) {
    return _projectViewModel.getActionItemsByType(actionType);
  }

  List<SceneParam> getParamsByActionTypeAndItem({
    required SceneActionType actionType,
    required SceneItem item,
    String? eventId,
  }) {
    return _projectViewModel.getParamsByActionTypeAndItem(actionType: actionType, item: item, eventId: eventId);
  }

  List<SceneValueDropdown> getSceneValueDropdownItems(String actionId) {
    return _projectViewModel.getSceneValueDropdownItems(actionId);
  }

  // ==================== Event Data Accessors ====================

  /// Get event by ID - needed for checking event state in UI
  FusionEvent getEventById(String eventId) {
    return _projectViewModel.getEventById(eventId);
  }

  /// Update the selected state for an event (for 2-state events)
  void updateEventSelectedState({required String eventId, required EventStates selectedState}) {
    _projectViewModel.updateEventSelectedState(eventId: eventId, selectedState: selectedState);
    syncWithProjectViewModel();
  }

  @override
  Future<void> close() => super.close();
}
