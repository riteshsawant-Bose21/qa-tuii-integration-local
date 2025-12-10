import 'package:fusion_lib/fusion_lib.dart';

enum EventTriggerType {
  schedule,
  gpi,
}

extension EventTriggerTypeExtension on EventTriggerType {
  String get displayName {
    switch (this) {
      case EventTriggerType.schedule:
        return 'Schedule';
      case EventTriggerType.gpi:
        return 'GPI';
    }
  }
}

/// Item (Schedule Entry, GPI Input, etc.)
class EventTriggerItem {
  final String itemId;

  EventTriggerItem({
    required this.itemId,
  });

  factory EventTriggerItem.fromJson(Map<String, dynamic> json) => EventTriggerItem(
    itemId: json['itemType'],
  );

  Map<String, dynamic> toJson() => {
    'itemType': itemId,
  };
}

class EventTriggerItemDropdown {
  final String id;
  final String name;

  EventTriggerItemDropdown({
    required this.id,
    required this.name,
  });
}

/// Trigger/Action Type (Timed Event, Digital, Value Change...)
enum EventActionType {
  digital,
  analog,
  timedEvent,
}

extension EventActionExtension on EventActionType {
  String get displayName {
    switch (this) {
      case EventActionType.digital:
        return 'Digital';
      case EventActionType.analog:
        return 'Analog';
      case EventActionType.timedEvent:
        return 'Timed Event';
    }
  }
}

enum EventConditionType {
  stateChange,
  threshold,
  valueChange,
}

extension EventConditionTypeExtension on EventConditionType {
  String get displayName {
    switch (this) {
      case EventConditionType.stateChange:
        return 'State Change';
      case EventConditionType.threshold:
        return 'Threshold';
      case EventConditionType.valueChange:
        return 'Value Change';
    }
  }
}

enum EventStateTypes {
  on,
  off,
  above,
  below,
}

abstract class EventCondition {
  final EventConditionType conditionType;

  EventCondition({
    required this.conditionType,
  });
}

class StateChangeCondition extends EventCondition {
  final bool hasValue;

  StateChangeCondition({
    super.conditionType = EventConditionType.stateChange,
    this.hasValue = false,
  });

  factory StateChangeCondition.fromJson(Map<String, dynamic> json) {
    return StateChangeCondition(conditionType: EventConditionType.values.firstWhere((e) => e.name == json['type']), hasValue: json['hasValue'] ?? false);
  }

  Map<String, dynamic> toJson() => {
    'type': conditionType.name,
    'hasValue': hasValue,
  };
}

class ValueChangeCondition extends EventCondition {
  final bool hasValue;
  final double min;
  final double max;

  ValueChangeCondition({
    super.conditionType = EventConditionType.valueChange,
    required this.min,
    required this.max,
    this.hasValue = true,
  });

  //copy with
  ValueChangeCondition copyWith({
    EventConditionType? conditionType,
    double? min,
    double? max,
    bool? hasValue,
  }) {
    return ValueChangeCondition(
      conditionType: conditionType ?? this.conditionType,
      min: min ?? this.min,
      max: max ?? this.max,
      hasValue: hasValue ?? this.hasValue,
    );
  }

  factory ValueChangeCondition.fromJson(Map<String, dynamic> json) {
    return ValueChangeCondition(
      conditionType: EventConditionType.values.firstWhere((e) => e.name == json['type']),
      min: json['min'],
      max: json['max'],
      hasValue: json['hasValue'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': conditionType.name,
    'min': min,
    'max': max,
    'hasValue': hasValue,
  };
}

class ThresholdCondition extends EventCondition {
  final double threshold;
  final bool hasValue;

  ThresholdCondition({
    super.conditionType = EventConditionType.threshold,
    required this.threshold,
    this.hasValue = true,
  });

  ThresholdCondition copyWith({
    EventConditionType? conditionType,
    double? threshold,
    bool? hasValue,
  }) {
    return ThresholdCondition(
      conditionType: conditionType ?? this.conditionType,
      threshold: threshold ?? this.threshold,
      hasValue: hasValue ?? this.hasValue,
    );
  }

  factory ThresholdCondition.fromJson(Map<String, dynamic> json) {
    return ThresholdCondition(
      conditionType: EventConditionType.values.firstWhere((e) => e.name == json['type']),
      threshold: json['threshold'],
      hasValue: json['hasValue'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': conditionType.name,
    'threshold': threshold,
    'hasValue': hasValue,
  };
}

class EventStates {
  final String name;
  final EventStateTypes stateType;

  EventStates({
    required this.name,
    required this.stateType,
  });

  factory EventStates.on() => EventStates(
    stateType: EventStateTypes.on,
    name: 'On',
  );

  factory EventStates.off() => EventStates(
    stateType: EventStateTypes.off,
    name: 'Off',
  );

  factory EventStates.above() => EventStates(
    stateType: EventStateTypes.above,
    name: 'Above',
  );

  factory EventStates.below() => EventStates(
    stateType: EventStateTypes.below,
    name: 'Below',
  );

  factory EventStates.fromJson(Map<String, dynamic> json) => EventStates(
    stateType: EventStateTypes.values.firstWhere((e) => e.name == json['stateType']),
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'stateType': stateType.name,
    'name': name,
  };
}

/// MAIN MODEL
class FusionEvent {
  final String id;
  final String name;
  final bool isEnabled;
  final EventTriggerType? triggerType;
  final EventTriggerItem? item;
  final EventActionType? action;
  final EventCondition? condition;
  final List<EventStates>? states;

  bool get isComplete {
    if (triggerType == null || item == null || action == null) {
      return false;
    }
    // For timed events, no condition or states are needed
    if (action == EventActionType.timedEvent) {
      return true;
    }
    // For other actions, condition and states are required
    if (condition == null || states == null || states!.isEmpty) {
      return false;
    }
    return true;
  }

  FusionEvent({
    String? id,
    required this.name,
    this.isEnabled = true,
    this.triggerType,
    this.item,
    this.action,
    this.condition,
    this.states,
  }) : id = id ?? "FUSIONEVENT${FusionUtils.shortStringUUID()}";

  factory FusionEvent.fromJson(Map<String, dynamic> json) {
    return FusionEvent(
      id: json['id'],
      name: json['name'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      triggerType: EventTriggerType.values.firstWhere((e) => e.name == json['triggerType']),
      item: EventTriggerItem.fromJson(json['item']),
      action: EventActionType.values.firstWhere((e) => e.name == json['action']),
      condition: json['condition'] != null
          ? switch (EventConditionType.values.firstWhere((e) => e.name == json['condition']['type'])) {
              EventConditionType.stateChange => StateChangeCondition.fromJson(json['condition']),
              EventConditionType.threshold => ThresholdCondition.fromJson(json['condition']),
              EventConditionType.valueChange => ValueChangeCondition.fromJson(json['condition']),
            }
          : null,
      states: json['states'] != null ? (json['states'] as List).map((e) => EventStates.fromJson(e)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isEnabled': isEnabled,
    'triggerType': triggerType?.name,
    'item': item?.toJson(),
    'action': action?.name,
    'condition': condition != null
        ? switch (condition?.conditionType) {
            EventConditionType.stateChange => (condition as StateChangeCondition).toJson(),
            EventConditionType.threshold => (condition as ThresholdCondition).toJson(),
            EventConditionType.valueChange => (condition as ValueChangeCondition).toJson(),
            null => null,
          }
        : null,
    'states': states?.map((e) => e.toJson()).toList(),
  };

  FusionEvent copyWith({
    String? id,
    String? name,
    bool? isEnabled,
    EventTriggerType? triggerType,
    EventTriggerItem? item,
    EventActionType? action,
    EventCondition? condition,
    List<EventStates>? states,
  }) {
    return FusionEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      triggerType: triggerType ?? this.triggerType,
      item: item ?? this.item,
      action: action ?? this.action,
      condition: condition ?? this.condition,
      states: states ?? this.states,
    );
  }

  FusionEvent updateTriggerType({required EventTriggerType triggerType, required EventActionType? action}) {
    return FusionEvent(
      id: id,
      name: name,
      isEnabled: isEnabled,
      triggerType: triggerType,
      item: null,
      action: action,
      condition: null,
      states: null,
    );
  }

  FusionEvent updateActionType(EventActionType action) {
    return FusionEvent(
      id: id,
      name: name,
      isEnabled: isEnabled,
      triggerType: triggerType,
      item: item,
      action: action,
      condition: null,
      states: null,
    );
  }

  FusionEvent updateItem(EventTriggerItem item) {
    return FusionEvent(
      id: id,
      name: name,
      isEnabled: isEnabled,
      triggerType: triggerType,
      item: item,
      action: null,
      condition: null,
      states: null,
    );
  }
}
