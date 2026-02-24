part of 'source_mix_settings_vm.dart';

class SourceMixAdditionalSettingsVmState extends Equatable {
  final List<SourceVolumneRangeModel> sources;
  final VolumneRangeModel? zoneVolumeRange;
  final List<VolumneRangeModel>? subZonesVolumeRange;
  final bool assignToControllers;

  const SourceMixAdditionalSettingsVmState({
    this.sources = const <SourceVolumneRangeModel>[],
    this.zoneVolumeRange,
    this.subZonesVolumeRange,
    this.assignToControllers = false,
  });

  SourceMixAdditionalSettingsVmState copyWith({
    List<SourceVolumneRangeModel>? sources,
    VolumneRangeModel? zoneVolumeRange,
    List<VolumneRangeModel>? subZonesVolumeRange,
    bool? assignToControllers,
  }) {
    return SourceMixAdditionalSettingsVmState(
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
