import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../models/device_system_info.dart';
import '../../models/meter_data.dart';

part 'meter_data_vm_state.dart';

/// Describes why telemetry is currently inactive.
enum MeterInactiveReason { notStarted, controlModeOff, projectClosed, refreshing }

// ─────────────────────────────────────────────────────────────────────────────
// MeterDataViewModel — singleton registered in service_locator.dart
//
// Resilient ZMQ telemetry consumer with:
//  • Heartbeat-based liveness detection (catches silent disconnects)
//  • Exponential-backoff auto-reconnect
//  • App lifecycle awareness (reconnects on resume from background)
//  • Observer-gated resource management (no reconnect when no UI watches)
// ─────────────────────────────────────────────────────────────────────────────

class MeterDataViewModel extends Cubit<MeterDataState> with WidgetsBindingObserver {
  MeterDataViewModel() : super(const MeterDataState()) {
    WidgetsBinding.instance.addObserver(this);
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
  /// a successful data reception.
  Duration _reconnectDelay = const Duration(seconds: 2);

  /// Hard ceiling so the backoff doesn't grow without bound.
  static const Duration _maxReconnectDelay = Duration(seconds: 30);

  /// Whether the last disconnection was intentional (user/control-mode off).
  /// Prevents auto-reconnect from firing after a deliberate stop.
  bool _intentionallyStopped = false;

  /// Number of mounted UI widgets currently observing meter data.
  /// Auto-reconnect only runs while this is > 0.
  int _uiObserverCount = 0;

  /// Periodic timer that checks whether we've received any data recently.
  /// If not, it treats the connection as stale and forces a reconnect.
  Timer? _heartbeatTimer;

  /// How often the heartbeat check fires.
  static const Duration _heartbeatInterval = Duration(seconds: 8);

  /// If no data arrives within this window the connection is considered stale.
  static const Duration _staleThreshold = Duration(seconds: 15);

  /// Timestamp of the last successfully received data frame.
  DateTime? _lastDataReceivedAt;

  /// Guards against overlapping connect/disconnect cycles.
  bool _isConnecting = false;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _controlModeSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _cancelTelemetry();
    return super.close();
  }

  // ── app lifecycle ──────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('[MeterData] App resumed — checking connection…');
        _onAppResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Stop the heartbeat while backgrounded to save resources.
        _heartbeatTimer?.cancel();
        _heartbeatTimer = null;
    }
  }

  /// Called when the app returns to the foreground. Forces a fresh connection
  /// check because ZMQ sockets often die silently during background.
  void _onAppResumed() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (!vm.isInControlMode || !hasActiveObservers) return;

    // Force a reconnect — the old socket is almost certainly stale after
    // the app was backgrounded.
    _forceReconnect();
  }

  // ── control-mode wiring ────────────────────────────────────────────────────

  void _attachControlModeListener() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();

    // Seed: react to whatever the current state already is.
    _onControlModeChanged(vm.isInControlMode);

    _controlModeSubscription = vm.stream.map((ProjectViewModelState s) => vm.isInControlMode).distinct().listen(_onControlModeChanged);
  }

  void _onControlModeChanged(bool isActive) {
    if (isActive) {
      startTelemetry();
    } else {
      stopTelemetry(reason: MeterInactiveReason.controlModeOff);
    }
  }

  void refreshSubscriber() {
    stopTelemetry(reason: MeterInactiveReason.refreshing);
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (vm.isInControlMode) {
      startTelemetry();
    }
  }

  // ── public API ─────────────────────────────────────────────────────────────

  void onProjectOpened() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (vm.isInControlMode) {
      startTelemetry();
    }
  }

  void onProjectClosed() {
    stopTelemetry(reason: MeterInactiveReason.projectClosed);
  }

  void registerObserver() {
    _uiObserverCount++;
    debugPrint('[MeterData] registerObserver — count: $_uiObserverCount');
    if (_uiObserverCount == 1) {
      final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
      if (vm.isInControlMode && _telemetrySubscription == null) {
        debugPrint('[MeterData] First observer mounted — connecting…');
        startTelemetry();
      }
    }
  }

  void unregisterObserver() {
    _uiObserverCount = (_uiObserverCount - 1).clamp(0, _uiObserverCount);
    debugPrint('[MeterData] unregisterObserver — count: $_uiObserverCount');
    if (_uiObserverCount == 0) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    }
  }

  bool get hasActiveObservers => _uiObserverCount > 0;

  // ── connection ─────────────────────────────────────────────────────────────

  Future<void> startTelemetry() async {
    // Guard: do not double-subscribe or overlap with an in-flight connect.
    if (_telemetrySubscription != null || _isConnecting) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _intentionallyStopped = false;
    _isConnecting = true;

    final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
    if (vip == null) {
      _isConnecting = false;
      return;
    }

    debugPrint('[MeterData] Starting telemetry to $vip…');

    try {
      await networkClient.connect(vip: vip);
    } catch (e) {
      debugPrint('[MeterData] Connect failed: $e');
      _isConnecting = false;
      _scheduleReconnect();
      return;
    }

    _lastDataReceivedAt = DateTime.now();

    _telemetrySubscription = networkClient.responseMessages.listen(
      _onDataReceived,
      onError: (dynamic error) {
        debugPrint('[MeterData] Stream error: $error');
        _handleUnexpectedDisconnect();
      },
      onDone: () {
        debugPrint('[MeterData] Stream closed by server.');
        _handleUnexpectedDisconnect();
      },
      cancelOnError: false,
    );

    // Reset backoff on successful connection.
    _reconnectDelay = const Duration(seconds: 2);
    _isConnecting = false;

    emit(state.copyWith(isConnected: true, clearInactiveReason: true));

    // Start the heartbeat checker to detect silent disconnects.
    _startHeartbeat();
  }

  void _onDataReceived(ResponseCallback<dynamic> message) {
    _lastDataReceivedAt = DateTime.now();

    // If we were in a "disconnected" state, mark as reconnected.
    if (!state.isConnected && !isClosed) {
      emit(state.copyWith(isConnected: true, clearInactiveReason: true));
    }

    try {
      final MeterPacket packet = MeterPacket.fromMap(
        message.data as Map<String, dynamic>,
      );

      final Map<String, MeterPacket> updatedPackets = Map<String, MeterPacket>.from(state.packets)..[packet.name] = packet;

      final Map<String, MeterBlock> updatedMeterValues = Map<String, MeterBlock>.from(state.meterValues ?? <String, MeterBlock>{});
      for (final MeterBlock block in packet.blocks) {
        updatedMeterValues[block.blockName] = block;
      }

      // Extract per-device system info from fusion_system_monitor packets.
      Map<String, DeviceSystemInfo>? updatedSystemInfo;
      if (packet.name == 'fusion_system_monitor' && packet.deviceId.isNotEmpty) {
        updatedSystemInfo = Map<String, DeviceSystemInfo>.from(state.deviceSystemInfo);
        updatedSystemInfo[packet.deviceId] = _parseSystemInfo(packet);
      }

      emit(
        state.copyWith(
          packets: updatedPackets,
          meterValues: updatedMeterValues,
          deviceSystemInfo: updatedSystemInfo,
          isConnected: true,
          clearInactiveReason: true,
        ),
      );
    } catch (e) {
      debugPrint('[MeterData] Parse error: $e');
    }
  }

  /// Extracts [DeviceSystemInfo] from a `fusion_system_monitor` [MeterPacket].
  DeviceSystemInfo _parseSystemInfo(MeterPacket packet) {
    double emmc = 0;
    double ram = 0;
    double temperature = 0;
    double usbStorage = 0;

    for (final MeterBlock block in packet.blocks) {
      if (block.blockName != 'system_info') continue;
      final double val = block.value.isNotEmpty ? block.value.first : 0;
      switch (block.meterName) {
        case 'emmc':
          emmc = val;
        case 'ram':
          ram = val;
        case 'temperature':
          temperature = val;
        case 'usb_storage':
          usbStorage = val;
      }
    }

    return DeviceSystemInfo(
      emmc: emmc,
      ram: ram,
      temperature: temperature,
      usbStorage: usbStorage,
      updatedAt: DateTime.now(),
    );
  }

  // ── heartbeat (stale-connection detection) ─────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _checkLiveness();
    });
  }

  /// Checks whether data has been received within [_staleThreshold].
  /// If not, the connection is considered silently dead and is torn down
  /// + reconnected.
  void _checkLiveness() {
    if (_intentionallyStopped || isClosed) return;
    if (_lastDataReceivedAt == null) return;

    final Duration elapsed = DateTime.now().difference(_lastDataReceivedAt!);
    if (elapsed > _staleThreshold) {
      debugPrint(
        '[MeterData] No data for ${elapsed.inSeconds}s — treating as stale, reconnecting…',
      );
      _forceReconnect();
    }
  }

  // ── reconnection ──────────────────────────────────────────────────────────

  /// Tears down the current connection unconditionally and starts a fresh one.
  void _forceReconnect() {
    _cancelTelemetry();
    if (!isClosed) {
      emit(state.copyWith(isConnected: false));
    }
    // Small delay to let the old socket fully release.
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(milliseconds: 500), () {
      if (isClosed) return;
      startTelemetry();
    });
  }

  void _handleUnexpectedDisconnect() {
    _cancelTelemetry();
    if (!isClosed) {
      emit(state.copyWith(isConnected: false));
    }

    if (!_intentionallyStopped) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (isClosed) return;

    if (!hasActiveObservers) {
      debugPrint('[MeterData] No active observers — skipping reconnect.');
      return;
    }

    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (!vm.isInControlMode) return;

    debugPrint(
      '[MeterData] Scheduling reconnect in ${_reconnectDelay.inSeconds}s…',
    );

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (isClosed) return;
      // Exponential backoff capped at _maxReconnectDelay.
      _reconnectDelay = Duration(
        milliseconds: (_reconnectDelay.inMilliseconds * 2).clamp(
          0,
          _maxReconnectDelay.inMilliseconds,
        ),
      );
      startTelemetry();
    });
  }

  // ── teardown ───────────────────────────────────────────────────────────────

  void stopTelemetry({required MeterInactiveReason reason}) {
    debugPrint('[MeterData] Stopping telemetry — reason: $reason');
    _intentionallyStopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectDelay = const Duration(seconds: 2);
    _lastDataReceivedAt = null;
    _cancelTelemetry();
    emit(
      MeterDataState(
        packets: const <String, MeterPacket>{},
        isConnected: false,
        inactiveReason: reason,
      ),
    );
  }

  void _cancelTelemetry() {
    _isConnecting = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
    // Fire-and-forget: disconnect is best-effort cleanup.
    networkClient.disconnect();
  }
}
