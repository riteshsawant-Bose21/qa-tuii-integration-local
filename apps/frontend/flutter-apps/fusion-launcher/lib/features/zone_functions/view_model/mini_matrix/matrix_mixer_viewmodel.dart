import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:meta/meta.dart';

import '../../../projects/view_model/block_data/block_data_viewmodel.dart';

part 'matrix_mixer_viewmodel_state.dart';

class MatrixMixerViewModel extends Cubit<MatrixMixerState> {
  MatrixMixerViewModel() : super(MatrixMixerInitial());

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

  /// Applies incoming block-data (e.g. `{gain: [...], mute: [...], input_mute: [...], out_mute: ...}`)
  /// to the local project model so BlocBuilder-driven UIs rebuild.
  void _applyBlockDataToProject({
    required String functionId,
    required Map<String, dynamic> data,
  }) {
    try {
      final ProjectViewModel projectVM = serviceLocator<ProjectViewModel>();
      final ZoneFunctions? function = projectVM.getFunctionById(functionId: functionId);
      if (function == null || function.matrixMixer == null) return;

      final List<MatrixSettings> settings = function.matrixMixer!.settings;
      if (settings.isEmpty) return;

      data.forEach((String key, dynamic value) {
        // Handle per-source array parameters
        if (value is List<dynamic>) {
          for (int i = 0; i < value.length && i < settings.length; i++) {
            if (value[i] == null) continue;
            final MatrixSettings current = settings[i];
            if (current is! MonoMatrixSettings) continue;
            MonoMatrixSettings updated = current;

            if (key == 'gain') {
              final double newLevel = (value[i] as num).toDouble();
              if (current.mixLevel != newLevel) {
                updated = updated.copyWith(mixLevel: newLevel);
              }
            } else if (key == 'mute') {
              final bool newMuted = value[i] != true; // mute=true means NOT selected
              if (current.isSelected != newMuted) {
                updated = updated.copyWith(isSelected: newMuted);
              }
            } else if (key == 'input_mute') {
              final bool newInputMute = value[i] == true;
              if (current.inputMute != newInputMute) {
                updated = updated.copyWith(inputMute: newInputMute);
              }
            }

            if (updated != current) {
              projectVM.updateMatrixSettings(
                matrixSettings: updated,
                functionId: functionId,
              );
            }
          }
        }

        // Handle scalar out_mute for the whole mixer
        if (key == 'out_mute' && function.matrixMixer is MonoMatrixMixer) {
          final bool newOutMuted = value == true || (value is List && value.isNotEmpty && value[0] == true);
          final MonoMatrixMixer mono = function.matrixMixer! as MonoMatrixMixer;
          if (mono.outMuted != newOutMuted) {
            projectVM.updateMatrixMixer(
              matrixMixer: mono.copyWith(outMuted: newOutMuted),
              functionId: functionId,
            );
          }
        }
      });
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'Error applying matrix block data to project: $e',
      );
    }
  }

  // ── public API ─────────────────────────────────────────────────────────────

  Future<void> updateCrosspointLevel({
    required ZoneFunctions function,
    required String sourceId,
    required MonoMatrixSettings currentSettings,
    required double newLevel,
  }) async {
    try {
      if (serviceLocator<ProjectViewModel>().isInControlMode && serviceLocator<ProjectViewModel>().virtualIP != null) {
        final int index = function.sourceIndex != null && function.sourceIndex!.containsKey(sourceId) ? function.sourceIndex![sourceId]! : 0;

        serviceLocator<BlockDataViewmodel>().updateBlockParameterViaAPi(
          blockId: function.id,
          parameter: 'gain',
          dimension: index,
          value: newLevel,
        );
      }
      serviceLocator<ProjectViewModel>().updateMatrixSettings(
        matrixSettings: currentSettings.copyWith(mixLevel: newLevel),
        functionId: function.id,
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating crosspoint level: $e");
    }
  }

  Future<void> updateCrosspointMute({
    required ZoneFunctions function,
    required String sourceId,
    required MonoMatrixSettings currentSettings,
    required bool isSelected,
  }) async {
    try {
      if (serviceLocator<ProjectViewModel>().isInControlMode && serviceLocator<ProjectViewModel>().virtualIP != null) {
        final int index = function.sourceIndex != null && function.sourceIndex!.containsKey(sourceId) ? function.sourceIndex![sourceId]! : 0;

        serviceLocator<BlockDataViewmodel>().updateBlockParameterViaAPi(
          blockId: function.id,
          parameter: 'mute',
          dimension: index,
          value: !isSelected, // mute = !isSelected
        );
      }
      serviceLocator<ProjectViewModel>().updateMatrixSettings(
        matrixSettings: currentSettings.copyWith(isSelected: isSelected),
        functionId: function.id,
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating crosspoint mute: $e");
    }
  }

  Future<void> updateInputMute({
    required ZoneFunctions function,
    required String sourceId,
    required MonoMatrixSettings currentSettings,
    required bool isMuted,
  }) async {
    try {
      if (serviceLocator<ProjectViewModel>().isInControlMode && serviceLocator<ProjectViewModel>().virtualIP != null) {
        final int index = function.sourceIndex != null && function.sourceIndex!.containsKey(sourceId) ? function.sourceIndex![sourceId]! : 0;

        serviceLocator<BlockDataViewmodel>().updateBlockParameterViaAPi(
          blockId: function.id,
          parameter: 'input_mute',
          dimension: index,
          value: isMuted,
        );
      }
      serviceLocator<ProjectViewModel>().updateMatrixSettings(
        matrixSettings: currentSettings.copyWith(inputMute: isMuted),
        functionId: function.id,
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating input mute: $e");
    }
  }

  Future<void> updateOutputMute({
    required ZoneFunctions function,
    required bool isMuted,
  }) async {
    try {
      if (function.matrixMixer is! MonoMatrixMixer) return;
      final MonoMatrixMixer mono = function.matrixMixer! as MonoMatrixMixer;

      if (serviceLocator<ProjectViewModel>().isInControlMode && serviceLocator<ProjectViewModel>().virtualIP != null) {
        serviceLocator<BlockDataViewmodel>().updateBlockParameterViaAPi(
          blockId: function.id,
          parameter: 'out_mute',
          dimension: 0,
          value: isMuted,
        );
      }
      serviceLocator<ProjectViewModel>().updateMatrixMixer(
        matrixMixer: mono.copyWith(outMuted: isMuted),
        functionId: function.id,
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating output mute: $e");
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

      final Map<String, dynamic>? data = await serviceLocator<BlockDataViewmodel>().getBlockData(blockId: function.id);
      if (data == null) return;

      _applyBlockDataToProject(functionId: function.id, data: data);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Error updating matrix settings from server params: $e");
    }
  }

  @override
  Future<void> close() {
    unsubscribeFromBlockData();
    return super.close();
  }
}
