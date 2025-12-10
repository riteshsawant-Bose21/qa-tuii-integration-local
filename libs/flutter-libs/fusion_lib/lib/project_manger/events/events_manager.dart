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
  void addEventForGPI({required String gpiId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addEventForGPI(gpiId: gpiId);
  }

  /// Adds Events for Schedule Entries
  void addEventForSchedule({required String scheduleId}) {
    if (projectService == null) {
      throw Exception('No project is currently open');
    }
    projectService!.addEventForSchedule(scheduleId: scheduleId);
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
}
