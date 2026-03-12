import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../models/meter_data.dart';

part 'meter_data_vm_state.dart';

/// Describes why telemetry is currently inactive.
enum MeterInactiveReason { notStarted, controlModeOff, projectClosed }

// ─────────────────────────────────────────────────────────────────────────────
// CUBIT  —  register as a singleton in service_locator.dart
//
//   serviceLocator.registerLazySingleton<MeterDataCubit>(() => MeterDataCubit());
//
// Provide it at the app root so every widget can reach it:
//
//   BlocProvider<MeterDataCubit>.value(
//     value: serviceLocator<MeterDataCubit>(),
//     child: MaterialApp(...),
//   )
// ─────────────────────────────────────────────────────────────────────────────

class MeterDataViewModel extends Cubit<MeterDataState> {
  MeterDataViewModel() : super(const MeterDataState()) {
    _attachControlModeListener();
  }

  // ── internals ──────────────────────────────────────────────────────────────

  StreamSubscription<ResponseCallback<dynamic>>? _telemetrySubscription;

  /// Listens to [ProjectViewModel] state changes and reacts to
  /// [isInControlMode] flipping on/off.
  StreamSubscription<dynamic>? _controlModeSubscription;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _controlModeSubscription?.cancel();
    _cancelTelemetry();
    return super.close();
  }

  // ── control-mode wiring ────────────────────────────────────────────────────

  /// Called once from the constructor.
  /// Taps into the [ProjectViewModel] Cubit stream and reacts whenever
  /// [isInControlMode] changes value — no manual start/stop calls needed.
  void _attachControlModeListener() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();

    // Seed: react to whatever the current state already is.
    _onControlModeChanged(vm.isInControlMode);

    // Watch ONLY isInControlMode — map extracts the field, distinct() ensures
    // we only fire when it actually changes, ignoring all other state updates.
    _controlModeSubscription = vm.stream.map((ProjectViewModelState s) => vm.isInControlMode).distinct().listen(_onControlModeChanged);
  }

  void _onControlModeChanged(bool isActive) {
    if (isActive) {
      startTelemetry();
    } else {
      _stopTelemetry(reason: MeterInactiveReason.controlModeOff);
    }
  }

  // ── public API ─────────────────────────────────────────────────────────────

  /// Called by the project page when a project is opened / switched.
  /// The control-mode stream listener handles connecting automatically,
  /// but call this so the cubit can also re-read the current VIP if needed.
  void onProjectOpened() {
    // The _attachControlModeListener seed call already handles the initial
    // isInControlMode value, so nothing extra is needed here unless you
    // need to refresh the VIP / reinitialise the network client.
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (vm.isInControlMode) {
      startTelemetry();
    }
  }

  /// Call this when a project page is closed / cloned.
  /// Regardless of control-mode state the connection is torn down.
  void onProjectClosed() {
    _stopTelemetry(reason: MeterInactiveReason.projectClosed);
  }

  // ── private helpers ────────────────────────────────────────────────────────

  Future<void> startTelemetry() async {
    // Guard: do not double-subscribe.
    if (_telemetrySubscription != null) return;
    final String? vip = serviceLocator<ProjectViewModel>().virtualIP;

    if (vip == null) return;

    debugPrint('[MeterDataCubit] Starting telemetry…');

    final FusionNetworkClient client = serviceLocator<FusionNetworkClient>();

    await client.connect(vip: vip);

    _telemetrySubscription = client.responseMessages.listen(
      (ResponseCallback<dynamic> message) {
        try {
          final MeterPacket packet = MeterPacket.fromMap(message.data as Map<String, dynamic>);
          final Map<String, MeterPacket> updatedPackets = Map<String, MeterPacket>.from(state.packets)..[packet.name] = packet;

          // Flatten all meter values into a single map for easy access.
          final Map<String, MeterBlock> updatedMeterValues = <String, MeterBlock>{};
          //convert packet.values from List<MeterBlock> to Map<String, MeterBlock> and merge into updatedMeterValues
          for (final MeterBlock block in packet.blocks) {
            updatedMeterValues[block.blockName] = block;
          }

          emit(
            state.copyWith(
              packets: updatedPackets,
              meterValues: updatedMeterValues, // Pass the flat map to state
              isConnected: true,
              clearInactiveReason: true,
            ),
          );
        } catch (e) {
          debugPrint('[MeterDataCubit] Parse error: $e');
        }
      },
      onError: (dynamic error) {
        debugPrint('[MeterDataCubit] Stream error: $error');
        // Reconnect or surface error state here if needed.
      },
      onDone: () {
        debugPrint('[MeterDataCubit] Stream closed by server.');
        _cancelTelemetry();
      },
      cancelOnError: false,
    );

    emit(state.copyWith(isConnected: true, clearInactiveReason: true));
  }

  void _stopTelemetry({required MeterInactiveReason reason}) {
    debugPrint('[MeterDataCubit] Stopping telemetry — reason: $reason');
    _cancelTelemetry();
    emit(
      MeterDataState(
        packets: const <String, MeterPacket>{}, // clear stale data
        isConnected: false,
        inactiveReason: reason,
      ),
    );
  }

  void _cancelTelemetry() {
    _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
  }

  Future<Map<String, dynamic>?> getBlockData({required String blockId}) async {
    try {
      final ResponseCallback<Map<String, dynamic>?> response = await serviceLocator<FusionNetworkClient>().get(
        api: FusionApiEndpoint.fusionValue,
        isSecure: false,
        baseUrlToOverride: serviceLocator<ProjectViewModel>().virtualIP,
        urlParameters: <String, dynamic>{
          "key": "settings.audio.$blockId",
        },
      );
      if (response.success && response.data != null) {
        try {
          final Map<String, dynamic> blockData = response.data!;
          if (blockData["exists"]) {
            return blockData["value"]["audio"] as Map<String, dynamic>;
          }
        } catch (ex) {
          FusionLogger.log(tag: LogTag.dspConfig, message: "Error parsing block data for $blockId: $ex");
        }
      }
      return null;
    } catch (ex) {
      FusionLogger.log(tag: LogTag.dspConfig, message: "Error fetching block data for $blockId: $ex");
      return null;
    }
  }

  Future<void> updateBlockParameter({required String blockId, required String parameter, required dynamic value, int? dimension}) async {
    try {
      final Map<String, dynamic> payload =
          dimension == null
              ? <String, dynamic>{
                "settings": <String, dynamic>{
                  "audio": <String, dynamic>{
                    blockId: <String, dynamic>{parameter: value},
                  },
                },
              }
              : <String, dynamic>{
                "value": value,
              };
      final ResponseCallback<dynamic> response = await serviceLocator<FusionNetworkClient>().patch(
        api: FusionApiEndpoint.fusionValue,
        isSecure: false,
        urlParameters:
            dimension != null
                ? <String, dynamic>{
                  "key": "settings.audio.$blockId.$parameter[$dimension]",
                }
                : null,
        baseUrlToOverride: serviceLocator<ProjectViewModel>().virtualIP,
        data: payload,
      );
      if (!response.success) {
        FusionLogger.log(tag: LogTag.dspConfig, message: "Failed to update block parameter for $blockId.$parameter: ${response.message}");
      }
    } catch (ex) {
      FusionLogger.log(tag: LogTag.dspConfig, message: "Error updating block parameter for $blockId.$parameter: $ex");
    }
  }
}
