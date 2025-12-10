import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

extension EventsViewModel on ProjectViewModel {
  /// Add Event
  void addNewEvent({required FusionEvent event, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addNewEvent(event);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to add new event: $ex");
    }
  }

  void updateEvent({required FusionEvent event, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateEvent(event);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to update event: $ex");
    }
  }

  void removeEvent({required String eventId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeEvent(eventId);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to remove event: $ex");
    }
  }

  List<FusionEvent> getAllEvents() {
    try {
      return projectManager.getAllEvents();
    } catch (ex) {
      throwError("Failed to retrieve events: $ex");
      return <FusionEvent>[];
    }
  }

  void addEventForGPI({required String gpiId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addEventForGPI(gpiId: gpiId);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to add GPI event: $ex");
    }
  }

  void addEventForSchedule({required String scheduleId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addEventForSchedule(scheduleId: scheduleId);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to add scheduled event: $ex");
    }
  }

  List<EventTriggerType> getEventTriggers() {
    try {
      return projectManager.getEventTriggers();
    } catch (ex) {
      throwError("Failed to retrieve event triggers: $ex");
      return <EventTriggerType>[];
    }
  }

  void updateEventTrigger({required String eventId, required EventTriggerType newTrigger, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateEventTrigger(eventId: eventId, newTrigger: newTrigger);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to update event trigger: $ex");
    }
  }

  List<EventTriggerItemDropdown> getEventTriggerDropdownItems({required EventTriggerType triggerType}) {
    try {
      return projectManager.getEventTriggerItems(triggerType: triggerType);
    } catch (ex) {
      throwError("Failed to retrieve event trigger items: $ex");
      return <EventTriggerItemDropdown>[];
    }
  }

  void updateEventTriggerItem({required String eventId, required EventTriggerItem newItem, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateEventTriggerItem(eventId: eventId, eventTriggerItem: newItem);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to update event trigger item: $ex");
    }
  }

  List<EventActionType> getEventActions({required String eventId}) {
    try {
      return projectManager.getEventActions(eventId: eventId);
    } catch (ex) {
      throwError("Failed to retrieve event actions: $ex");
      return <EventActionType>[];
    }
  }

  void updateEventAction({required String eventId, required EventActionType newAction, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateEventAction(eventId: eventId, newAction: newAction);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to update event action: $ex");
    }
  }

  List<EventConditionType> getEventConditionTypes({required String eventId}) {
    try {
      return projectManager.getEventConditionTypes(eventId: eventId);
    } catch (ex) {
      throwError("Failed to retrieve event condition types: $ex");
      return <EventConditionType>[];
    }
  }

  void updateEventConditionType({required String eventId, required EventConditionType newConditionType, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateEventConditionType(eventId: eventId, conditionType: newConditionType);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to update event condition type: $ex");
    }
  }

  void updateEventCondition({required String eventId, required EventCondition newCondition, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateEventCondition(eventId: eventId, condition: newCondition);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to update event condition: $ex");
    }
  }

  void addActionToEvent({required String eventId, required SceneActionModel action, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addActionToEvent(eventId: eventId, action: action);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to add action to event: $ex");
    }
  }

  void duplicateActionInEvent({required String eventId, required String actionId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.duplicateActionInEvent(eventId: eventId, actionId: actionId);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to duplicate action in event: $ex");
    }
  }

  void removeActionFromEvent({required String eventId, required String actionId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeActionFromEvent(eventId: eventId, actionId: actionId);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to remove action from event: $ex");
    }
  }

  void removeAllActionsFromEvent({required String eventId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeAllActionsFromEvent(eventId: eventId);
      if (autoSave) {
        saveProject();
      }
    } catch (ex) {
      throwError("Failed to remove all actions from event: $ex");
    }
  }

  List<SceneActionModel> getEventActionsForEvent(String eventId) {
    try {
      return projectManager.getEventActionsForEvent(eventId);
    } catch (ex) {
      throwError("Failed to retrieve event actions for event: $ex");
      return <SceneActionModel>[];
    }
  }
}
