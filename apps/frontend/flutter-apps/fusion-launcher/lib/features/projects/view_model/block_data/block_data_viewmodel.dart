import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:fusion_lib/generated/proto/fusion/websocket.pb.dart' as model;
import 'package:fusion_lib/generated/proto/google/protobuf/struct.pb.dart'
    as structpb;
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

part 'block_data_viewmodel_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BlockDataViewmodel — singleton registered in service_locator.dart
//
// Connection state machine:
//
//   disconnected ──startWebsocket()──► connecting ──success──► connected
//        ▲                                  │                      │
//        │                           failure/error        heartbeat / resume
//        │                                  │                      │
//        └──────────ping timeout────── verifying ◄────────────────┘
//                                           │
//                                    pong received
//                                           │
//                                     connected (re-subscribes)
//
// Key design decisions:
//  • App resume / heartbeat → send ping first, NEVER blindly tear down socket.
//  • Reconnect is only triggered when (a) stream errors/closes, or
//    (b) a liveness ping times out without a pong.
//  • A single _WsConnectionState enum guards all entry points — no boolean soup.
//  • Pending pings use Completers so the caller can await a true/false result.
// ─────────────────────────────────────────────────────────────────────────────

/// Internal connection state — the single source of truth for what the socket
/// is doing right now. All public/private methods gate on this value.
enum _WsState {
  /// No socket exists. Safe to call [startWebsocket].
  disconnected,

  /// [connectWebSocket] is in-flight. Duplicate calls are ignored.
  connecting,

  /// Socket open, data flowing, heartbeat running.
  connected,

  /// A ping has been sent; awaiting pong before deciding whether to reconnect.
  /// The socket is still open and fully usable during this window.
  verifying,
}

class BlockDataViewmodel extends Cubit<BlockDataState>
    with WidgetsBindingObserver {
  BlockDataViewmodel() : super(BlockDataState()) {
    WidgetsBinding.instance.addObserver(this);
    _attachControlModeListener();
  }

  final FusionNetworkClient _networkClient =
      serviceLocator<FusionNetworkClient>();

  // ── Message templates ──────────────────────────────────────────────────────

  // ── Connection state machine ───────────────────────────────────────────────

  _WsState _wsState = _WsState.disconnected;

  /// Whether [stopWebsocket] was called intentionally.
  /// Prevents the auto-reconnect path from firing after a deliberate stop.
  bool _intentionallyStopped = false;

  StreamSubscription<ResponseCallback<dynamic>>? _wsSubscription;
  StreamSubscription<dynamic>? _controlModeSubscription;

  // ── Ping / Pong ────────────────────────────────────────────────────────────

  int _pingSeq = 0;

  /// Live ping completers keyed by their request id ("ping-N").
  /// Each completer resolves to true (pong received) or false (timed out).
  final Map<String, Completer<bool>> _pendingPings =
      <String, Completer<bool>>{};

  /// How long to wait for a pong before declaring the socket dead.
  static const Duration _kPingTimeout = Duration(seconds: 5);

  // ── Heartbeat ──────────────────────────────────────────────────────────────

  Timer? _heartbeatTimer;

  /// How often the heartbeat fires while connected.
  static const Duration _kHeartbeatInterval = Duration(seconds: 30);

  // ── Auto-reconnect (exponential backoff) ───────────────────────────────────

  Timer? _reconnectTimer;
  Duration _reconnectDelay = const Duration(seconds: 2);
  static const Duration _kMaxReconnectDelay = Duration(seconds: 30);

  // ── Interaction suppression ────────────────────────────────────────────────

  /// Tracks which blockId.parameter combos the user is currently editing.
  /// While an entry is alive, incoming server echoes for that key are dropped.
  final Map<String, Timer> _activeInteractions = <String, Timer>{};
  static const Duration _kInteractionCooldown = Duration(milliseconds: 10000);

  // ── Send debouncing ────────────────────────────────────────────────────────

  final Map<String, ({Timer timer, dynamic value, int? dimension})>
  _pendingSends = <String, ({Timer timer, dynamic value, int? dimension})>{};
  static const Duration _kSendDebounce = Duration(milliseconds: 150);
  int _patchSeq = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _controlModeSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _cancelAllPendingPings();
    _teardownSocket();
    return super.close();
  }

  // ── App lifecycle ──────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        _onAppResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Pause the heartbeat while backgrounded — saves resources and avoids
        // a spurious reconnect if iOS suspends mid-ping.
        _heartbeatTimer?.cancel();
        _heartbeatTimer = null;
    }
  }

  /// Called when the app returns to the foreground.
  ///
  /// *** THE FIX ***
  /// Old code called [_forceReconnect] unconditionally — destroying a
  /// perfectly healthy socket every single time the user came back from
  /// a brief lock-screen or notification check.
  ///
  /// New behaviour: send a ping. If the server responds with a pong within
  /// [_kPingTimeout], the socket is healthy — just re-send the config
  /// subscription to catch up on any missed updates and restart the heartbeat.
  /// Only if the ping times out (socket died silently) do we reconnect.
  void _onAppResumed() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (!vm.isInControlMode) return;

    debugPrint('[BlockData] App resumed — verifying socket health…');
    _verifyOrReconnect();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Control-mode wiring
  // ═══════════════════════════════════════════════════════════════════════════

  void _attachControlModeListener() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    _onControlModeChanged(vm.isInControlMode);
    _controlModeSubscription = vm.stream
        .map((_) => vm.isInControlMode)
        .distinct()
        .listen(_onControlModeChanged);
  }

  void _onControlModeChanged(bool active) {
    if (active) {
      startWebsocket();
    } else {
      stopWebsocket(reason: BlockDataInactiveReason.controlModeOff);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  void onProjectOpened() {
    if (serviceLocator<ProjectViewModel>().isInControlMode) startWebsocket();
  }

  void onProjectClosed() {
    stopWebsocket(reason: BlockDataInactiveReason.projectClosed);
  }

  /// Tear down and re-establish the subscription (e.g. after a project switch).
  void refreshSubscription() {
    stopWebsocket(reason: BlockDataInactiveReason.notStarted);
    if (serviceLocator<ProjectViewModel>().isInControlMode) startWebsocket();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Connection — start
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> startWebsocket() async {
    // Only start from a clean disconnected state — all other states mean
    // work is already in progress (connecting, connected, or verifying).
    if (_wsState != _WsState.disconnected) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _intentionallyStopped = false;
    _wsState = _WsState.connecting;

    final String? virtualIP = serviceLocator<ProjectViewModel>().virtualIP;
    if (virtualIP == null || virtualIP.isEmpty) {
      FusionLogger.log(
        tag: LogTag.dspConfig,
        message: '[BlockData] Cannot start WebSocket: virtualIP is null/empty',
      );
      _wsState = _WsState.disconnected;
      return;
    }

    final String wsHost =
        virtualIP.contains(':') ? virtualIP : '$virtualIP:8080';
    final String wsUrl = 'ws://$wsHost/ws';
    debugPrint('[BlockData] Connecting to $wsUrl…');

    try {
      final ResponseCallback<dynamic> result = await _networkClient
          .connectWebSocket(url: wsUrl);
      if (!result.success) {
        debugPrint('[BlockData] Connect failed: ${result.message}');
        _wsState = _WsState.disconnected;
        _scheduleReconnect();
        return;
      }
    } catch (e) {
      debugPrint('[BlockData] Connect exception: $e');
      _wsState = _WsState.disconnected;
      _scheduleReconnect();
      return;
    }

    // Attach stream listener BEFORE sending the subscription so we can
    // never miss the first config push.
    _wsSubscription = _networkClient.webSocketMessages.listen(
      _onDataReceived,
      onError: (dynamic error) {
        debugPrint('[BlockData] Stream error: $error');
        _handleUnexpectedDisconnect();
      },
      onDone: () {
        debugPrint('[BlockData] Stream closed by server.');
        _handleUnexpectedDisconnect();
      },
      cancelOnError: false,
    );

    _sendConfigSubscription();

    // Reset backoff — we succeeded.
    _reconnectDelay = const Duration(seconds: 2);
    _wsState = _WsState.connected;

    if (!isClosed) {
      emit(state.copyWith(isConnected: true, clearInactiveReason: true));
    }

    _startHeartbeat();
    debugPrint('[BlockData] WebSocket connected.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Liveness verification (ping / pong)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verify whether the current socket is still alive without closing it.
  ///
  /// • If the socket is already disconnected → call [startWebsocket].
  /// • If a connect/verify is already in progress → no-op (guard clause).
  /// • If connected → send a ping, await pong:
  ///     - pong received within timeout → re-subscribe + restart heartbeat.
  ///     - ping timed out              → socket is dead, force reconnect.
  Future<void> _verifyOrReconnect() async {
    switch (_wsState) {
      case _WsState.disconnected:
        await startWebsocket();
        return;
      case _WsState.connecting:
      case _WsState.verifying:
        // Already transitioning — do not pile on.
        return;
      case _WsState.connected:
        break; // Fall through to the ping logic.
    }

    _wsState = _WsState.verifying;
    debugPrint('[BlockData] Sending liveness ping…');

    final bool alive = await _sendPing();

    // Guard: could have been stopped or closed while we awaited the ping.
    if (isClosed || _intentionallyStopped) return;

    if (alive) {
      debugPrint('[BlockData] Pong received — socket healthy, re-subscribing.');
      _wsState = _WsState.connected;
      // Re-send subscription to catch up on any data missed while backgrounded.
      _sendConfigSubscription();
      // Restart the heartbeat timer (it was paused while backgrounded).
      _startHeartbeat();
    } else {
      debugPrint('[BlockData] Ping timed out — socket is dead, reconnecting…');
      _wsState = _WsState.disconnected;
      _forceReconnect();
    }
  }

  // ── Ping send ──────────────────────────────────────────────────────────────

  /// Sends a ping message and returns a [Future] that resolves to:
  ///   • `true`  — pong arrived within [_kPingTimeout].
  ///   • `false` — no pong (socket silent or dead) OR socket not connected.
  Future<bool> _sendPing() async {
    // If the underlying socket is gone there is nothing to ping.
    if (!_networkClient.webSocketService.isConnected) return false;

    final String id = 'ping-${++_pingSeq}';
    final Completer<bool> completer = Completer<bool>();
    _pendingPings[id] = completer;

    // Safety timeout — completes the future with false if no pong arrives.
    Timer? timeoutTimer;
    timeoutTimer = Timer(_kPingTimeout, () {
      if (!completer.isCompleted) {
        debugPrint(
          '[BlockData] Ping $id timed out after ${_kPingTimeout.inSeconds}s',
        );
        _pendingPings.remove(id);
        completer.complete(false);
      }
      timeoutTimer?.cancel();
    });

    _networkClient.sendWebSocketMessage(
      model.WebSocketRequest(id: id, version: 1, type: 'ping'),
    );

    final bool result = await completer.future;
    timeoutTimer.cancel();
    return result;
  }

  /// Resolves the Completer waiting for this pong message, if any.
  void _handlePong(model.WebSocketResponse message) {
    final String? id = message.hasId() ? message.id : null;
    if (id == null) return;
    final Completer<bool>? completer = _pendingPings.remove(id);
    if (completer != null && !completer.isCompleted) {
      debugPrint('[BlockData] Pong received for $id');
      completer.complete(true);
    }
  }

  /// Cancels all in-flight pings, completing their futures with [false].
  /// Called when the socket is being torn down so no caller hangs forever.
  void _cancelAllPendingPings() {
    for (final Completer<bool> c in _pendingPings.values) {
      if (!c.isCompleted) c.complete(false);
    }
    _pendingPings.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _kHeartbeatInterval,
      (_) => _onHeartbeatTick(),
    );
  }

  /// On each heartbeat tick, verify liveness via ping/pong.
  /// This also serves as a periodic config keepalive — [_verifyOrReconnect]
  /// re-sends the subscription message on a successful pong.
  Future<void> _onHeartbeatTick() async {
    if (_intentionallyStopped || isClosed) return;
    await _verifyOrReconnect();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Incoming data
  // ═══════════════════════════════════════════════════════════════════════════

  void _onDataReceived(ResponseCallback<dynamic> message) {
    if (!message.success || message.data == null) return;

    final dynamic rawData = message.data;
    late final model.WebSocketResponse payload;
    try {
      payload =
          rawData is String
              ? model.WebSocketResponse.fromJson(rawData)
              : model.WebSocketResponse.fromJson(jsonEncode(rawData));
    } catch (_) {
      return;
    }

    final String? type = payload.hasType() ? payload.type : null;

    // ── Pong ──────────────────────────────────────────────────────────────
    if (type == 'pong') {
      _handlePong(payload);
      return;
    }

    // ── Config data ────────────────────────────────────────────────────────
    if (type != 'config' && type != 'config_update') return;

    // Receiving config data proves the socket is alive; snap back to connected
    // in case we somehow received data during a verifying window.
    if (_wsState == _WsState.verifying) {
      _wsState = _WsState.connected;
    }

    if (!state.isConnected && !isClosed) {
      emit(state.copyWith(isConnected: true, clearInactiveReason: true));
    }

    try {
      final Map<String, dynamic>? data =
          payload.hasData() ? _decodeValueMap(payload.data) : null;
      final Map<String, dynamic>? audio =
          (data?['settings'] as Map<String, dynamic>?)?['audio']
              as Map<String, dynamic>?;
      if (audio == null) return;

      final Map<String, Map<String, dynamic>> updated =
          Map<String, Map<String, dynamic>>.from(state.allBlockData);
      bool anyAccepted = false;

      audio.forEach((String blockId, dynamic value) {
        if (value is! Map<String, dynamic>) return;

        final Map<String, dynamic> merged = Map<String, dynamic>.from(
          updated[blockId] ?? <String, dynamic>{},
        );
        bool blockAccepted = false;

        value.forEach((String param, dynamic paramValue) {
          final String key = '$blockId.$param';
          if (_activeInteractions.containsKey(key)) {
            // User is still editing this control — suppress the server echo.
            debugPrint('[BlockData] Suppressing server echo for $key');
          } else {
            merged[param] = paramValue;
            blockAccepted = true;
          }
        });

        updated[blockId] = merged;
        if (blockAccepted) anyAccepted = true;
      });

      if (anyAccepted && !isClosed) {
        emit(
          state.copyWith(
            allBlockData: updated,
            isConnected: true,
            clearInactiveReason: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('[BlockData] Parse error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Reconnect
  // ═══════════════════════════════════════════════════════════════════════════

  /// Unconditionally tear down and restart the socket.
  /// Only called when a liveness ping times out — never on app resume alone.
  void _forceReconnect() {
    _cancelAllPendingPings();
    _teardownSocket();
    _wsState = _WsState.disconnected;
    if (!isClosed) emit(state.copyWith(isConnected: false));

    // Small delay to let the OS fully release the old socket FD.
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(milliseconds: 500), () {
      if (isClosed || _intentionallyStopped) return;
      startWebsocket();
    });
  }

  void _handleUnexpectedDisconnect() {
    _cancelAllPendingPings();
    _teardownSocket();
    _wsState = _WsState.disconnected;
    if (!isClosed) emit(state.copyWith(isConnected: false));
    if (!_intentionallyStopped) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (isClosed) return;
    if (!serviceLocator<ProjectViewModel>().isInControlMode) return;

    debugPrint(
      '[BlockData] Reconnecting in ${_reconnectDelay.inSeconds}s '
      '(backoff: ${_reconnectDelay.inMilliseconds}ms)…',
    );

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (isClosed || _intentionallyStopped) return;
      // Double the delay for the next failure, capped at [_kMaxReconnectDelay].
      _reconnectDelay = Duration(
        milliseconds: (_reconnectDelay.inMilliseconds * 2).clamp(
          0,
          _kMaxReconnectDelay.inMilliseconds,
        ),
      );
      startWebsocket();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Teardown
  // ═══════════════════════════════════════════════════════════════════════════

  /// Intentional stop — clears all state, emits inactive.
  void stopWebsocket({required BlockDataInactiveReason reason}) {
    debugPrint('[BlockData] Stopping WebSocket — reason: $reason');
    _intentionallyStopped = true;
    _wsState = _WsState.disconnected;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectDelay = const Duration(seconds: 2);

    _cancelAllPendingPings();

    for (final Timer t in _activeInteractions.values) t.cancel();
    _activeInteractions.clear();
    for (final ({Timer timer, dynamic value, int? dimension}) e
        in _pendingSends.values) {
      e.timer.cancel();
    }
    _pendingSends.clear();

    _teardownSocket();

    emit(
      BlockDataState(
        allBlockData: const <String, Map<String, dynamic>>{},
        isConnected: false,
        inactiveReason: reason,
      ),
    );
  }

  /// Low-level socket cleanup — cancels the stream subscription and
  /// disconnects the underlying WebSocket. Does NOT update [_wsState] —
  /// the caller owns that.
  void _teardownSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _networkClient.disconnectWebSocket();
  }

  // ── Config subscription ────────────────────────────────────────────────────

  void _sendConfigSubscription() {
    _networkClient.sendWebSocketMessage(
      model.WebSocketRequest(id: 'config-001', version: 1, type: 'config'),
    );
    debugPrint('[BlockData] Sent config subscription');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REST fallback / on-demand block data
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getBlockData({
    required String blockId,
  }) async {
    // Prefer WebSocket-supplied data when fresh.
    final Map<String, dynamic>? wsData = state.allBlockData[blockId];
    if (wsData != null && wsData.isNotEmpty) {
      emit(state.copyWith(blockId: blockId, blockData: wsData));
      return wsData;
    }

    // Fallback to REST.
    try {
      final ResponseCallback<FusionStateValue<Map<String, dynamic>>> response =
          await _networkClient.getStateValue<Map<String, dynamic>>(
            key: 'settings.audio.$blockId',
            isSecure: false,
            baseUrlToOverride: serviceLocator<ProjectViewModel>().virtualIP!,
            decodeValue:
                (dynamic value) => Map<String, dynamic>.from(
                  value as Map<dynamic, dynamic>,
                ),
          );

      if (response.success && response.data != null && response.data!.exists) {
        final Map<String, dynamic> currentValue = response.data!.value!;
        final Map<String, Map<String, dynamic>> updated =
            Map<String, Map<String, dynamic>>.from(state.allBlockData)
              ..[blockId] = currentValue;
        emit(
          state.copyWith(
            blockId: blockId,
            blockData: currentValue,
            allBlockData: updated,
          ),
        );
        return currentValue;
      } else {
        FusionLogger.log(
          tag: LogTag.dspConfig,
          message:
              '[BlockData] REST fetch failed for $blockId: ${response.message}',
        );
      }
    } catch (ex) {
      FusionLogger.log(
        tag: LogTag.dspConfig,
        message: '[BlockData] REST fetch exception for $blockId: $ex',
      );
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Parameter updates
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> updateBlockParameter({
    required String blockId,
    required String parameter,
    required dynamic value,
    int? dimension,
  }) async {
    final String key = '$blockId.$parameter';

    // 1. Optimistic local write — UI feels instant.
    final Map<String, Map<String, dynamic>> optimistic =
        Map<String, Map<String, dynamic>>.from(state.allBlockData)
          ..[blockId] = <String, dynamic>{
            ...state.allBlockData[blockId] ?? <String, dynamic>{},
            parameter: value,
          };
    if (!isClosed) emit(state.copyWith(allBlockData: optimistic));

    // 2. Mark interaction — suppresses echo from server for [_kInteractionCooldown].
    _activeInteractions[key]?.cancel();
    _activeInteractions[key] = Timer(_kInteractionCooldown, () {
      _activeInteractions.remove(key);
      debugPrint('[BlockData] Interaction released for $key');
    });

    // 3. Debounce the network send — coalesces rapid slider movements.
    _pendingSends[key]?.timer.cancel();
    _pendingSends[key] = (
      value: value,
      dimension: dimension,
      timer: Timer(_kSendDebounce, () async {
        _pendingSends.remove(key);
        await _flushParameterUpdate(
          blockId: blockId,
          parameter: parameter,
          value: value,
          dimension: dimension,
        );
      }),
    );
  }

  /// Direct REST update (use when WebSocket is intentionally bypassed).
  Future<void> updateBlockParameterViaAPi({
    required String blockId,
    required String parameter,
    required dynamic value,
    int? dimension,
  }) async {
    try {
      final Map<String, dynamic> payload =
          dimension == null
              ? <String, dynamic>{
                'settings': <String, dynamic>{
                  'audio': <String, dynamic>{
                    blockId: <String, dynamic>{parameter: value},
                  },
                },
              }
              : <String, dynamic>{
                'settings': <String, dynamic>{
                  'audio': <String, dynamic>{
                    blockId: <String, dynamic>{
                      parameter: _buildDimensionList(value, dimension),
                    },
                  },
                },
              };

      final ResponseCallback<dynamic> response = await _networkClient.patch(
        api: FusionApiEndpoint.fusionState,
        isSecure: false,
        baseUrlToOverride: serviceLocator<ProjectViewModel>().virtualIP,
        data: payload,
      );

      if (!response.success) {
        FusionLogger.log(
          tag: LogTag.dspConfig,
          message:
              '[BlockData] REST patch failed for $blockId.$parameter: ${response.message}',
        );
      }
    } catch (ex) {
      FusionLogger.log(
        tag: LogTag.dspConfig,
        message:
            '[BlockData] REST patch exception for $blockId.$parameter: $ex',
      );
    }
  }

  /// Sends the actual network update after the debounce settles.
  ///
  /// Preference order:
  ///   1. WebSocket [patch_config] — lowest latency, only when the connection
  ///      is FULLY CONFIRMED healthy (_wsState == connected, i.e. a prior pong
  ///      has been received).
  ///   2. REST PATCH — used in every other state:
  ///      • verifying  — a ping is in flight; the socket might be dead. Sending
  ///        a patch on a potentially-dead socket and having the ping subsequently
  ///        time out means the patch is silently lost with no retry.
  ///      • connecting — socket handshake still in progress.
  ///      • disconnected — no socket.
  ///      REST guarantees delivery in all three cases.
  ///
  /// Does NOT attempt to reconnect the socket here — that is the responsibility
  /// of the heartbeat / disconnect handler. Mixing reconnect logic into the
  /// hot update path causes race conditions.
  Future<void> _flushParameterUpdate({
    required String blockId,
    required String parameter,
    required dynamic value,
    int? dimension,
  }) async {
    try {
      final Map<String, dynamic> audioPayload =
          dimension == null
              ? <String, dynamic>{
                'settings': <String, dynamic>{
                  'audio': <String, dynamic>{
                    blockId: <String, dynamic>{parameter: value},
                  },
                },
              }
              : <String, dynamic>{
                'settings': <String, dynamic>{
                  'audio': <String, dynamic>{
                    blockId: <String, dynamic>{
                      parameter: _buildDimensionList(value, dimension),
                    },
                  },
                },
              };

      // IMPORTANT: check _wsState, NOT just the underlying isConnected flag.
      //
      // During 'verifying', the physical socket is still open so isConnected
      // returns true — but we have not yet received a pong confirming the
      // socket is alive. If the ping subsequently times out, _forceReconnect
      // tears the socket down and any message sent in this window is dropped
      // with no retry. REST is reliable; use it whenever we are not in the
      // fully-confirmed 'connected' state.
      final bool socketConfirmedHealthy =
          _wsState == _WsState.connected &&
          _networkClient.webSocketService.isConnected;

      if (socketConfirmedHealthy) {
        _sendPatchConfig(audioPayload);
        return;
      }

      // Socket uncertain or unavailable — fall back to REST.
      await _restPatch(
        blockId: blockId,
        parameter: parameter,
        value: value,
        dimension: dimension,
        audioPayload: audioPayload,
      );
    } catch (ex) {
      FusionLogger.log(
        tag: LogTag.dspConfig,
        message: '[BlockData] Flush error for $blockId.$parameter: $ex',
      );
    }
  }

  void _sendPatchConfig(Map<String, dynamic> data) {
    _networkClient.sendWebSocketMessage(
      model.WebSocketRequest(
        id: 'patch-${++_patchSeq}',
        version: 1,
        type: 'patch_config',
        data: _valueFromJson(data),
      ),
    );
  }

  Future<void> _restPatch({
    required String blockId,
    required String parameter,
    required dynamic value,
    required int? dimension,
    required Map<String, dynamic> audioPayload,
  }) async {
    final ResponseCallback<dynamic> response = await _networkClient.patch(
      api: FusionApiEndpoint.fusionState,
      isSecure: false,
      baseUrlToOverride: serviceLocator<ProjectViewModel>().virtualIP,
      data: audioPayload,
    );
    if (!response.success) {
      FusionLogger.log(
        tag: LogTag.dspConfig,
        message:
            '[BlockData] REST patch fallback failed for $blockId.$parameter: ${response.message}',
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Builds a sparse list so a single array dimension can be patched without
  /// overwriting sibling dimensions on the server.
  List<dynamic> _buildDimensionList(dynamic value, int dimension) {
    return List<dynamic>.filled(dimension + 1, null)..[dimension] = value;
  }

  structpb.Value _valueFromJson(Map<String, dynamic> json) {
    final structpb.Struct value = structpb.Struct();
    value.mergeFromProto3Json(json);
    return structpb.Value(structValue: value);
  }

  Map<String, dynamic>? _decodeValueMap(structpb.Value value) {
    try {
      final dynamic decoded = jsonDecode(value.writeToJson());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
