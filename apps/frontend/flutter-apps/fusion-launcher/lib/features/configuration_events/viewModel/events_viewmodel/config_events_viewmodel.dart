import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/events_viewmodel/config_events_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Cubit for managing Events feature state and business logic
class ConfigEventsViewmodel extends Cubit<ConfigEventsState> {
  final ProjectViewModel _projectViewModel;

  ConfigEventsViewmodel({
    required ProjectViewModel projectViewModel,
  }) : _projectViewModel = projectViewModel,
       super(const EventsInitial()) {
    _loadEvents();
  }

  void _loadEvents() {
    emit(const EventsLoading());
    try {
      final List<FusionEvent> events = _projectViewModel.getAllEvents();
      emit(EventsLoaded(events: events, selectedEventId: _projectViewModel.selectedEventId));
    } catch (e) {
      emit(EventsError(message: e.toString()));
    }
  }

  void syncWithProjectViewModel() {
    final ConfigEventsState currentState = state;
    try {
      final List<FusionEvent> events = _projectViewModel.getAllEvents();
      if (currentState is EventsLoaded) {
        emit(currentState.copyWith(events: events, selectedEventId: _projectViewModel.selectedEventId));
      } else {
        emit(EventsLoaded(events: events, selectedEventId: _projectViewModel.selectedEventId));
      }
    } catch (e) {
      emit(EventsError(message: e.toString()));
    }
  }

  void refresh() => syncWithProjectViewModel();

  void selectEvent(String? eventId) {
    _projectViewModel.setSelectedEventId(eventId);
    final ConfigEventsState currentState = state;
    if (currentState is EventsLoaded) {
      emit(currentState.copyWith(selectedEventId: eventId, clearSelectedEventId: eventId == null));
    }
  }

  void clearSelection() => selectEvent(null);

  void addEvent() {
    final FusionEvent newEvent = FusionEvent(name: "New Event ${state.events.length + 1}", isEnabled: true);
    _projectViewModel.addNewEvent(event: newEvent);
    _projectViewModel.setSelectedEventId(newEvent.id);
    syncWithProjectViewModel();
  }

  void deleteEvent(String eventId) {
    _projectViewModel.removeEvent(eventId: eventId);
    if (state.selectedEventId == eventId) {
      _projectViewModel.setSelectedEventId(null);
    }
    syncWithProjectViewModel();
  }

  void updateEvent(FusionEvent event) {
    _projectViewModel.updateEvent(event: event);
    syncWithProjectViewModel();
  }

  void toggleEventEnabled(String eventId) {
    final FusionEvent event = _projectViewModel.getEventById(eventId);
    final FusionEvent updatedEvent = event.copyWith(isEnabled: !event.isEnabled);
    _projectViewModel.updateEvent(event: updatedEvent);
    syncWithProjectViewModel();
  }

  void reorderEvents(int oldIndex, int newIndex) {
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;
    final List<FusionEvent> events = state.events;
    if (oldIndex >= 0 && oldIndex < events.length && adjustedNewIndex >= 0 && adjustedNewIndex < events.length) {
      final String eventToMove = events[oldIndex].id;
      final String eventAtNewIndex = events[adjustedNewIndex].id;
      _projectViewModel.reOrderEvents(eventIdToMove: eventToMove, eventAtNewIndex: eventAtNewIndex);
      _projectViewModel.setSelectedEventId(eventToMove);
      syncWithProjectViewModel();
    }
  }

  FusionEvent? getSelectedEventModel() {
    if (state.selectedEventId == null) return null;
    return _projectViewModel.getEventById(state.selectedEventId!);
  }

  FusionEvent getEventById(String eventId) => _projectViewModel.getEventById(eventId);

  List<EventTriggerType> getEventTriggers() => _projectViewModel.getEventTriggers();

  List<EventTriggerItemDropdown> getEventTriggerDropdownItems({required EventTriggerType triggerType}) {
    return _projectViewModel.getEventTriggerDropdownItems(triggerType: triggerType);
  }

  List<EventActionType> getEventActions({required String eventId}) => _projectViewModel.getEventActions(eventId: eventId);

  List<EventConditionType> getEventConditionTypes({required String eventId}) => _projectViewModel.getEventConditionTypes(eventId: eventId);

  void updateEventTrigger({required String eventId, required EventTriggerType newTrigger}) {
    _projectViewModel.updateEventTrigger(eventId: eventId, newTrigger: newTrigger);
    syncWithProjectViewModel();
  }

  void updateEventTriggerItem({required String eventId, required EventTriggerItem newItem}) {
    _projectViewModel.updateEventTriggerItem(eventId: eventId, newItem: newItem);
    syncWithProjectViewModel();
  }

  void updateEventAction({required String eventId, required EventActionType newAction}) {
    _projectViewModel.updateEventAction(eventId: eventId, newAction: newAction);
    syncWithProjectViewModel();
  }

  void updateEventConditionType({required String eventId, required EventConditionType newConditionType}) {
    _projectViewModel.updateEventConditionType(eventId: eventId, newConditionType: newConditionType);
    syncWithProjectViewModel();
  }

  void updateEventCondition({required String eventId, required EventCondition newCondition}) {
    _projectViewModel.updateEventCondition(eventId: eventId, newCondition: newCondition);
    syncWithProjectViewModel();
  }

  /// Update the selected state for a 2-state event (e.g. above / below).
  /// Routed through ConfigEventsViewmodel so that the events state always
  /// emits a new (different) object and all listeners rebuild correctly.
  void updateEventSelectedState({required String eventId, required EventStates selectedState}) {
    _projectViewModel.updateEventSelectedState(eventId: eventId, selectedState: selectedState);
    syncWithProjectViewModel();
  }

  @override
  Future<void> close() {
    _projectViewModel.setSelectedEventId(null);
    return super.close();
  }
}
