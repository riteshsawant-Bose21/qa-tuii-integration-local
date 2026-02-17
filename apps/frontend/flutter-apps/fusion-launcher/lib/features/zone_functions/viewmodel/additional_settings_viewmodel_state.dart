part of 'additional_settings_viewmodel.dart';

class ZoneFunctionAdditionalSettingsViewmodelState extends Equatable {
  final ZoneFunctionsType? zoneFunctionsType;
  final SourceSelectAdditionalSettingsModel? sourceSelectAdditionalSettingsModel;

  const ZoneFunctionAdditionalSettingsViewmodelState({this.zoneFunctionsType, this.sourceSelectAdditionalSettingsModel});

  ZoneFunctionAdditionalSettingsViewmodelState copyWith({
    ZoneFunctionsType? zoneFunctionsType,
    SourceSelectAdditionalSettingsModel? sourceSelectAdditionalSettingsModel,
  }) {
    return ZoneFunctionAdditionalSettingsViewmodelState(
      zoneFunctionsType: zoneFunctionsType ?? this.zoneFunctionsType,
      sourceSelectAdditionalSettingsModel: sourceSelectAdditionalSettingsModel ?? this.sourceSelectAdditionalSettingsModel,
    );
  }

  @override
  List<Object?> get props => <Object?>[zoneFunctionsType, sourceSelectAdditionalSettingsModel];
}

enum AdditionalSettingsPriorityControlType {
  pttControler,
  threshold,
}

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

class SourceSelectAdditionalSettingsModel extends Equatable {
  final List<String> selectedSourcesIds;
  final bool useOff;
  final bool useCrossfade;

  final List<PriorityAdditionalSettingsModel>? priorityAdditionalSettingsModel;

  final VolumneRangeModel? zoneVolumeRange;
  final List<VolumneRangeModel>? subZonesVolumeRange;

  // SOURCE MIX
  final bool assignToControllers;

  const SourceSelectAdditionalSettingsModel({
    this.selectedSourcesIds = const <String>[],
    this.useOff = false,
    this.useCrossfade = false,
    this.priorityAdditionalSettingsModel,
    this.zoneVolumeRange,
    this.subZonesVolumeRange,
    this.assignToControllers = false,
  });

  SourceSelectAdditionalSettingsModel copyWith({
    List<String>? selectedSourcesIds,
    bool? useOff,
    bool? useCrossfade,
    List<PriorityAdditionalSettingsModel>? priorityAdditionalSettingsModel,
    VolumneRangeModel? zoneVolumeRange,
    List<VolumneRangeModel>? subZonesVolumeRange,
    bool? assignToControllers,
  }) {
    return SourceSelectAdditionalSettingsModel(
      selectedSourcesIds: selectedSourcesIds ?? this.selectedSourcesIds,
      useOff: useOff ?? this.useOff,
      useCrossfade: useCrossfade ?? this.useCrossfade,
      priorityAdditionalSettingsModel: priorityAdditionalSettingsModel ?? this.priorityAdditionalSettingsModel,
      zoneVolumeRange: zoneVolumeRange ?? this.zoneVolumeRange,
      subZonesVolumeRange: subZonesVolumeRange ?? this.subZonesVolumeRange,
      assignToControllers: assignToControllers ?? this.assignToControllers,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedSourcesIds,
    useOff,
    useCrossfade,
    priorityAdditionalSettingsModel,
    zoneVolumeRange,
    subZonesVolumeRange,
    assignToControllers,
  ];
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

abstract class PriorityAdditionalSettingsModel1 extends Equatable {
  final AdditionalSettingsPriorityControlType priorityControlType;
  final AdditionalSettingPriorityBehavior? priorityBehavior;
  final bool isStateActive;
  final double? thresholdValue;
  final double? reductionValue;
  final double depth;
  final double attack;
  final double hold;
  final double release;

  const PriorityAdditionalSettingsModel1({
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
