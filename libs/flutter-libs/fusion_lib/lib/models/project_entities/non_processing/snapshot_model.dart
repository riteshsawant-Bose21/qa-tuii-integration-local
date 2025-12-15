enum SceneActionType {
  zoneControl,
  gpOut,
  snapshot,
  scene,
  // sourceControl,
  deviceControl,
}

extension SceneActionExtension on SceneActionType {
  String get displayName {
    switch (this) {
      case SceneActionType.zoneControl:
        return "Zone Control";
      case SceneActionType.gpOut:
        return "GPO Output";
      case SceneActionType.snapshot:
        return "Snapshot Recall";
      case SceneActionType.scene:
        return "Mix Scene Recall";
      // case SceneActionType.sourceControl:
      //   return "Source Control";
      case SceneActionType.deviceControl:
        return "Device Control";
    }
  }
}

class SceneItemDropdown {
  final String id;
  final String name;

  SceneItemDropdown({
    required this.id,
    required this.name,
  });
}

/// Represents a selectable item in column 2.
/// Example: Zone, SubZone, Source, SceneSet, GPO, Device, etc.
class SceneItem {
  final String itemId;

  SceneItem({
    required this.itemId,
  });

  factory SceneItem.fromJson(Map<String, dynamic> json) => SceneItem(
    itemId: json['itemId'],
  );

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
  };
}

enum SceneParamType {
  volume,
  mute,
  recall,
  sourceSelect,
  mixScene,
  prioritySelect1,
  prioritySelect2,
  setState,
  pulse,
  standby,
  inputLevel,
  inputMute,
}

extension SceneParamOptionExtension on SceneParamType {
  String get displayName {
    switch (this) {
      case SceneParamType.volume:
        return "Volume";
      case SceneParamType.mute:
        return "Mute/Unmute";
      case SceneParamType.recall:
        return "Recall";
      case SceneParamType.sourceSelect:
        return "Source Select";
      case SceneParamType.mixScene:
        return "Mix Scene";
      case SceneParamType.prioritySelect1:
        return "Priority Select 1";
      case SceneParamType.prioritySelect2:
        return "Priority Select 2";
      case SceneParamType.setState:
        return "Set State";
      case SceneParamType.pulse:
        return "Pulse";
      case SceneParamType.standby:
        return "Standby";
      case SceneParamType.inputLevel:
        return "Input Level";
      case SceneParamType.inputMute:
        return "Input Mute";
    }
  }

  SceneParamValueType get valueType {
    switch (this) {
      case SceneParamType.volume:
      case SceneParamType.inputLevel:
        return SceneParamValueType.volumeSlider;
      case SceneParamType.mute:
      case SceneParamType.inputMute:
        return SceneParamValueType.muteUnmute;
      case SceneParamType.recall:
      case SceneParamType.sourceSelect:
      case SceneParamType.mixScene:
      case SceneParamType.prioritySelect1:
      case SceneParamType.prioritySelect2:
        return SceneParamValueType.dropdownSingle;
      case SceneParamType.setState:
      case SceneParamType.standby:
        return SceneParamValueType.onOffButton;
      case SceneParamType.pulse:
        return SceneParamValueType.textInput;
    }
  }

  String get valueLabel {
    switch (this) {
      case SceneParamType.volume:
      case SceneParamType.inputLevel:
        return "Volume Level (0-100)";
      case SceneParamType.mute:
      case SceneParamType.inputMute:
        return "Mute State";
      case SceneParamType.recall:
      case SceneParamType.sourceSelect:
      case SceneParamType.mixScene:
      case SceneParamType.prioritySelect1:
      case SceneParamType.prioritySelect2:
        return "Select Option";
      case SceneParamType.setState:
        return "Set State (On/Off)";
      case SceneParamType.standby:
        return "Standby State (On/Off)";
      case SceneParamType.pulse:
        return "Pulse Duration (ms)";
    }
  }
}

enum SceneParamValueType {
  muteUnmute,
  volumeSlider,
  dropdownSingle,
  textInput,
  onOffButton,
}

class SceneParam {
  final String label;
  final SceneParamType type;
  final String? associatedId;

  SceneParam({
    required this.label,
    required this.type,
    this.associatedId,
  });

  factory SceneParam.fromJson(Map<String, dynamic> json) => SceneParam(
    label: json['label'],
    type: SceneParamType.values.firstWhere((e) => e.name == json['type']),
    associatedId: json['associatedId'],
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'type': type.name,
    'associatedId': associatedId,
  };

  // Add proper equality and hashCode implementation
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SceneParam && other.label == label && other.type == type && other.associatedId == associatedId;
  }

  @override
  int get hashCode => Object.hash(label, type, associatedId);

  // Add a convenience getter for valueType
  SceneParamValueType get valueType => type.valueType;
}

class SceneValueDropdown {
  final String value;
  final String label;

  SceneValueDropdown({
    required this.value,
    required this.label,
  });
}

/// Value for column 4 (type-safe)
class SceneValue {
  final String label;
  final String? value;
  final SceneParamValueType valueType;

  SceneValue({
    required this.label,
    this.value,
    required this.valueType,
  });

  //copy with
  SceneValue copyWith({
    String? label,
    String? value,
    SceneParamValueType? valueType,
  }) {
    return SceneValue(
      label: label ?? this.label,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
    );
  }

  factory SceneValue.fromJson(Map<String, dynamic> json) => SceneValue(
    value: json['value'],
    label: json['label'],
    valueType: SceneParamValueType.values.firstWhere((e) => e.name == json['valueType']),
  );

  Map<String, dynamic> toJson() => {
    'value': value,
    'label': label,
    'valueType': valueType.name,
  };
}

class SnapshotsModel {
  final String id;
  final String name;

  SnapshotsModel({
    String? id,
    required this.name,
  }) : id = id ?? "SCENE${DateTime.now().millisecondsSinceEpoch}";

  factory SnapshotsModel.fromJson(Map<String, dynamic> json) {
    return SnapshotsModel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  SnapshotsModel copyWith({
    String? id,
    String? name,
    List<SceneActionModel>? actions,
  }) {
    return SnapshotsModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

/// MAIN MODEL (One Row)
class SceneActionModel {
  String id;

  /// Column 1
  SceneActionType? actionType;

  /// Column 2 — complex object
  SceneItem? item;

  /// Column 3 — param object
  SceneParam? param;

  /// Column 4 — typed value
  SceneValue? value;

  SceneActionModel({
    String? id,
    this.actionType,
    this.item,
    this.param,
    this.value,
  }) : id = id ?? "ACTION${DateTime.now().millisecondsSinceEpoch}";

  bool get isComplete {
    switch (actionType) {
      case SceneActionType.zoneControl:
      case SceneActionType.gpOut:
      // case SceneActionType.sourceControl:
      case SceneActionType.deviceControl:
      case SceneActionType.scene:
        return item != null && param != null && value != null && value?.value != null;
      case SceneActionType.snapshot:
        return param != null && value != null && value?.value != null;
      case null:
        return false;
    }
  }

  factory SceneActionModel.fromJson(Map<String, dynamic> json) {
    return SceneActionModel(
      id: json['id'],
      actionType: json['actionType'] != null ? SceneActionType.values.firstWhere((e) => e.name == json['actionType']) : null,
      item: json['item'] != null ? SceneItem.fromJson(json['item']) : null,
      param: json['param'] != null ? SceneParam.fromJson(json['param']) : null,
      value: json['value'] != null ? SceneValue.fromJson(json['value']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionType': actionType?.name,
    'item': item?.toJson(),
    'param': param?.toJson(),
    'value': value?.toJson(),
  };

  SceneActionModel copyWith({
    String? id,
    SceneActionType? actionType,
    SceneItem? item,
    SceneParam? param,
    SceneValue? value,
  }) {
    return SceneActionModel(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      item: item ?? this.item,
      param: param ?? this.param,
      value: value ?? this.value,
    );
  }

  //get list of Action Types as strings
  // static List<String> getActionTypeStrings() {
  //   return SceneActionType.values.map((e) => e.displayName).toList();
  // }
}
