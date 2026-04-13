part of 'mix_settings_vm.dart';

class SourceMixAdditionalSettingsVmState extends Equatable {
  final List<SourceVolumneRangeModel> sources;
  final VolumneRangeModel? zoneVolumeRange;
  final List<VolumneRangeModel>? subZonesVolumeRange;
  final bool assignToControllers;

  final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel;

  const SourceMixAdditionalSettingsVmState({
    this.sources = const <SourceVolumneRangeModel>[],
    this.zoneVolumeRange,
    this.subZonesVolumeRange,
    this.assignToControllers = false,
    this.priorityAdditionalSettingsModel = const <PriorityAdditionalSettingsModel>[],
  });

  SourceMixAdditionalSettingsVmState copyWith({
    List<SourceVolumneRangeModel>? sources,
    VolumneRangeModel? zoneVolumeRange,
    List<VolumneRangeModel>? subZonesVolumeRange,
    bool? assignToControllers,
    List<PriorityAdditionalSettingsModel>? priorityAdditionalSettingsModel,
  }) {
    return SourceMixAdditionalSettingsVmState(
      sources: sources ?? this.sources,
      zoneVolumeRange: zoneVolumeRange ?? this.zoneVolumeRange,
      subZonesVolumeRange: subZonesVolumeRange ?? this.subZonesVolumeRange,
      assignToControllers: assignToControllers ?? this.assignToControllers,
      priorityAdditionalSettingsModel: priorityAdditionalSettingsModel ?? this.priorityAdditionalSettingsModel,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    sources,
    zoneVolumeRange,
    subZonesVolumeRange,
    assignToControllers,
    priorityAdditionalSettingsModel,
  ];
}
