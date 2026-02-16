// ignore_for_file: public_member_api_docs, sort_constructors_first
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

class SourceSelectAdditionalSettingsModel extends Equatable {
  final List<String> selectedSourcesIds;
  final bool useOff;
  final bool useCrossfade;
  final double thresholdValue;
  final double reductionValue;

  final List<PriorityAdditionalSettingsModel>? priorityAdditionalSettingsModel;

  final List<Zone>? zone;
  final List<SubZone>? subZone;

  const SourceSelectAdditionalSettingsModel({
    this.selectedSourcesIds = const <String>[],
    this.useOff = false,
    this.useCrossfade = false,
    this.thresholdValue = 0,
    this.reductionValue = 0,
    this.priorityAdditionalSettingsModel,
    this.zone,
    this.subZone,
  });

  SourceSelectAdditionalSettingsModel copyWith({
    List<String>? selectedSourcesIds,
    bool? useOff,
    bool? useCrossfade,
    double? thresholdValue,
    double? reductionValue,
    List<PriorityAdditionalSettingsModel>? priorityAdditionalSettingsModel,
    List<Zone>? zone,
    List<SubZone>? subZone,
  }) {
    return SourceSelectAdditionalSettingsModel(
      selectedSourcesIds: selectedSourcesIds ?? this.selectedSourcesIds,
      useOff: useOff ?? this.useOff,
      useCrossfade: useCrossfade ?? this.useCrossfade,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      reductionValue: reductionValue ?? this.reductionValue,
      priorityAdditionalSettingsModel: priorityAdditionalSettingsModel ?? this.priorityAdditionalSettingsModel,
      zone: zone ?? this.zone,
      subZone: subZone ?? this.subZone,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedSourcesIds,
    useOff,
    useCrossfade,
    thresholdValue,
    reductionValue,
    priorityAdditionalSettingsModel,
    zone,
    subZone,
  ];
}

class PriorityAdditionalSettingsModel extends Equatable {
  final AdditionalSettingsPriorityControlType priorityControlType;
  final AdditionalSettingPriorityBehavior? priorityBehavior;
  final double depth;
  final double attack;
  final double hold;
  final double release;

  const PriorityAdditionalSettingsModel({
    this.priorityControlType = AdditionalSettingsPriorityControlType.pttControler,
    this.priorityBehavior,
    this.depth = 0,
    this.attack = 0,
    this.hold = 0,
    this.release = 0,
  });

  PriorityAdditionalSettingsModel copyWith({
    AdditionalSettingsPriorityControlType? priorityControlType,
    AdditionalSettingPriorityBehavior? priorityBehavior,
    double? depth,
    double? attack,
    double? hold,
    double? release,
  }) {
    return PriorityAdditionalSettingsModel(
      priorityControlType: priorityControlType ?? this.priorityControlType,
      priorityBehavior: priorityBehavior ?? this.priorityBehavior,
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
    depth,
    attack,
    hold,
    release,
  ];
}
