import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart' show ListExtension;
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/service_locator.dart';

part 'additional_settings_viewmodel_state.dart';

class ZoneFunctionAdditionalSettingsViewModel extends Cubit<ZoneFunctionAdditionalSettingsViewmodelState> {
  ZoneFunctionAdditionalSettingsViewModel()
    : super(
        const ZoneFunctionAdditionalSettingsViewmodelState(
          sourceSelectAdditionalSettingsModel: SourceSelectAdditionalSettingsModel(
            priorityAdditionalSettingsModel: <PriorityAdditionalSettingsModel>[
              // Keep it only two for now
              PriorityAdditionalSettingsModel(),
              PriorityAdditionalSettingsModel(),
            ],
          ),
        ),
      );

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();

  bool hasSubZones = false;

  void init({required ZoneFunctionsType zoneFunctionsType, required String zoneID}) {
    emit(state.copyWith(zoneFunctionsType: zoneFunctionsType));

    // ===============================================================================================
    // ZONE or SUBZONE volume range initialization
    // ===============================================================================================
    final List<SubZone> subZones = projectViewModel.getSubZonesForZone(parentZoneId: zoneID);
    if (subZones.isEmpty) {
      hasSubZones = false;
      final SourceSelectAdditionalSettingsModel? updated = state.sourceSelectAdditionalSettingsModel?.copyWith(
        zoneVolumeRange: VolumneRangeModel(zoneOrSubzoneId: zoneID),
      );
      emit(state.copyWith(sourceSelectAdditionalSettingsModel: updated));
    } else {
      hasSubZones = true;
      final List<VolumneRangeModel> subZonesVolumes = subZones.map((SubZone subZone) => VolumneRangeModel(zoneOrSubzoneId: subZone.id)).toList();
      final SourceSelectAdditionalSettingsModel? updated = state.sourceSelectAdditionalSettingsModel?.copyWith(subZonesVolumeRange: subZonesVolumes);
      emit(state.copyWith(sourceSelectAdditionalSettingsModel: updated));
    }
  }

  void updateZoneFunctionsType(ZoneFunctionsType zoneFunctionsType) => emit(state.copyWith(zoneFunctionsType: zoneFunctionsType));

  bool isSourceSelect(String sourceId) => state.sourceSelectAdditionalSettingsModel?.selectedSourcesIds.contains(sourceId) ?? false;

  void toggleSourceSelect(String sourceId) {
    final List<String> selectedSourcesIds = <String>[...state.sourceSelectAdditionalSettingsModel?.selectedSourcesIds ?? <String>[]];
    if (selectedSourcesIds.contains(sourceId)) {
      selectedSourcesIds.remove(sourceId);
    } else {
      selectedSourcesIds.add(sourceId);
    }

    emit(
      state.copyWith(
        sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
          selectedSourcesIds: selectedSourcesIds,
        ),
      ),
    );
  }

  bool get useOff => state.sourceSelectAdditionalSettingsModel?.useOff ?? false;
  void toggleUseOff() {
    emit(
      state.copyWith(
        sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
          useOff: !useOff,
        ),
      ),
    );
  }

  bool get useCrossfade => state.sourceSelectAdditionalSettingsModel?.useCrossfade ?? false;
  void toggleUseCrossfade() {
    emit(
      state.copyWith(
        sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
          useCrossfade: !useCrossfade,
        ),
      ),
    );
  }

  AdditionalSettingPriorityBehavior? getPriorityBehavior(int index) =>
      state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel?[index].priorityBehavior;

  void setPriorityBehavior(int index, AdditionalSettingPriorityBehavior? priorityBehavior) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      final bool shouldResetFields = priorityBehavior != AdditionalSettingPriorityBehavior.custom;
      priorityAdditionalSettingsModel[index] = priorityAdditionalSettingsModel[index].copyWith(
        priorityBehavior: priorityBehavior,
        depth: shouldResetFields ? 0.0 : null,
        attack: shouldResetFields ? 0.0 : null,
        hold: shouldResetFields ? 0.0 : null,
        release: shouldResetFields ? 0.0 : null,
      );

      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
          ),
        ),
      );
    }
  }

  double getThresholdValue(int index) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];
    if (index < priorityAdditionalSettingsModel.length) {
      return priorityAdditionalSettingsModel[index].thresholdValue ?? 0;
    }
    return 0;
  }

  double getReductionValue(int index) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];
    if (index < priorityAdditionalSettingsModel.length) {
      return priorityAdditionalSettingsModel[index].reductionValue ?? 0;
    }
    return 0;
  }

  bool isPriorityStateActive(int index) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];
    if (index < priorityAdditionalSettingsModel.length) {
      return priorityAdditionalSettingsModel[index].isStateActive;
    }
    return false;
  }

  bool get isAssignToControllersEnabled => state.sourceSelectAdditionalSettingsModel?.assignToControllers ?? false;
  void toggleAssignToControllers() {
    final bool newValue = !isAssignToControllersEnabled;
    final SourceSelectAdditionalSettingsModel? updated = state.sourceSelectAdditionalSettingsModel?.copyWith(assignToControllers: newValue);
    emit(state.copyWith(sourceSelectAdditionalSettingsModel: updated));
  }

  bool isFieldsEnabled(int index) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      final AdditionalSettingPriorityBehavior? priorityBehavior = priorityAdditionalSettingsModel[index].priorityBehavior;
      return priorityBehavior != null && priorityBehavior == AdditionalSettingPriorityBehavior.custom;
    }

    return false;
  }

  double? getDepth(int index) => state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel?[index].depth;
  void setDepth(int index, double? depth) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      priorityAdditionalSettingsModel[index] = priorityAdditionalSettingsModel[index].copyWith(depth: depth);
      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
          ),
        ),
      );
    }
  }

  double? getAttack(int index) => state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel?[index].attack;
  void setAttack(int index, double? attack) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      priorityAdditionalSettingsModel[index] = priorityAdditionalSettingsModel[index].copyWith(attack: attack);
      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
          ),
        ),
      );
    }
  }

  double? getHold(int index) => state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel?[index].hold;
  void setHold(int index, double? hold) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      priorityAdditionalSettingsModel[index] = priorityAdditionalSettingsModel[index].copyWith(hold: hold);
      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
          ),
        ),
      );
    }
  }

  double? getRelease(int index) => state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel?[index].release;
  void setRelease(int index, double? release) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      priorityAdditionalSettingsModel[index] = priorityAdditionalSettingsModel[index].copyWith(release: release);
      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
          ),
        ),
      );
    }
  }

  AdditionalSettingsPriorityControlType? getPriorityControlType(int index) =>
      state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel?[index].priorityControlType;

  void setPriorityControlType(int index, AdditionalSettingsPriorityControlType? priorityControlType) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      priorityAdditionalSettingsModel[index] = priorityAdditionalSettingsModel[index].copyWith(priorityControlType: priorityControlType);
      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
          ),
        ),
      );
    }
  }

  bool isPriorityControlTypePTT(int index) => getPriorityControlType(index) == AdditionalSettingsPriorityControlType.pttControler;
  bool isPriorityControlTypeThreshold(int index) => getPriorityControlType(index) == AdditionalSettingsPriorityControlType.threshold;

  // ZONE AND SUBZONES related methods
  void updateZoneProperties({
    required String zoneOrSubzoneId,
    double? upperLimit,
    double? lowerLimit,
    bool? allowMuteUnmute,
  }) {
    if (hasSubZones) {
      final List<VolumneRangeModel> subZonesVolumeRange = state.sourceSelectAdditionalSettingsModel?.subZonesVolumeRange ?? <VolumneRangeModel>[];
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

      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            subZonesVolumeRange: updatedSubZonesVolumeRange,
          ),
        ),
      );
    } else {
      VolumneRangeModel? zoneVolumeRange = state.sourceSelectAdditionalSettingsModel?.zoneVolumeRange;

      zoneVolumeRange = zoneVolumeRange?.copyWith(
        lowerGain: lowerLimit ?? zoneVolumeRange.lowerGain,
        upperGain: upperLimit ?? zoneVolumeRange.upperGain,
        allowMute: allowMuteUnmute ?? zoneVolumeRange.allowMute,
      );

      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            zoneVolumeRange: zoneVolumeRange,
          ),
        ),
      );
    }
  }

  void updatePriorityProperties({
    required String zoneOrSubzoneId,
    required int index,
    bool? isStateActive,
    double? thresholdValue,
    double? reductionValue,
  }) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...?state.sourceSelectAdditionalSettingsModel?.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      final PriorityAdditionalSettingsModel model = priorityAdditionalSettingsModel[index];
      priorityAdditionalSettingsModel[index] = model.copyWith(
        isStateActive: isStateActive,
        thresholdValue: thresholdValue,
        reductionValue: reductionValue,
      );

      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
          ),
        ),
      );
    }
  }

  double getLowerGain(String zoneOrSubzoneID) {
    if (hasSubZones) {
      final List<VolumneRangeModel> subZonesVolumeRange = state.sourceSelectAdditionalSettingsModel?.subZonesVolumeRange ?? <VolumneRangeModel>[];
      final VolumneRangeModel? subZoneVolumeRange = subZonesVolumeRange.firstWhereOrNull((VolumneRangeModel e) => e.zoneOrSubzoneId == zoneOrSubzoneID);
      if (subZoneVolumeRange != null) return subZoneVolumeRange.lowerGain;
    } else {
      final VolumneRangeModel? zoneVolumeRange = state.sourceSelectAdditionalSettingsModel?.zoneVolumeRange;
      if (zoneVolumeRange != null) return zoneVolumeRange.lowerGain;
    }

    return 0;
  }

  double getUpperGain(String zoneOrSubzoneID) {
    if (hasSubZones) {
      final List<VolumneRangeModel> subZonesVolumeRange = state.sourceSelectAdditionalSettingsModel?.subZonesVolumeRange ?? <VolumneRangeModel>[];
      final VolumneRangeModel? subZoneVolumeRange = subZonesVolumeRange.firstWhereOrNull((VolumneRangeModel e) => e.zoneOrSubzoneId == zoneOrSubzoneID);
      if (subZoneVolumeRange != null) return subZoneVolumeRange.upperGain;
    } else {
      final VolumneRangeModel? zoneVolumeRange = state.sourceSelectAdditionalSettingsModel?.zoneVolumeRange;
      if (zoneVolumeRange != null) return zoneVolumeRange.upperGain;
    }

    return 0;
  }

  bool isAllowMute(String zoneOrSubzoneID) {
    if (hasSubZones) {
      final List<VolumneRangeModel> subZonesVolumeRange = state.sourceSelectAdditionalSettingsModel?.subZonesVolumeRange ?? <VolumneRangeModel>[];
      final VolumneRangeModel? subZoneVolumeRange = subZonesVolumeRange.firstWhereOrNull((VolumneRangeModel e) => e.zoneOrSubzoneId == zoneOrSubzoneID);
      if (subZoneVolumeRange != null) return subZoneVolumeRange.allowMute;
    } else {
      final VolumneRangeModel? zoneVolumeRange = state.sourceSelectAdditionalSettingsModel?.zoneVolumeRange;
      if (zoneVolumeRange != null) return zoneVolumeRange.allowMute;
    }
    return false;
  }
}
