import 'dart:async';
import 'dart:convert';

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
// Resilient WebSocket telemetry consumer with:
//  • Enum-based connection state machine (no desync-able boolean flags)
//  • Heartbeat liveness detection via last-received timestamp
//  • Exponential-backoff auto-reconnect
//  • App lifecycle awareness with background-grace-period guard
//    (short focus-blips on desktop are ignored; only true backgrounds reconnect)
//  • Observer-gated resource management via a Set<Object> identity token
//    (eliminates double-register / double-unregister counter drift)
// ─────────────────────────────────────────────────────────────────────────────

/// Internal connection state — the single source of truth for what the
/// telemetry stream is doing right now. All entry points gate on this value.
enum _TelemetryState {
  /// No subscription open. Safe to call [startTelemetry].
  disconnected,

  /// WebSocket connect is in-flight. Duplicate calls are ignored.
  connecting,

  /// WebSocket open; data flowing; heartbeat running.
  connected,
}

class MeterDataViewModel extends Cubit<MeterDataState> with WidgetsBindingObserver {
  MeterDataViewModel() : super(const MeterDataState()) {
    WidgetsBinding.instance.addObserver(this);
    _attachControlModeListener();
  }

  final FusionNetworkClient networkClient = serviceLocator<FusionNetworkClient>();
  final WebSocketService _wsService = serviceLocator<WebSocketService>();

  // ── Connection state machine ───────────────────────────────────────────────

  _TelemetryState _telemetryState = _TelemetryState.disconnected;

  /// Whether [stopTelemetry] was called intentionally.
  /// Prevents the auto-reconnect path from running after a deliberate stop.
  bool _intentionallyStopped = false;

  StreamSubscription<ResponseCallback<dynamic>>? _wsSubscription;
  StreamSubscription<bool>? _wsAliveSubscription;
  StreamSubscription<dynamic>? _controlModeSubscription;

  // ── Observer tracking ──────────────────────────────────────────────────────

  final Map<Object, Set<String>?> _observers = <Object, Set<String>?>{};

  bool get hasActiveObservers => _observers.isNotEmpty;

  Set<String> _activeBlockIds = <String>{};

  // ── Reconnect (exponential backoff) ───────────────────────────────────────

  Timer? _reconnectTimer;
  Duration _reconnectDelay = const Duration(seconds: 2);
  static const Duration _kMaxReconnectDelay = Duration(seconds: 30);

  // ── Heartbeat (ping/pong via FusionNetworkClient) ───────────────────────────
  //

  // ── App-lifecycle background detection ────────────────────────────────────

  /// When the app truly entered a background state (`paused` / `detached`).
  /// `null` means the app has not been genuinely backgrounded — transient
  /// `inactive` / `hidden` events on desktop do NOT set this.
  DateTime? _backgroundedAt;

  /// The last observed lifecycle state. Used to deduplicate repeated callbacks
  /// (some platforms re-deliver the same state without a real transition).
  AppLifecycleState? _lastLifecycleState;

  /// Minimum background duration before we consider the socket suspect on
  /// resume. Anything shorter is a focus blip (menu open, alert, etc.) and
  /// the socket is almost certainly still alive.
  static const Duration _kBackgroundGracePeriod = Duration(seconds: 5);

  // ═══════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _controlModeSubscription?.cancel();
    _wsAliveSubscription?.cancel();
    _reconnectTimer?.cancel();
    _teardownTelemetry();
    return super.close();
  }

  // ── App lifecycle ──────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    // Deduplicate — some platforms re-deliver the same state.
    if (_lastLifecycleState == lifecycleState) return;
    _lastLifecycleState = lifecycleState;

    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        final DateTime? backgroundedAt = _backgroundedAt;
        _backgroundedAt = null; // Clear regardless of whether we act.

        if (backgroundedAt == null) {
          // Was never truly backgrounded (e.g. a transient inactive→resumed
          // flip). Ensure the heartbeat is alive and move on.
          _ensureHeartbeatRunning();
          return;
        }

        final Duration awayFor = DateTime.now().difference(backgroundedAt);
        debugPrint(
          '[MeterData] App resumed after ${awayFor.inSeconds}s in background.',
        );
        _onAppResumed(awayFor: awayFor);

      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // True background entry — record timestamp
        _backgroundedAt ??= DateTime.now();

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Transient states: window-focus loss, system overlay, brief
        // obscuration. The process keeps running and the socket stays valid.
        // Do NOT set _backgroundedAt or cancel the heartbeat — on desktop
        // these fire constantly (every menu open, every tooltip, etc.) and
        // would cause continuous spurious reconnects.
        break;
    }
  }

  /// Handles the app returning to the foreground after a genuine background
  /// trip. Decides whether the existing subscription can be trusted.
  ///
  void _onAppResumed({required Duration awayFor}) {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (!vm.isInControlMode || !hasActiveObservers) return;

    if (_telemetryState == _TelemetryState.disconnected) {
      startTelemetry();
      return;
    }

    if (awayFor < _kBackgroundGracePeriod) {
      // Short absence — socket is trusted. Ensure heartbeat is running.
      _ensureHeartbeatRunning();
    } else {
      debugPrint('[MeterData] Long background (${awayFor.inSeconds}s) — forcing reconnect.');
      _forceReconnect();
    }
  }

  /// Restarts the heartbeat in [FusionNetworkClient] if a connection is open.
  void _ensureHeartbeatRunning() {
    if (_telemetryState != _TelemetryState.connected) return;
    networkClient.startWsHeartbeat();
  }

  // ── Control-mode wiring ────────────────────────────────────────────────────

  void _attachControlModeListener() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    _onControlModeChanged(vm.isInControlMode);
    _controlModeSubscription = vm.stream.map((_) => vm.isInControlMode).distinct().listen(_onControlModeChanged);
  }

  void _onControlModeChanged(bool active) {
    if (active) {
      startTelemetry();
    } else {
      stopTelemetry(reason: MeterInactiveReason.controlModeOff);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  void onProjectOpened() {
    if (serviceLocator<ProjectViewModel>().isInControlMode) startTelemetry();
  }

  void onProjectClosed() {
    stopTelemetry(reason: MeterInactiveReason.projectClosed);
  }

  void refreshSubscriber() {
    stopTelemetry(reason: MeterInactiveReason.refreshing);
    if (serviceLocator<ProjectViewModel>().isInControlMode) startTelemetry();
  }

  // ── Observer management ────────────────────────────────────────────────────

  /// Call from a widget's [State.initState] / [StatefulWidget] mounting point.
  ///
  /// Pass a stable identity token — typically `this` from a [State] subclass.
  /// Optionally pass [blockIds] to declare which meter block IDs this observer
  void registerObserver(Object observer, Set<String> blockIds) {
    final bool wasEmpty = _observers.isEmpty;
    _observers[observer] = blockIds;
    FusionLogger.log(
      tag: LogTag.dspConfig,
      message:
          '[MeterData] registerObserver — count: ${_observers.length}'
          '${blockIds != null ? ', blockIds: $blockIds' : ''}',
    );
    _recomputeBlockIds();

    if (wasEmpty) {
      final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
      if (vm.isInControlMode && _telemetryState == _TelemetryState.disconnected) {
        debugPrint('[MeterData] First observer — connecting…');
        startTelemetry();
      }
    }
  }

  /// Call from a widget's [State.dispose].
  ///
  /// Safe to call with a token that was never registered (no-op).
  void unregisterObserver(Object observer) {
    _observers.remove(observer);
    debugPrint('[MeterData] unregisterObserver — count: ${_observers.length}');

    _recomputeBlockIds();

    if (_observers.isEmpty) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Connection
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> startTelemetry() async {
    // Only start from a clean disconnected state — connecting/connected means
    // work is already in progress.
    if (_telemetryState != _TelemetryState.disconnected) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _intentionallyStopped = false;
    _telemetryState = _TelemetryState.connecting;

    final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
    if (vip == null || vip.isEmpty) {
      FusionLogger.log(
        tag: LogTag.dspConfig,
        message: '[MeterData] Cannot start: virtualIP is null/empty',
      );
      _telemetryState = _TelemetryState.disconnected;
      return;
    }

    final String wsHost = vip.contains(':') ? vip : '$vip:8080';
    final String wsUrl = 'ws://$wsHost/ws';

    debugPrint('[MeterData] Connecting to $wsUrl…');

    await networkClient.connectWebSocket(url: wsUrl);

    _wsSubscription = networkClient.webSocketMessages.listen(
      _onWsMessage,
      onError: (dynamic error) {
        debugPrint('[MeterData] WS stream error: $error');
        _handleUnexpectedDisconnect();
      },
      onDone: () {
        debugPrint('[MeterData] WS stream closed by server.');
        _handleUnexpectedDisconnect();
      },
      cancelOnError: false,
    );

    // _wsAliveSubscription?.cancel();
    // _wsAliveSubscription = networkClient.wsAliveStream.listen((bool alive) {
    //   if (!alive && !_intentionallyStopped) {
    //     debugPrint('[MeterData] wsAliveStream emitted false — reconnecting…');
    //     _forceReconnect();
    //   }
    // });

    _reconnectDelay = const Duration(seconds: 2);
    _telemetryState = _TelemetryState.connected;

    if (!isClosed) {
      emit(state.copyWith(isConnected: true, clearInactiveReason: true));
    }

    // _sendSubscribe();
    _sendBlockIdsUpdate();

    networkClient.startWsHeartbeat();
    debugPrint('[MeterData] Telemetry connected via WebSocket.');
  }

  /// Sends the subscribe_meter_data message to the WS server.
  void _sendSubscribe() {
    final Map<String, dynamic> msg = <String, dynamic>{
      'type': 'subscribe_meter_data',
      'id': _randomId,
      'version': 1,
    };
    _wsService.sendMessage(jsonEncode(msg));
    debugPrint('[MeterData] Sent subscribe_meter_data');
  }

  /// Sends the unsubscribe_meter_data message to the WS server.
  void _sendUnsubscribe() {
    if (!_wsService.isConnected) return;
    final Map<String, dynamic> msg = <String, dynamic>{
      'type': 'unsubscribe_meter_data',
      'id': _randomId,
      'version': 1,
    };
    _wsService.sendMessage(jsonEncode(msg));
    debugPrint('[MeterData] Sent unsubscribe_meter_data');
  }

  /// Random ID generator for WS messages ID field.
  String get _randomId => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  // ── Block-ID subscription management ──────────────────────────────────────

  /// Recomputes [_activeBlockIds] from all observers and sends an update to
  /// the WS server if the set has changed.
  void _recomputeBlockIds() {
    final Set<String> newIds = <String>{};
    for (final Set<String>? entry in _observers.values) {
      if (entry != null) newIds.addAll(entry);
    }

    if (_activeBlockIds.length == newIds.length && _activeBlockIds.containsAll(newIds)) {
      return; // No change — skip the WS message.
    }

    _activeBlockIds = newIds;
    debugPrint('[MeterData] activeBlockIds updated: $_activeBlockIds');

    _sendBlockIdsUpdate();
  }

  /// Sends the current [_activeBlockIds] to the WS server so it can filter
  /// which meter blocks it sends back.
  void _sendBlockIdsUpdate() {
    if (!_wsService.isConnected) return;
    if (_telemetryState != _TelemetryState.connected) return;

    final Map<String, dynamic> msg = <String, dynamic>{
      'type': 'update_meter_data_filter',
      'version': 1,
      'id': _randomId,
      'data': <String, dynamic>{
        'filter': _activeBlockIds.toList(),
      },
    };
    FusionLogger.log(tag: 'MeterDataViewModel', message: 'Sending update_meter_data_filter with block IDs: $msg');
    _wsService.sendMessage(jsonEncode(msg));
    debugPrint('[MeterData] Sent update_meter_subscription — block_ids: $_activeBlockIds');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Incoming data
  // ═══════════════════════════════════════════════════════════════════════════

  void _onWsMessage(ResponseCallback<dynamic> response) {
    print("[MeterData] Received WS message: ${response.data}");
    if (!response.success) return;

    if (!state.isConnected && !isClosed) {
      emit(state.copyWith(isConnected: true, clearInactiveReason: true));
    }

    try {
      final Map<String, dynamic> envelope = response.data as Map<String, dynamic>;

      final String? type = envelope['type'] as String?;

      // Only process meter_data envelopes.
      if (type != 'meter_data') return;

      FusionLogger.log(tag: 'MeterDataViewModel', message: 'Received WS message: ${response.data}');
      FusionLogger.log(tag: 'MeterDataViewModel', message: 'Current state before processing message: $_observers');

      final dynamic data = envelope['data'];
      if (data is! Map<String, dynamic>) return;

      final MeterPacket packet = MeterPacket.fromMap(data);

      final Map<String, MeterPacket> updatedPackets = Map<String, MeterPacket>.from(state.packets)..[packet.name] = packet;

      final Map<String, MeterBlock> updatedMeterValues = Map<String, MeterBlock>.from(
        state.meterValues ?? <String, MeterBlock>{},
      );
      for (final MeterBlock block in packet.blocks) {
        updatedMeterValues[block.blockName] = block;
      }

      // Extract per-device system info from fusion_system_monitor packets.
      Map<String, DeviceSystemInfo>? updatedSystemInfo;
      if (packet.name == 'fusion_system_monitor' && packet.deviceId.isNotEmpty) {
        updatedSystemInfo = Map<String, DeviceSystemInfo>.from(state.deviceSystemInfo)..[packet.deviceId] = _parseSystemInfo(packet);
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            packets: updatedPackets,
            meterValues: updatedMeterValues,
            deviceSystemInfo: updatedSystemInfo,
            isConnected: true,
            clearInactiveReason: true,
          ),
        );
      }
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Reconnect
  // ═══════════════════════════════════════════════════════════════════════════

  /// Unconditionally tears down and restarts the subscription.
  /// Only called when liveness checks confirm the connection is dead.
  void _forceReconnect() {
    _teardownTelemetry();
    _telemetryState = _TelemetryState.disconnected;
    if (!isClosed) emit(state.copyWith(isConnected: false));

    // Small delay to let the OS fully release the old socket descriptor.
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(milliseconds: 500), () {
      if (isClosed || _intentionallyStopped) return;
      startTelemetry();
    });
  }

  void _handleUnexpectedDisconnect() {
    _teardownTelemetry();
    _telemetryState = _TelemetryState.disconnected;
    if (!isClosed) emit(state.copyWith(isConnected: false));
    if (!_intentionallyStopped) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (isClosed) return;
    if (!hasActiveObservers) {
      debugPrint('[MeterData] No active observers — skipping reconnect.');
      return;
    }
    if (!serviceLocator<ProjectViewModel>().isInControlMode) return;

    debugPrint(
      '[MeterData] Reconnecting in ${_reconnectDelay.inSeconds}s '
      '(backoff: ${_reconnectDelay.inMilliseconds}ms)…',
    );

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (isClosed || _intentionallyStopped) return;
      _reconnectDelay = Duration(
        milliseconds: (_reconnectDelay.inMilliseconds * 2).clamp(0, _kMaxReconnectDelay.inMilliseconds),
      );
      startTelemetry();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Teardown
  // ═══════════════════════════════════════════════════════════════════════════

  /// Intentional full stop — clears all state and emits inactive reason.
  void stopTelemetry({required MeterInactiveReason reason}) {
    debugPrint('[MeterData] Stopping telemetry — reason: $reason');
    _intentionallyStopped = true;
    _telemetryState = _TelemetryState.disconnected;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectDelay = const Duration(seconds: 2);

    _teardownTelemetry();

    emit(
      MeterDataState(
        packets: const <String, MeterPacket>{},
        isConnected: false,
        inactiveReason: reason,
      ),
    );
  }

  /// Low-level subscription cleanup. Does NOT update [_telemetryState] —
  /// the caller owns that transition.
  void _teardownTelemetry() {
    _sendUnsubscribe();
    _wsAliveSubscription?.cancel();
    _wsAliveSubscription = null;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    networkClient.stopWsHeartbeat();
    networkClient.disconnectWebSocket();
  }
}
