part of 'source_select_settings_vm.dart';

class SourceSelectAdditionalSettingsVmState extends Equatable {
  final List<String> selectedSourcesIds;
  final bool useOff;
  final bool useCrossfade;

  final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel;

  final VolumneRangeModel? zoneVolumeRange;
  final List<VolumneRangeModel>? subZonesVolumeRange;

  // SOURCE MIX
  final bool assignToControllers;

  const SourceSelectAdditionalSettingsVmState({
    this.selectedSourcesIds = const <String>[],
    this.useOff = false,
    this.useCrossfade = false,
    this.priorityAdditionalSettingsModel = const <PriorityAdditionalSettingsModel>[],
    this.zoneVolumeRange,
    this.subZonesVolumeRange,
    this.assignToControllers = false,
  });

  SourceSelectAdditionalSettingsVmState copyWith({
    List<String>? selectedSourcesIds,
    bool? useOff,
    bool? useCrossfade,
    List<PriorityAdditionalSettingsModel>? priorityAdditionalSettingsModel,
    VolumneRangeModel? zoneVolumeRange,
    List<VolumneRangeModel>? subZonesVolumeRange,
    bool? assignToControllers,
  }) {
    return SourceSelectAdditionalSettingsVmState(
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
