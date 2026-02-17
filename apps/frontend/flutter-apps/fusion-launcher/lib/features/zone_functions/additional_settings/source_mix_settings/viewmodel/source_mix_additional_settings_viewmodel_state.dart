part of 'source_mix_additional_settings_viewmodel.dart';

class SourceMixAdditionalSettingsViewmodelState extends Equatable {
  final List<SourceVolumneRangeModel> sources;
  final VolumneRangeModel? zoneVolumeRange;
  final List<VolumneRangeModel>? subZonesVolumeRange;
  final bool assignToControllers;

  const SourceMixAdditionalSettingsViewmodelState({
    this.sources = const <SourceVolumneRangeModel>[],
    this.zoneVolumeRange,
    this.subZonesVolumeRange,
    this.assignToControllers = false,
  });

  SourceMixAdditionalSettingsViewmodelState copyWith({
    List<SourceVolumneRangeModel>? sources,
    VolumneRangeModel? zoneVolumeRange,
    List<VolumneRangeModel>? subZonesVolumeRange,
    bool? assignToControllers,
  }) {
    return SourceMixAdditionalSettingsViewmodelState(
      sources: sources ?? this.sources,
      zoneVolumeRange: zoneVolumeRange ?? this.zoneVolumeRange,
      subZonesVolumeRange: subZonesVolumeRange ?? this.subZonesVolumeRange,
      assignToControllers: assignToControllers ?? this.assignToControllers,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    sources,
    zoneVolumeRange,
    subZonesVolumeRange,
    assignToControllers,
  ];
}
