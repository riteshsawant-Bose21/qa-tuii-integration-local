import 'dart:ui';

import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/entitity/event_item_entity.dart';
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

  FusionEvent? addEventForGPI({required String gpiId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final FusionEvent addedEvent = projectManager.addEventForGPI(gpiId: gpiId);
      if (autoSave) {
        saveProject();
      }
      selectedEventId = addedEvent.id;
      return addedEvent;
    } catch (ex) {
      throwError("Failed to add GPI event: $ex");
    }
    return null;
  }

  FusionEvent? addEventForSchedule({required String scheduleId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final FusionEvent fusionEvent = projectManager.addEventForSchedule(scheduleId: scheduleId);
      if (autoSave) {
        saveProject();
      }
      selectedEventId = fusionEvent.id;
      return fusionEvent;
    } catch (ex) {
      throwError("Failed to add scheduled event: $ex");
    }
    return null;
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

  FusionEvent getEventById(String eventId) {
    try {
      return projectManager.getEventById(eventId);
    } catch (ex) {
      throwError("Failed to retrieve event by id: $ex");
      rethrow;
    }
  }

  FusionEvent? getEventsForGPI({required String gpiId}) {
    try {
      return projectManager.getEventsForGPI(gpiId: gpiId);
    } catch (ex) {
      throwError("Failed to retrieve events for GPI: $ex");
      return null;
    }
  }

  FusionEvent? getEventsForSchedule({required String scheduleId}) {
    try {
      return projectManager.getEventsForSchedule(scheduleId: scheduleId);
    } catch (ex) {
      throwError("Failed to retrieve events for schedule: $ex");
      return null;
    }
  }

  void updateEventSelectedState({required String eventId, required EventStates selectedState, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateEventSelectedState(eventId: eventId, selectedState: selectedState);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      throwError("Failed to update event selected state: $ex");
    }
  }

  void reOrderEvents({required String eventIdToMove, required String eventAtNewIndex, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOrderEvents(eventIdToMove: eventIdToMove, eventAtNewIndex: eventAtNewIndex);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      throwError("Failed to reorder events: $ex");
    }
  }

  List<FusionEvent> getAllTimedEvents() {
    try {
      return projectManager.getAllTimedEvents();
    } catch (ex) {
      throwError("Failed to retrieve all timed events: $ex");
      return <FusionEvent>[];
    }
  }

  ScheduleConfig? getScheduleForEvent({required String eventId}) {
    try {
      final FusionEvent event = projectManager.getEventById(eventId);
      final ScheduleConfig? scheduleConfig = projectManager.getScheduleById(event.item!.itemId);
      return scheduleConfig;
    } catch (ex) {
      throwError("Failed to retrieve schedule for event: $ex");
      return null;
    }
  }

  List<EventItemEntity> getAllScheduledEvents() {
    try {
      final List<FusionEvent> timedEvents = getAllTimedEvents();
      final List<EventItemEntity> scheduledEventItems =
          timedEvents.map((FusionEvent event) {
            final ScheduleConfig? schedule = getScheduleById(event.item!.itemId);
            if (schedule != null) {
              return EventItemEntity(
                time: schedule.time,
                title: schedule.name,
                eventName: event.name,
                eventId: event.id,
                accentColor: Color(int.parse(schedule.colorHex.replaceFirst('#', '0xFF'))), // Convert hex string to Color
                isEnabled: event.isEnabled,
              );
            } else {
              throw Exception("No schedule found for event ${event.id}");
            }
          }).toList();
      return scheduledEventItems;
    } catch (ex) {
      throwError("Failed to retrieve scheduled events: $ex");
      return <EventItemEntity>[];
    }
  }

  //get upcoming events for the next 24 hours
  List<EventItemEntity> getAllUpcomingEvents() {
    try {
      final List<FusionEvent> timedEvents = getAllTimedEvents();
      final DateTime now = DateTime.now();
      final DateTime next24Hours = now.add(const Duration(hours: 24));

      final List<EventItemEntity> upcomingEventItems =
          timedEvents
              .where((FusionEvent event) {
                final ScheduleConfig? schedule = getScheduleById(event.item!.itemId);
                if (schedule != null) {
                  return schedule.time.isAfter(now) && schedule.time.isBefore(next24Hours);
                }
                return false;
              })
              .map((FusionEvent event) {
                final ScheduleConfig? schedule = getScheduleById(event.item!.itemId);
                return EventItemEntity(
                  time: schedule!.time,
                  title: schedule.name,
                  eventName: event.name,
                  eventId: event.id,
                  accentColor: Color(int.parse(schedule.colorHex.replaceFirst('#', '0xFF'))), // Convert hex string to Color
                  isEnabled: event.isEnabled,
                );
              })
              .toList();

      return upcomingEventItems;
    } catch (ex) {
      throwError("Failed to retrieve upcoming events: $ex");
      return <EventItemEntity>[];
    }
  }

  void toggleEvent({required String eventId, required bool isEnabled, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final FusionEvent event = projectManager.getEventById(eventId);
      final FusionEvent updatedEvent = event.copyWith(isEnabled: isEnabled);
      projectManager.updateEvent(updatedEvent);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (ex) {
      throwError("Failed to toggle event: $ex");
    }
  }
}
