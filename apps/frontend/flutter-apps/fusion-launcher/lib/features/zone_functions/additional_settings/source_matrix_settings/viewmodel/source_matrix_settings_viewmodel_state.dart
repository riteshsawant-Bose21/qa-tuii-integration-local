part of 'source_matrix_additional_settings_viewmodel.dart';

class SourceMatrixSettingsViewmodelState extends Equatable {
  final List<String> selectedSourcesIds;
  final VolumneRangeModel? zoneVolumeRange;
  final List<VolumneRangeModel>? subZonesVolumeRange;
  final bool assignToControllers;

  final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel;

  const SourceMatrixSettingsViewmodelState({
    this.selectedSourcesIds = const <String>[],
    this.zoneVolumeRange,
    this.subZonesVolumeRange,
    this.assignToControllers = false,
    this.priorityAdditionalSettingsModel = const <PriorityAdditionalSettingsModel>[],
  });

  SourceMatrixSettingsViewmodelState copyWith({
    List<String>? selectedSourcesIds,
    VolumneRangeModel? zoneVolumeRange,
    List<VolumneRangeModel>? subZonesVolumeRange,
    bool? assignToControllers,
    List<PriorityAdditionalSettingsModel>? priorityAdditionalSettingsModel,
  }) {
    return SourceMatrixSettingsViewmodelState(
      selectedSourcesIds: selectedSourcesIds ?? this.selectedSourcesIds,
      zoneVolumeRange: zoneVolumeRange ?? this.zoneVolumeRange,
      subZonesVolumeRange: subZonesVolumeRange ?? this.subZonesVolumeRange,
      assignToControllers: assignToControllers ?? this.assignToControllers,
      priorityAdditionalSettingsModel: priorityAdditionalSettingsModel ?? this.priorityAdditionalSettingsModel,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedSourcesIds,
    zoneVolumeRange,
    subZonesVolumeRange,
    assignToControllers,
    priorityAdditionalSettingsModel,
  ];
}
