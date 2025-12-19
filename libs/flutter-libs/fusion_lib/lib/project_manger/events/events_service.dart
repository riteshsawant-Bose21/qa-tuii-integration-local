import 'package:fusion_lib/fusion_lib.dart';

extension EventsService on ProjectService {
  void addNewEvent(FusionEvent event) {
    events.add(event.id, event);
  }

  void updateEvent(FusionEvent event) {
    if (!events.exists(event.id)) {
      throw Exception("Event with id ${event.id} does not exist.");
    }
    events.add(event.id, event);
  }

  void removeEvent(String eventId) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }

    //remove all actions linked to event
    removeAllActionsFromEvent(eventId: eventId);

    events.remove(eventId);
  }

  void addEventForGPI({required String gpiId}) {
    final newEvent = FusionEvent(
      name: "GPI Event",
      triggerType: EventTriggerType.gpi,
      item: EventTriggerItem(
        itemId: gpiId,
      ),
    );
    events.add(newEvent.id, newEvent);
  }

  void addEventForSchedule({required String scheduleId}) {
    final newEvent = FusionEvent(
      name: "Scheduled Event",
      triggerType: EventTriggerType.schedule,
      item: EventTriggerItem(
        itemId: scheduleId,
      ),
      action: EventActionType.timedEvent,
    );
    events.add(newEvent.id, newEvent);
  }

  //Get first dropdown
  List<EventTriggerType> getEventTriggers() {
    return EventTriggerType.values;
  }

  void updateEventTrigger({required String eventId, required EventTriggerType newTrigger}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final event = events.get(eventId)!;

    switch (newTrigger) {
      case EventTriggerType.schedule:
        if (event.triggerType == EventTriggerType.schedule) {
          // No change needed
          break;
        }
        final updatedEvent = event.updateTriggerType(
          triggerType: newTrigger,
          action: EventActionType.timedEvent,
        );
        events.add(eventId, updatedEvent);
        //remove all actions linked to event as action type is changed
        removeAllActionsFromEvent(eventId: eventId);

      case EventTriggerType.gpi:
        //check if old is not gpi then only update it to avoid losing gpi item
        if (event.triggerType == EventTriggerType.gpi) {
          // No change needed
          break;
        }
        final updatedEvent = event.copyWith(
          triggerType: newTrigger,
        );
        events.add(eventId, updatedEvent);
        //remove all actions linked to event as action type is changed
        removeAllActionsFromEvent(eventId: eventId);
    }
  }

  List<EventTriggerItemDropdown> getEventTriggerItems({required EventTriggerType triggerType}) {
    switch (triggerType) {
      case EventTriggerType.schedule:
        return schedulerConfig.getAll().map((e) => EventTriggerItemDropdown(id: e.id, name: e.name)).toList();
      case EventTriggerType.gpi:
        return getGpiConfigs().map((e) => EventTriggerItemDropdown(id: e.id, name: e.name)).toList();
    }
  }

  void updateEventTriggerItem({required String eventId, required EventTriggerItem eventTriggerItem}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final event = events.get(eventId)!;
    if (event.item?.itemId == eventTriggerItem.itemId) {
      // No change needed
      return;
    }
    final updatedEvent = event.copyWith(item: eventTriggerItem);
    events.add(eventId, updatedEvent);
  }

  List<EventActionType> getEventActions({required String eventId}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final event = events.get(eventId)!;
    if (event.triggerType == EventTriggerType.schedule) {
      return [EventActionType.timedEvent];
    } else if (event.triggerType == EventTriggerType.gpi) {
      return [EventActionType.analog, EventActionType.digital];
    }
    return [];
  }

  void updateEventAction({required String eventId, required EventActionType newAction}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final event = events.get(eventId)!;

    if (event.action == newAction) {
      // No change needed
      return;
    }

    final updatedEvent = event.updateActionType(newAction);
    events.add(eventId, updatedEvent);

    //remove all actions linked to event as action type is changed
    removeAllActionsFromEvent(eventId: eventId);
  }

  List<EventConditionType> getEventConditionTypes({required String eventId}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final event = events.get(eventId)!;
    if (event.action == EventActionType.timedEvent) {
      return [];
    } else if (event.action == EventActionType.analog) {
      return [
        EventConditionType.threshold,
        EventConditionType.valueChange,
      ];
    } else if (event.action == EventActionType.digital) {
      return [
        EventConditionType.stateChange,
      ];
    }
    return [];
  }

  EventCondition getEventConditionForType({required EventConditionType conditionType}) {
    switch (conditionType) {
      case EventConditionType.stateChange:
        return StateChangeCondition();
      case EventConditionType.threshold:
        return ThresholdCondition(
          threshold: 50,
        );
      case EventConditionType.valueChange:
        return ValueChangeCondition(
          min: 0,
          max: 100,
        );
    }
  }

  List<EventStates>? getEventStatesForConditionType({required EventConditionType conditionType}) {
    switch (conditionType) {
      case EventConditionType.stateChange:
        return [EventStates.on(), EventStates.off()];
      case EventConditionType.threshold:
        return [EventStates.above(), EventStates.below()];
      case EventConditionType.valueChange:
        return null;
    }
  }

  void updateEventConditionType({required String eventId, required EventConditionType conditionType}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final event = events.get(eventId)!;
    final condition = getEventConditionForType(conditionType: conditionType);

    if (event.condition?.conditionType == conditionType) {
      // No change needed
      return;
    }

    List<EventStates>? states = getEventStatesForConditionType(conditionType: conditionType);

    final updatedEvent = event.updateCondition(
      condition: condition,
      states: states,
    );
    events.add(eventId, updatedEvent);

    //remove all actions linked to event as condition is changed
    removeAllActionsFromEvent(eventId: eventId);
  }

  void updateEventCondition({required String eventId, required EventCondition condition}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final event = events.get(eventId)!;

    final updatedEvent = event.copyWith(
      condition: condition,
    );
    events.add(eventId, updatedEvent);
  }

  void addActionToEvent({required String eventId, required SceneActionModel action}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    sceneActions.add(action.id, action);
    relationships.link(RelationshipType.eventActions, eventId, action.id);
  }

  void duplicateActionInEvent({required String eventId, required String actionId}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    if (!sceneActions.exists(actionId)) {
      throw Exception("Action with id $actionId does not exist.");
    }
    final originalAction = sceneActions.get(actionId)!;
    final duplicatedAction = originalAction.copyWith(
      id: "ACTION${FusionUtils.shortStringUUID()}",
    );
    sceneActions.add(duplicatedAction.id, duplicatedAction);
    relationships.link(RelationshipType.eventActions, eventId, duplicatedAction.id);
  }

  void removeActionFromEvent({required String eventId, required String actionId}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    relationships.unlink(RelationshipType.eventActions, eventId, actionId);

    snapshots.remove(actionId);
  }

  void removeAllActionsFromEvent({required String eventId}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final actionIds = relationships.getChildren(RelationshipType.eventActions, eventId);
    final copyOfActionIds = List<String>.from(actionIds);
    for (var actionId in copyOfActionIds) {
      removeActionFromEvent(eventId: eventId, actionId: actionId);
    }
  }

  List<FusionEvent> getAllEvents() {
    return events.getAll();
  }

  List<SceneActionModel> getEventActionsForEvent(String eventId) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final actionIds = relationships.getChildren(RelationshipType.eventActions, eventId);
    return actionIds.map((id) => sceneActions.get(id)!).toList();
  }

  FusionEvent getEventById({required String eventId}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    return events.get(eventId)!;
  }

  void updateEventSelectedState({required String eventId, required EventStates selectedState}) {
    if (!events.exists(eventId)) {
      throw Exception("Event with id $eventId does not exist.");
    }
    final FusionEvent event = events.get(eventId)!;
    final FusionEvent updated = event.copyWith(selectedState: selectedState);
    events.add(eventId, updated);
  }
}
