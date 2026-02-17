part of 'source_matrix_additional_settings_viewmodel.dart';

class SourceMatrixSettingsViewmodelState extends Equatable {
  final List<String> selectedSourcesIds;
  final VolumneRangeModel? zoneVolumeRange;
  final List<VolumneRangeModel>? subZonesVolumeRange;
  final bool assignToControllers;

  const SourceMatrixSettingsViewmodelState({
    this.selectedSourcesIds = const <String>[],
    this.zoneVolumeRange,
    this.subZonesVolumeRange,
    this.assignToControllers = false,
  });

  SourceMatrixSettingsViewmodelState copyWith({
    List<String>? selectedSourcesIds,
    VolumneRangeModel? zoneVolumeRange,
    List<VolumneRangeModel>? subZonesVolumeRange,
    bool? assignToControllers,
  }) {
    return SourceMatrixSettingsViewmodelState(
      selectedSourcesIds: selectedSourcesIds ?? this.selectedSourcesIds,
      zoneVolumeRange: zoneVolumeRange ?? this.zoneVolumeRange,
      subZonesVolumeRange: subZonesVolumeRange ?? this.subZonesVolumeRange,
      assignToControllers: assignToControllers ?? this.assignToControllers,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedSourcesIds,
    zoneVolumeRange,
    subZonesVolumeRange,
    assignToControllers,
  ];
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
