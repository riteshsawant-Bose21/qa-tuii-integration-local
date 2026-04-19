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
//  • Enum-based connection state machine (no desync-able boolean flags)
//  • Heartbeat liveness detection via last-received timestamp
//    (ZMQ has no ping/pong — timestamp is the correct mechanism here)
//  • Exponential-backoff auto-reconnect
//  • App lifecycle awareness with background-grace-period guard
//    (short focus-blips on desktop are ignored; only true backgrounds reconnect)
//  • Observer-gated resource management via a Set<Object> identity token
//    (eliminates double-register / double-unregister counter drift)
// ─────────────────────────────────────────────────────────────────────────────

/// Internal connection state — the single source of truth for what the
/// telemetry stream is doing right now. All entry points gate on this value.
///
/// Unlike [BlockDataViewmodel] there is no `verifying` state because ZMQ
/// subscriptions do not support a ping/pong handshake. Liveness is inferred
/// from the timestamp of the last received frame.
enum _TelemetryState {
  /// No subscription open. Safe to call [startTelemetry].
  disconnected,

  /// [networkClient.connect] is in-flight. Duplicate calls are ignored.
  connecting,

  /// Subscription open; data flowing; heartbeat running.
  connected,
}

class MeterDataViewModel extends Cubit<MeterDataState> with WidgetsBindingObserver {
  MeterDataViewModel() : super(const MeterDataState()) {
    WidgetsBinding.instance.addObserver(this);
    _attachControlModeListener();
  }

  final FusionNetworkClient networkClient = serviceLocator<FusionNetworkClient>();

  // ── Connection state machine ───────────────────────────────────────────────

  _TelemetryState _telemetryState = _TelemetryState.disconnected;

  /// Whether [stopTelemetry] was called intentionally.
  /// Prevents the auto-reconnect path from running after a deliberate stop.
  bool _intentionallyStopped = false;

  StreamSubscription<ResponseCallback<dynamic>>? _telemetrySubscription;
  StreamSubscription<dynamic>? _controlModeSubscription;

  // ── Observer tracking ──────────────────────────────────────────────────────

  /// Identity tokens of currently mounted UI widgets observing this ViewModel.
  ///
  /// Using a [Set] rather than a counter prevents counter drift caused by
  /// mismatched register/unregister calls (e.g. hot-reload, widget rebuild).
  /// Each widget passes a stable `this` reference or a dedicated token object.
  final Set<Object> _observers = <Object>{};

  bool get hasActiveObservers => _observers.isNotEmpty;

  // ── Reconnect (exponential backoff) ───────────────────────────────────────

  Timer? _reconnectTimer;
  Duration _reconnectDelay = const Duration(seconds: 2);
  static const Duration _kMaxReconnectDelay = Duration(seconds: 30);

  // ── Heartbeat (timestamp-based liveness) ──────────────────────────────────
  //
  // ZMQ is a subscriber protocol — there is no application-level ping/pong.
  // We infer liveness from how recently data arrived. If no frame arrives
  // within [_kStaleThreshold] the socket is considered silently dead.

  Timer? _heartbeatTimer;

  /// How often the heartbeat fires while connected.
  static const Duration _kHeartbeatInterval = Duration(seconds: 8);

  /// If no data arrives within this window the connection is stale.
  static const Duration _kStaleThreshold = Duration(seconds: 15);

  /// Timestamp of the last successfully received data frame.
  DateTime? _lastDataReceivedAt;

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

  /// On resume, if the most recent data frame is older than this we assume the
  /// socket died silently and force a reconnect immediately.
  static const Duration _kResumeStaleThreshold = Duration(seconds: 10);

  // ═══════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _controlModeSubscription?.cancel();
    _heartbeatTimer?.cancel();
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
        // True background entry — record timestamp, pause heartbeat.
        _backgroundedAt ??= DateTime.now();
        _heartbeatTimer?.cancel();
        _heartbeatTimer = null;

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
  /// Note: Unlike [BlockDataViewmodel], there is no ping/pong available over
  /// ZMQ. We probe liveness via the last-received timestamp instead.
  void _onAppResumed({required Duration awayFor}) {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (!vm.isInControlMode || !hasActiveObservers) return;

    // Very short absence → trust the socket; the heartbeat will catch any
    // silent death within [_kHeartbeatInterval].
    if (awayFor < _kBackgroundGracePeriod) {
      _ensureHeartbeatRunning();
      return;
    }

    // No subscription at all → let the normal connect flow run.
    if (_telemetryState == _TelemetryState.disconnected) {
      _ensureHeartbeatRunning();
      startTelemetry();
      return;
    }

    // Subscription exists — check the last-data timestamp to decide if it is
    // still alive. A fresh frame means the socket survived the background.
    final DateTime? last = _lastDataReceivedAt;
    final bool looksAlive = last != null && DateTime.now().difference(last) < _kResumeStaleThreshold;

    if (looksAlive) {
      debugPrint('[MeterData] Socket looks alive on resume — keeping it.');
      _ensureHeartbeatRunning();
    } else {
      debugPrint(
        '[MeterData] Socket appears stale on resume — forcing reconnect.',
      );
      _forceReconnect();
    }
  }

  /// Restarts the heartbeat timer only if a subscription is open and the
  /// timer is not already running.
  void _ensureHeartbeatRunning() {
    if (_telemetryState != _TelemetryState.connected) return;
    if (_heartbeatTimer?.isActive ?? false) return;
    _startHeartbeat();
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
  /// The Set ensures that a widget calling [registerObserver] twice without an
  /// intervening [unregisterObserver] does not inflate the count.
  void registerObserver(Object observer) {
    final bool wasEmpty = _observers.isEmpty;
    _observers.add(observer);
    debugPrint('[MeterData] registerObserver — count: ${_observers.length}');

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

    if (_observers.isEmpty) {
      // No UI is watching — pause timers to conserve resources.
      // The subscription itself is kept alive so data is not lost if an
      // observer re-mounts quickly (e.g. a tab switch).
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
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

    debugPrint('[MeterData] Connecting to $vip…');

    try {
      await networkClient.connect(vip: vip);
    } catch (e) {
      debugPrint('[MeterData] Connect failed: $e');
      _telemetryState = _TelemetryState.disconnected;
      _scheduleReconnect();
      return;
    }

    // Attach stream listener before updating state so we cannot miss the
    // first frame.
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

    _lastDataReceivedAt = DateTime.now();

    // Reset backoff — connection succeeded.
    _reconnectDelay = const Duration(seconds: 2);
    _telemetryState = _TelemetryState.connected;

    if (!isClosed) {
      emit(state.copyWith(isConnected: true, clearInactiveReason: true));
    }

    _startHeartbeat();
    debugPrint('[MeterData] Telemetry connected.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Incoming data
  // ═══════════════════════════════════════════════════════════════════════════

  void _onDataReceived(ResponseCallback<dynamic> message) {
    _lastDataReceivedAt = DateTime.now();

    if (!state.isConnected && !isClosed) {
      emit(state.copyWith(isConnected: true, clearInactiveReason: true));
    }

    try {
      final MeterPacket packet = MeterPacket.fromMap(
        message.data as Map<String, dynamic>,
      );

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
  // Heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_kHeartbeatInterval, (_) => _checkLiveness());
  }

  /// Checks whether the most recent frame arrived within [_kStaleThreshold].
  /// If not, the ZMQ socket is considered silently dead and is torn down.
  void _checkLiveness() {
    if (_intentionallyStopped || isClosed) return;
    if (_lastDataReceivedAt == null) return;

    final Duration elapsed = DateTime.now().difference(_lastDataReceivedAt!);
    if (elapsed > _kStaleThreshold) {
      debugPrint(
        '[MeterData] No data for ${elapsed.inSeconds}s — '
        'treating connection as stale, reconnecting…',
      );
      _forceReconnect();
    }
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
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectDelay = const Duration(seconds: 2); // ← was never reset in original
    _lastDataReceivedAt = null;

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
  ///
  /// Note: heartbeat is NOT cancelled here. [stopTelemetry] and
  /// [_handleUnexpectedDisconnect] handle that explicitly before calling
  /// this method, avoiding the double-cancel that was in the original code.
  void _teardownTelemetry() {
    _telemetrySubscription?.cancel();
    _telemetrySubscription = null;
    networkClient.disconnect(); // fire-and-forget
  }
}
