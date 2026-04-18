import 'package:bloc/bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/mix_scenes.dart';
import 'package:meta/meta.dart';

import '../../../projects/view_model/block_data/block_data_viewmodel.dart';

part 'source_mix_view_model_state.dart';

class SourceMixViewModel extends Cubit<SourceMixViewModelState> {
  SourceMixViewModel() : super(SourceMixViewModelInitial());

  Future<void> updateGain({
    required ZoneFunctions function,
    required String sourceId,
    required final MixSettings mixSetting,
    required final double gain,
  }) async {
    try {
      if (serviceLocator<ProjectViewModel>().isInControlMode && serviceLocator<ProjectViewModel>().virtualIP != null) {
        final int index = function.sourceIndex != null && function.sourceIndex!.containsKey(sourceId) ? function.sourceIndex![sourceId]! : 1;

        serviceLocator<BlockDataViewmodel>().updateBlockParameter(
          blockId: function.id,
          parameter: 'input_gain',
          dimension: index - 1,
          value: gain,
        );
      } else {
        serviceLocator<ProjectViewModel>().updateMixSettings(
          mixSettings: mixSetting.copyWith(
            gain: gain,
          ),
          functionId: function.id,
        );
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating gain: $e");
    }
  }

  Future<void> updateMuted({
    required ZoneFunctions function,
    required String sourceId,
    required final MixSettings mixSetting,
    required final bool isMuted,
  }) async {
    try {
      if (serviceLocator<ProjectViewModel>().isInControlMode && serviceLocator<ProjectViewModel>().virtualIP != null) {
        final int index = function.sourceIndex != null && function.sourceIndex!.containsKey(sourceId) ? function.sourceIndex![sourceId]! : 1;

        serviceLocator<BlockDataViewmodel>().updateBlockParameter(
          blockId: function.id,
          parameter: 'input_mute',
          dimension: index - 1,
          value: isMuted,
        );
      } else {
        serviceLocator<ProjectViewModel>().updateMixSettings(
          mixSettings: mixSetting.copyWith(
            muted: isMuted,
          ),
          functionId: function.id,
        );
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating muted state: $e");
    }
  }

  Future<void> updateParamsAsPerServer({
    required ZoneFunctions function,
  }) async {
    try {
      final Map<String, dynamic>? data = await serviceLocator<BlockDataViewmodel>().getBlockData(blockId: function.id);
      if (data != null) {
        data.forEach((String key, dynamic value) {
          if (value is List<dynamic>) {
            for (int i = 0; i < value.length; i++) {
              if (value[i] != null) {
                MixSettings? settings = function.mixSettings?[i];
                if (settings == null) {
                  if (key == 'input_gain') {
                    settings = settings?.copyWith(gain: value[i].toDouble());
                  } else if (key == 'input_mute') {
                    settings = settings?.copyWith(muted: value[i] == true);
                  }
                  serviceLocator<ProjectViewModel>().updateMixSettings(
                    mixSettings: settings!,
                    functionId: function.id,
                  );
                }
              }
            }
          }
        });
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating mix settings from server params: $e");
    }
  }
}
