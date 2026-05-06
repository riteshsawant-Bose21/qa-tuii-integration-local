import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../projects/view_model/block_data/block_data_viewmodel.dart';

part 'source_mix_view_model_state.dart';

class SourceMixViewModel extends Cubit<SourceMixViewModelState> {
  SourceMixViewModel() : super(SourceMixViewModelInitial());

  StreamSubscription<Map<String, dynamic>?>? _blockDataSubscription;

  // ── block data subscription ────────────────────────────────────────────────

  /// Subscribes to [BlockDataViewmodel] for live WebSocket updates for the
  /// given function. When block data for [functionId] changes, the local
  /// project model is patched so the UI stays in sync across devices.
  void subscribeToBlockData({required String functionId}) {
    _blockDataSubscription?.cancel();
    final BlockDataViewmodel blockDataVM = serviceLocator<BlockDataViewmodel>();

    _blockDataSubscription = blockDataVM.stream.map((BlockDataState s) => s.allBlockData[functionId]).distinct().listen((Map<String, dynamic>? blockData) {
      if (blockData == null || isClosed) return;
      _applyBlockDataToProject(functionId: functionId, data: blockData);
    });
  }

  /// Unsubscribes from [BlockDataViewmodel].
  void unsubscribeFromBlockData() {
    _blockDataSubscription?.cancel();
    _blockDataSubscription = null;
  }

  /// Applies a block-data map (e.g. `{input_gain: [...], input_mute: [...]}`)
  /// to the local project model so BlocBuilder-driven UIs rebuild.
  void _applyBlockDataToProject({
    required String functionId,
    required Map<String, dynamic> data,
  }) {
    try {
      final ProjectViewModel projectVM = serviceLocator<ProjectViewModel>();
      final ZoneFunctions? function = projectVM.getFunctionById(functionId: functionId);
      if (function == null) return;

      final List<MixSettings>? mixSettings = function.mixSettings;
      if (mixSettings == null || mixSettings.isEmpty) return;

      data.forEach((String key, dynamic value) {
        if (value is! List<dynamic>) return;
        for (int i = 0; i < value.length && i < mixSettings.length; i++) {
          if (value[i] == null) continue;
          final MixSettings current = mixSettings[i];
          MixSettings updated = current;
          if (key == 'input_gain') {
            final double newGain = (value[i] as num).toDouble();
            if (current.gain != newGain) {
              updated = updated.copyWith(gain: newGain);
            }
          } else if (key == 'input_mute') {
            final bool newMuted = value[i] == true;
            if (current.muted != newMuted) {
              updated = updated.copyWith(muted: newMuted);
            }
          }
          if (updated != current) {
            projectVM.updateMixSettings(
              mixSettings: updated,
              functionId: functionId,
            );
          }
        }
      });
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Error applying block data to project: $e',
      );
    }
  }

  // ── public API ─────────────────────────────────────────────────────────────

  Future<void> updateGain({
    required ZoneFunctions function,
    required String sourceId,
    required final MixSettings mixSetting,
    required final double gain,
  }) async {
    try {
      if (serviceLocator<ProjectViewModel>().isInControlMode && serviceLocator<ProjectViewModel>().virtualIP != null) {
        final int index = function.sourceIndex != null && function.sourceIndex!.containsKey(sourceId) ? function.sourceIndex![sourceId]! : 0;

        serviceLocator<BlockDataViewmodel>().updateBlockParameterViaAPi(
          blockId: function.paramName,
          parameter: 'input_gain',
          dimension: index,
          value: gain,
        );
      }
      serviceLocator<ProjectViewModel>().updateMixSettings(
        mixSettings: mixSetting.copyWith(
          gain: gain,
        ),
        functionId: function.id,
      );
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
        final int index = function.sourceIndex != null && function.sourceIndex!.containsKey(sourceId) ? function.sourceIndex![sourceId]! : 0;

        serviceLocator<BlockDataViewmodel>().updateBlockParameterViaAPi(
          blockId: function.paramName,
          parameter: 'input_mute',
          dimension: index,
          value: isMuted,
        );
      }
      serviceLocator<ProjectViewModel>().updateMixSettings(
        mixSettings: mixSetting.copyWith(
          muted: isMuted,
        ),
        functionId: function.id,
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating muted state: $e");
    }
  }

  /// Fetches the latest block data from the server (or WebSocket cache) and
  /// patches the local project model so the UI shows server-authoritative
  /// values on first load.
  Future<void> updateParamsAsPerServer({
    required ZoneFunctions function,
  }) async {
    try {
      if (!serviceLocator<ProjectViewModel>().isInControlMode || serviceLocator<ProjectViewModel>().virtualIP == null) {
        return;
      }

      final Map<String, dynamic>? data = await serviceLocator<BlockDataViewmodel>().getBlockData(blockId: function.paramName);
      if (data == null) return;

      final List<MixSettings>? mixSettings = function.mixSettings;
      if (mixSettings == null || mixSettings.isEmpty) return;

      data.forEach((String key, dynamic value) {
        if (value is! List<dynamic>) return;
        for (int i = 0; i < value.length && i < mixSettings.length; i++) {
          if (value[i] == null) continue;
          final MixSettings current = mixSettings[i];
          MixSettings updated = current;
          if (key == 'input_gain') {
            updated = updated.copyWith(gain: (value[i] as num).toDouble());
          } else if (key == 'input_mute') {
            updated = updated.copyWith(muted: value[i] == true);
          }
          if (updated != current) {
            serviceLocator<ProjectViewModel>().updateMixSettings(
              mixSettings: updated,
              functionId: function.id,
            );
          }
        }
      });
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating mix settings from server params: $e");
    }
  }

  @override
  Future<void> close() {
    unsubscribeFromBlockData();
    return super.close();
  }
}
