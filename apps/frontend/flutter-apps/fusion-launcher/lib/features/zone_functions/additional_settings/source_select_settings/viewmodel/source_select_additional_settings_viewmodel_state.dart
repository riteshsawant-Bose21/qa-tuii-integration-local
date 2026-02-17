part of 'source_select_additional_settings_viewmodel.dart';

class SourceSelectAdditionalSettingsState extends Equatable {
  final List<String> selectedSourcesIds;
  final bool useOff;
  final bool useCrossfade;

  final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel;

  final VolumneRangeModel? zoneVolumeRange;
  final List<VolumneRangeModel>? subZonesVolumeRange;

  // SOURCE MIX
  final bool assignToControllers;

  const SourceSelectAdditionalSettingsState({
    this.selectedSourcesIds = const <String>[],
    this.useOff = false,
    this.useCrossfade = false,
    this.priorityAdditionalSettingsModel = const <PriorityAdditionalSettingsModel>[],
    this.zoneVolumeRange,
    this.subZonesVolumeRange,
    this.assignToControllers = false,
  });

  SourceSelectAdditionalSettingsState copyWith({
    List<String>? selectedSourcesIds,
    bool? useOff,
    bool? useCrossfade,
    List<PriorityAdditionalSettingsModel>? priorityAdditionalSettingsModel,
    VolumneRangeModel? zoneVolumeRange,
    List<VolumneRangeModel>? subZonesVolumeRange,
    bool? assignToControllers,
  }) {
    return SourceSelectAdditionalSettingsState(
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
