part of 'source_mix_additional_settings_viewmodel.dart';

class SourceMixAdditionalSettingsViewmodelState extends Equatable {
  final List<String> selectedSourcesIds;
  final VolumneRangeModel? zoneVolumeRange;
  final List<VolumneRangeModel>? subZonesVolumeRange;
  final bool assignToControllers;

  const SourceMixAdditionalSettingsViewmodelState({
    this.selectedSourcesIds = const <String>[],
    this.zoneVolumeRange,
    this.subZonesVolumeRange,
    this.assignToControllers = false,
  });

  SourceMixAdditionalSettingsViewmodelState copyWith({
    List<String>? selectedSourcesIds,
    VolumneRangeModel? zoneVolumeRange,
    List<VolumneRangeModel>? subZonesVolumeRange,
    bool? assignToControllers,
  }) {
    return SourceMixAdditionalSettingsViewmodelState(
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
