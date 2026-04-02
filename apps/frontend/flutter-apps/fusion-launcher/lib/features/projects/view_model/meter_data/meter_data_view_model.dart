import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../models/meter_data.dart';

part 'meter_data_vm_state.dart';

/// Describes why telemetry is currently inactive.
enum MeterInactiveReason { notStarted, controlModeOff, projectClosed, refreshing }

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

  final FusionNetworkClient networkClient = serviceLocator<FusionNetworkClient>();

  // ── internals ──────────────────────────────────────────────────────────────

  StreamSubscription<ResponseCallback<dynamic>>? _telemetrySubscription;

  /// Listens to [ProjectViewModel] state changes and reacts to
  /// [isInControlMode] flipping on/off.
  StreamSubscription<dynamic>? _controlModeSubscription;

  /// Timer used for auto-reconnect with exponential backoff.
  Timer? _reconnectTimer;

  /// Current reconnect delay — doubles after each failed attempt, resets on
  /// a successful connection.
  Duration _reconnectDelay = const Duration(seconds: 1);

  /// Hard ceiling so the backoff doesn't grow without bound.
  static const Duration _maxReconnectDelay = Duration(seconds: 30);

  /// Whether the last disconnection was intentional (user/control-mode off).
  /// Prevents auto-reconnect from firing after a deliberate stop.
  bool _intentionallyStopped = false;

  /// Number of mounted UI widgets currently observing meter data.
  /// Auto-reconnect only runs while this is > 0.
  int _uiObserverCount = 0;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _controlModeSubscription?.cancel();
    _cancelTelemetry();
    _reconnectTimer?.cancel();
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

  void refreshSubscriber() {
    //disconnect and reconnect to refresh all subscribers with the latest VIP and control mode state
    _stopTelemetry(reason: MeterInactiveReason.refreshing);
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (vm.isInControlMode) {
      startTelemetry();
    }
  }

  // ── public API ─────────────────────────────────────────────────────────────

  /// Called by the project page when a project is opened / switched.
  /// The control-mode stream listener handles connecting automatically,
  /// but call this so the cubit can also re-read the current VIP if needed.
  void onProjectOpened() {
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

  /// Call from a meter widget's [initState] (or equivalent mount point).
  /// While at least one observer is registered, the cubit will auto-reconnect
  /// if the stream drops unexpectedly.
  void registerObserver() {
    _uiObserverCount++;
    debugPrint('[MeterDataCubit] registerObserver — count: $_uiObserverCount');
    if (_uiObserverCount == 1) {
      // First observer just mounted — ensure we are connected.
      final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
      if (vm.isInControlMode && _telemetrySubscription == null) {
        debugPrint('[MeterDataCubit] UI appeared, reconnecting…');
        startTelemetry();
      }
    }
  }

  /// Call from a meter widget's [dispose].
  /// When the count drops to 0 the auto-reconnect timer is cancelled so we
  /// don't waste resources reconnecting when no UI needs the data.
  void unregisterObserver() {
    _uiObserverCount = (_uiObserverCount - 1).clamp(0, _uiObserverCount);
    debugPrint('[MeterDataCubit] unregisterObserver — count: $_uiObserverCount');
    if (_uiObserverCount == 0) {
      // No UI is watching — cancel any pending reconnect.
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }
  }

  /// Whether at least one meter widget is currently mounted.
  bool get hasActiveObservers => _uiObserverCount > 0;

  // ── private helpers ────────────────────────────────────────────────────────

  Future<void> startTelemetry() async {
    // Guard: do not double-subscribe.
    if (_telemetrySubscription != null) return;

    // Cancel any pending reconnect timer — we are connecting now.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _intentionallyStopped = false;

    final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
    if (vip == null) return;

    debugPrint('[MeterDataCubit] Starting telemetry…');

    try {
      await networkClient.connect(vip: vip);
    } catch (e) {
      debugPrint('[MeterDataCubit] Connect failed: $e');
      _scheduleReconnect();
      return;
    }

    _telemetrySubscription = networkClient.responseMessages.listen(
      (ResponseCallback<dynamic> message) {
        try {
          final MeterPacket packet = MeterPacket.fromMap(message.data as Map<String, dynamic>);
          final Map<String, MeterPacket> updatedPackets = Map<String, MeterPacket>.from(state.packets)..[packet.name] = packet;

          // Flatten all meter values into a single map for easy access.
          final Map<String, MeterBlock> updatedMeterValues = <String, MeterBlock>{};
          for (final MeterBlock block in packet.blocks) {
            updatedMeterValues[block.blockName] = block;
          }

          emit(
            state.copyWith(
              packets: updatedPackets,
              meterValues: updatedMeterValues,
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
        _handleUnexpectedDisconnect();
      },
      onDone: () {
        debugPrint('[MeterDataCubit] Stream closed by server.');
        _handleUnexpectedDisconnect();
      },
      cancelOnError: false,
    );

    // Connection succeeded — reset the backoff delay.
    _reconnectDelay = const Duration(seconds: 1);
    emit(state.copyWith(isConnected: true, clearInactiveReason: true));
  }

  /// Called when the stream ends unexpectedly (server closed / error).
  /// Cleans up and schedules an auto-reconnect if control-mode is still on.
  void _handleUnexpectedDisconnect() {
    _cancelTelemetry();
    emit(state.copyWith(isConnected: false));

    if (!_intentionallyStopped) {
      _scheduleReconnect();
    }
  }

  /// Schedules a reconnect attempt with exponential backoff, only if
  /// control-mode is still active.
  void _scheduleReconnect() {
    // Don't stack multiple timers.
    if (_reconnectTimer?.isActive ?? false) return;
    if (isClosed) return;

    // Only reconnect if there is UI actively observing meter data.
    if (!hasActiveObservers) {
      debugPrint('[MeterDataCubit] No active observers — skipping reconnect.');
      return;
    }

    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (!vm.isInControlMode) return;

    debugPrint('[MeterDataCubit] Scheduling reconnect in ${_reconnectDelay.inSeconds}s…');

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (isClosed) return;
      // Exponential backoff: double the delay for the next attempt, capped.
      _reconnectDelay = _reconnectDelay * 2;
      if (_reconnectDelay > _maxReconnectDelay) {
        _reconnectDelay = _maxReconnectDelay;
      }
      startTelemetry();
    });
  }

  /// Intentionally tears down telemetry (user action / control-mode off).
  void _stopTelemetry({required MeterInactiveReason reason}) {
    debugPrint('[MeterDataCubit] Stopping telemetry — reason: $reason');
    _intentionallyStopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectDelay = const Duration(seconds: 1);
    _cancelTelemetry();
    emit(
      MeterDataState(
        packets: const <String, MeterPacket>{},
        isConnected: false,
        inactiveReason: reason,
      ),
    );
  }

  void _cancelTelemetry() async {
    await networkClient.disconnect();
    _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
  }
}
