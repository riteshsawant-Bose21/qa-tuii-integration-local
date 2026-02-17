import 'package:equatable/equatable.dart';

enum AdditionalSettingsPriorityControlType { pttControler, threshold }

enum AdditionalSettingPriorityBehavior {
  override(displayName: "Override"),
  talkOver(displayName: "Talk Over"),
  ducking(displayName: "Ducking"),
  custom(displayName: "Custom");

  const AdditionalSettingPriorityBehavior({required this.displayName});
  final String displayName;
}

class VolumneRangeModel extends Equatable {
  final String zoneOrSubzoneId;
  final double lowerGain;
  final double upperGain;
  final bool allowMute;

  const VolumneRangeModel({
    this.lowerGain = -6,
    this.upperGain = 6,
    required this.zoneOrSubzoneId,
    this.allowMute = true,
  });

  VolumneRangeModel copyWith({
    double? lowerGain,
    double? upperGain,
    String? zoneOrSubzoneId,
    bool? allowMute,
  }) {
    return VolumneRangeModel(
      lowerGain: lowerGain ?? this.lowerGain,
      upperGain: upperGain ?? this.upperGain,
      zoneOrSubzoneId: zoneOrSubzoneId ?? this.zoneOrSubzoneId,
      allowMute: allowMute ?? this.allowMute,
    );
  }

  @override
  List<Object?> get props => <Object?>[lowerGain, upperGain, zoneOrSubzoneId, allowMute];
}

class SourceVolumneRangeModel extends Equatable {
  final String sourceId;
  final double lowerGain;
  final double upperGain;
  final bool allowMute;

  const SourceVolumneRangeModel({
    this.lowerGain = -6,
    this.upperGain = 6,
    required this.sourceId,
    this.allowMute = true,
  });

  SourceVolumneRangeModel copyWith({
    double? lowerGain,
    double? upperGain,
    String? sourceId,
    bool? allowMute,
  }) {
    return SourceVolumneRangeModel(
      lowerGain: lowerGain ?? this.lowerGain,
      upperGain: upperGain ?? this.upperGain,
      sourceId: sourceId ?? this.sourceId,
      allowMute: allowMute ?? this.allowMute,
    );
  }

  @override
  List<Object?> get props => <Object?>[lowerGain, upperGain, sourceId, allowMute];
}

class PriorityAdditionalSettingsModel extends Equatable {
  final AdditionalSettingsPriorityControlType priorityControlType;
  final AdditionalSettingPriorityBehavior? priorityBehavior;
  final bool isStateActive;
  final double? thresholdValue;
  final double? reductionValue;
  final double depth;
  final double attack;
  final double hold;
  final double release;

  const PriorityAdditionalSettingsModel({
    this.priorityControlType = AdditionalSettingsPriorityControlType.pttControler,
    this.priorityBehavior,
    this.isStateActive = false,
    this.thresholdValue,
    this.reductionValue,
    this.depth = 0,
    this.attack = 0,
    this.hold = 0,
    this.release = 0,
  });

  PriorityAdditionalSettingsModel copyWith({
    AdditionalSettingsPriorityControlType? priorityControlType,
    AdditionalSettingPriorityBehavior? priorityBehavior,
    bool? isStateActive,
    double? thresholdValue,
    double? reductionValue,
    double? depth,
    double? attack,
    double? hold,
    double? release,
  }) {
    return PriorityAdditionalSettingsModel(
      priorityControlType: priorityControlType ?? this.priorityControlType,
      priorityBehavior: priorityBehavior ?? this.priorityBehavior,
      isStateActive: isStateActive ?? this.isStateActive,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      reductionValue: reductionValue ?? this.reductionValue,
      depth: depth ?? this.depth,
      attack: attack ?? this.attack,
      hold: hold ?? this.hold,
      release: release ?? this.release,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    priorityControlType,
    priorityBehavior,
    isStateActive,
    thresholdValue,
    reductionValue,
    depth,
    attack,
    hold,
    release,
  ];
}
