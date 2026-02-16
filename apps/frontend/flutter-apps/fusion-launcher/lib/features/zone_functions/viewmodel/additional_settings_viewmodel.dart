import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

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

  void init({required ZoneFunctionsType zoneFunctionsType}) {
    emit(state.copyWith(zoneFunctionsType: zoneFunctionsType));
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
      priorityAdditionalSettingsModel[index] = priorityAdditionalSettingsModel[index].copyWith(priorityBehavior: priorityBehavior);
      emit(
        state.copyWith(
          sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
            priorityAdditionalSettingsModel: priorityAdditionalSettingsModel,
          ),
        ),
      );
    }
  }

  double get thresholdValue => state.sourceSelectAdditionalSettingsModel?.thresholdValue ?? 0;
  void setThresholdValue(double? thresholdValue) {
    emit(
      state.copyWith(
        sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
          thresholdValue: thresholdValue,
        ),
      ),
    );
  }

  double? get reductionValue => state.sourceSelectAdditionalSettingsModel?.reductionValue;
  void setReductionValue(double? reductionValue) {
    emit(
      state.copyWith(
        sourceSelectAdditionalSettingsModel: state.sourceSelectAdditionalSettingsModel?.copyWith(
          reductionValue: reductionValue,
        ),
      ),
    );
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
}
