import 'package:fusion_lib/fusion_lib.dart';

extension EventsManager on ProjectManager {
  /// Add Event
  void addNewEvent(FusionEvent event) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addNewEvent(event);
  }

  /// Update Event
  void updateEvent(FusionEvent event) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateEvent(event);
  }

  /// Remove Event
  void removeEvent(String eventId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeEvent(eventId);
  }

  /// Get All Events
  List<FusionEvent> getAllEvents() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllEvents();
  }

  ///Adds new Event for GPI
  FusionEvent addEventForGPI({required String gpiId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.addEventForGPI(gpiId: gpiId);
  }

  /// Adds Events for Schedule Entries
  FusionEvent addEventForSchedule({required String scheduleId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.addEventForSchedule(scheduleId: scheduleId);
  }

  List<EventTriggerType> getEventTriggers() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getEventTriggers();
  }

  void updateEventTrigger({required String eventId, required EventTriggerType newTrigger}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateEventTrigger(eventId: eventId, newTrigger: newTrigger);
  }

  List<EventTriggerItemDropdown> getEventTriggerItems({required EventTriggerType triggerType}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getEventTriggerItems(triggerType: triggerType);
  }

  void updateEventTriggerItem({required String eventId, required EventTriggerItem eventTriggerItem}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateEventTriggerItem(eventId: eventId, eventTriggerItem: eventTriggerItem);
  }

  List<EventActionType> getEventActions({required String eventId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getEventActions(eventId: eventId);
  }

  void updateEventAction({required String eventId, required EventActionType newAction}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateEventAction(eventId: eventId, newAction: newAction);
  }

  List<EventConditionType> getEventConditionTypes({required String eventId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getEventConditionTypes(eventId: eventId);
  }

  void updateEventConditionType({required String eventId, required EventConditionType conditionType}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateEventConditionType(eventId: eventId, conditionType: conditionType);
  }

  void updateEventCondition({required String eventId, required EventCondition condition}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateEventCondition(eventId: eventId, condition: condition);
  }

  void addActionToEvent({required String eventId, required SceneActionModel action}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addActionToEvent(eventId: eventId, action: action);
  }

  void duplicateActionInEvent({required String eventId, required String actionId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.duplicateActionInEvent(eventId: eventId, actionId: actionId);
  }

  void removeActionFromEvent({required String eventId, required String actionId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeActionFromEvent(eventId: eventId, actionId: actionId);
  }

  void removeAllActionsFromEvent({required String eventId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.removeAllActionsFromEvent(eventId: eventId);
  }

  List<SceneActionModel> getEventActionsForEvent(String eventId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getEventActionsForEvent(eventId);
  }

  FusionEvent getEventById(String eventId) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getEventById(eventId: eventId);
  }

  FusionEvent? getEventsForGPI({required String gpiId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getEventsForGPI(gpiId: gpiId);
  }

  FusionEvent? getEventsForSchedule({required String scheduleId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getEventsForSchedule(scheduleId: scheduleId);
  }

  void updateEventSelectedState({required String eventId, required EventStates selectedState}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.updateEventSelectedState(eventId: eventId, selectedState: selectedState);
  }

  void reOrderEvents({required String eventIdToMove, required String eventAtNewIndex}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    Map<String, FusionEvent> reorderedList = projectService!.reOrderEvents(
      eventIdToMove: eventIdToMove,
      eventAtNewIndexId: eventAtNewIndex,
    );

    projectService = projectService!.copyWith(
      events: projectService!.events.copyWith(reorderedList),
    );
  }

  List<FusionEvent> getAllTimedEvents() {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    return projectService!.getAllTimedEvents();
  }
}
