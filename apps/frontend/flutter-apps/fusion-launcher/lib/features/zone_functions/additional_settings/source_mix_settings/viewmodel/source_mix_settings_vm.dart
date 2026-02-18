import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart' show ListExtension;
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/zone_functions/additional_settings/models/models.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'source_mix_settings_vm_state.dart';

class SourceMixAdditionalSettingsViewmodel extends Cubit<SourceMixAdditionalSettingsVmState> {
  SourceMixAdditionalSettingsViewmodel() : super(const SourceMixAdditionalSettingsVmState());

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();

  bool hasSubZones = false;

  void init({required String zoneID}) {
    final List<Source> sources = projectViewModel.getSourcesInZone(zoneId: zoneID);

    SourceMixAdditionalSettingsVmState updatedState = state.copyWith(
      // ===============================================================================================
      // SOURCES volume range initialization
      // ===============================================================================================
      sources: <SourceVolumneRangeModel>[
        ...sources.map(
          (Source source) => SourceVolumneRangeModel(sourceId: source.id),
        ),
      ],
    );

    // ===============================================================================================
    // ZONE or SUBZONE volume range initialization
    // ===============================================================================================
    final List<SubZone> subZones = projectViewModel.getSubZonesForZone(parentZoneId: zoneID);
    if (subZones.isEmpty) {
      hasSubZones = false;
      updatedState = updatedState.copyWith(zoneVolumeRange: VolumneRangeModel(zoneOrSubzoneId: zoneID));
      emit(updatedState);
    } else {
      hasSubZones = true;
      final List<VolumneRangeModel> subZonesVolumes = subZones.map((SubZone subZone) => VolumneRangeModel(zoneOrSubzoneId: subZone.id)).toList();
      updatedState = updatedState.copyWith(subZonesVolumeRange: subZonesVolumes);
      emit(updatedState);
    }
  }

  SourceVolumneRangeModel getSourceRange(String sourceId) => state.sources.firstWhere((SourceVolumneRangeModel source) => source.sourceId == sourceId);

  bool get isAssignToControllersEnabled => state.assignToControllers;
  void toggleAssignToControllers() {
    final bool newValue = !isAssignToControllersEnabled;
    final SourceMixAdditionalSettingsVmState updated = state.copyWith(assignToControllers: newValue);
    emit(updated);
  }

  void updateSource({
    required String sourceId,
    double? lowerGain,
    double? upperGain,
    bool? alloMute,
  }) {
    final SourceVolumneRangeModel sourceRange = getSourceRange(sourceId);
    final SourceVolumneRangeModel updatedSourceRange = sourceRange.copyWith(
      lowerGain: lowerGain,
      upperGain: upperGain,
      allowMute: alloMute,
    );

    final Iterable<SourceVolumneRangeModel> updatedSources = state.sources.map((SourceVolumneRangeModel source) {
      return source.sourceId == sourceId ? updatedSourceRange : source;
    });

    emit(state.copyWith(sources: updatedSources.toList()));
  }

  // ZONE AND SUBZONES related methods
  void updateZoneProperties({
    required String zoneOrSubzoneId,
    double? upperLimit,
    double? lowerLimit,
    bool? allowMuteUnmute,
  }) {
    if (hasSubZones) {
      final List<VolumneRangeModel> subZonesVolumeRange = state.subZonesVolumeRange ?? <VolumneRangeModel>[];
      final List<VolumneRangeModel> updatedSubZonesVolumeRange =
          subZonesVolumeRange.map((VolumneRangeModel e) {
            if (e.zoneOrSubzoneId == zoneOrSubzoneId) {
              return e.copyWith(
                lowerGain: lowerLimit ?? e.lowerGain,
                upperGain: upperLimit ?? e.upperGain,
                allowMute: allowMuteUnmute ?? e.allowMute,
              );
            }
            return e;
          }).toList();

      emit(state.copyWith(subZonesVolumeRange: updatedSubZonesVolumeRange));
    } else {
      VolumneRangeModel? zoneVolumeRange = state.zoneVolumeRange;

      zoneVolumeRange = zoneVolumeRange?.copyWith(
        lowerGain: lowerLimit ?? zoneVolumeRange.lowerGain,
        upperGain: upperLimit ?? zoneVolumeRange.upperGain,
        allowMute: allowMuteUnmute ?? zoneVolumeRange.allowMute,
      );

      emit(state.copyWith(zoneVolumeRange: zoneVolumeRange));
    }
  }

  double getLowerGain(String zoneOrSubzoneID) {
    if (hasSubZones) {
      final List<VolumneRangeModel> subZonesVolumeRange = state.subZonesVolumeRange ?? <VolumneRangeModel>[];
      final VolumneRangeModel? subZoneVolumeRange = subZonesVolumeRange.firstWhereOrNull((VolumneRangeModel e) => e.zoneOrSubzoneId == zoneOrSubzoneID);
      if (subZoneVolumeRange != null) return subZoneVolumeRange.lowerGain;
    } else {
      final VolumneRangeModel? zoneVolumeRange = state.zoneVolumeRange;
      if (zoneVolumeRange != null) return zoneVolumeRange.lowerGain;
    }

    return 0;
  }

  double getUpperGain(String zoneOrSubzoneID) {
    if (hasSubZones) {
      final List<VolumneRangeModel> subZonesVolumeRange = state.subZonesVolumeRange ?? <VolumneRangeModel>[];
      final VolumneRangeModel? subZoneVolumeRange = subZonesVolumeRange.firstWhereOrNull((VolumneRangeModel e) => e.zoneOrSubzoneId == zoneOrSubzoneID);
      if (subZoneVolumeRange != null) return subZoneVolumeRange.upperGain;
    } else {
      final VolumneRangeModel? zoneVolumeRange = state.zoneVolumeRange;
      if (zoneVolumeRange != null) return zoneVolumeRange.upperGain;
    }

    return 0;
  }

  bool isAllowMute(String zoneOrSubzoneID) {
    if (hasSubZones) {
      final List<VolumneRangeModel> subZonesVolumeRange = state.subZonesVolumeRange ?? <VolumneRangeModel>[];
      final VolumneRangeModel? subZoneVolumeRange = subZonesVolumeRange.firstWhereOrNull((VolumneRangeModel e) => e.zoneOrSubzoneId == zoneOrSubzoneID);
      if (subZoneVolumeRange != null) return subZoneVolumeRange.allowMute;
    } else {
      final VolumneRangeModel? zoneVolumeRange = state.zoneVolumeRange;
      if (zoneVolumeRange != null) return zoneVolumeRange.allowMute;
    }
    return false;
  }
}
