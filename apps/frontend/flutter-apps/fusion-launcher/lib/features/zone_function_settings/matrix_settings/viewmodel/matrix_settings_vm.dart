import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart' show ListExtension;
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../models/models.dart';

part 'matrix_settings_vm_state.dart';

class SourceMatrixAdditionalSettingsViewmodel extends Cubit<SourceMatrixSettingsVmState> {
  SourceMatrixAdditionalSettingsViewmodel() : super(const SourceMatrixSettingsVmState());

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();

  bool hasSubZones = false;

  void init({required String zoneID}) {
    SourceMatrixSettingsVmState updatedState = state.copyWith(
      priorityAdditionalSettingsModel: const <PriorityAdditionalSettingsModel>[
        // INITIALIZE with 2 models as we have 2 priority behaviors, if more are added in the future, this needs to be updated
        PriorityAdditionalSettingsModel(),
        PriorityAdditionalSettingsModel(),
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

  double getThresholdValue(int index) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...state.priorityAdditionalSettingsModel,
    ];
    if (index < priorityAdditionalSettingsModel.length) {
      return priorityAdditionalSettingsModel[index].thresholdValue ?? 0;
    }
    return 0;
  }

  double getReductionValue(int index) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...state.priorityAdditionalSettingsModel,
    ];
    if (index < priorityAdditionalSettingsModel.length) {
      return priorityAdditionalSettingsModel[index].reductionValue ?? 0;
    }
    return 0;
  }

  bool isPriorityStateActive(int index) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...state.priorityAdditionalSettingsModel,
    ];
    if (index < priorityAdditionalSettingsModel.length) {
      return priorityAdditionalSettingsModel[index].isStateActive;
    }
    return false;
  }

  bool get isAssignToControllersEnabled => state.assignToControllers;
  void toggleAssignToControllers() {
    final bool newValue = !isAssignToControllersEnabled;
    final SourceMatrixSettingsVmState updated = state.copyWith(assignToControllers: newValue);
    emit(updated);
  }

  bool enableBehaviorSettingsFields(int index) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...state.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      final AdditionalSettingPriorityBehavior? priorityBehavior = priorityAdditionalSettingsModel[index].priorityBehavior;
      return priorityBehavior != null && priorityBehavior == AdditionalSettingPriorityBehavior.custom;
    }

    return false;
  }

  double? getDepth(int index) => state.priorityAdditionalSettingsModel[index].depth;
  double? getAttack(int index) => state.priorityAdditionalSettingsModel[index].attack;
  double? getHold(int index) => state.priorityAdditionalSettingsModel[index].hold;
  double? getRelease(int index) => state.priorityAdditionalSettingsModel[index].release;
  AdditionalSettingPriorityBehavior? getPriorityBehavior(int index) => state.priorityAdditionalSettingsModel[index].priorityBehavior;

  AdditionalSettingsPriorityControlType? getPriorityControlType(int index) => state.priorityAdditionalSettingsModel[index].priorityControlType;

  void setPriorityControlType(int index, AdditionalSettingsPriorityControlType? priorityControlType) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...state.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      priorityAdditionalSettingsModel[index] = priorityAdditionalSettingsModel[index].copyWith(priorityControlType: priorityControlType);
      emit(
        state.copyWith(
          priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
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

  void updatePriorityProperties({
    required String zoneOrSubzoneId,
    required int index,
    bool? isStateActive,
    double? thresholdValue,
    double? reductionValue,
    double? depthValue,
    double? attackValue,
    double? holdValue,
    double? releaseValue,
    AdditionalSettingPriorityBehavior? priorityBehavior,
    AdditionalSettingsPriorityControlType? priorityControlType,
  }) {
    final List<PriorityAdditionalSettingsModel> priorityAdditionalSettingsModel = <PriorityAdditionalSettingsModel>[
      ...state.priorityAdditionalSettingsModel,
    ];

    if (index < priorityAdditionalSettingsModel.length) {
      final PriorityAdditionalSettingsModel model = priorityAdditionalSettingsModel[index];
      priorityAdditionalSettingsModel[index] = model.copyWith(
        isStateActive: isStateActive,
        thresholdValue: thresholdValue,
        reductionValue: reductionValue,
        depth: depthValue,
        attack: attackValue,
        hold: holdValue,
        release: releaseValue,
        priorityBehavior: priorityBehavior,
        priorityControlType: priorityControlType,
      );

      emit(
        state.copyWith(
          priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
        ),
      );
    }
  }
}
