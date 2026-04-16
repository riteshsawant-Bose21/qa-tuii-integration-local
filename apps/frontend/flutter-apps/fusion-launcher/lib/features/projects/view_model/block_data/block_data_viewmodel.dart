import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

part 'block_data_viewmodel_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BlockDataViewmodel — singleton registered in service_locator.dart
//
// Resilient WebSocket config-subscription consumer with:
//  • Heartbeat-based liveness detection (catches silent disconnects)
//  • Exponential-backoff auto-reconnect
//  • App lifecycle awareness (reconnects on resume from background)
//  • Periodic config re-subscription as a keepalive
// ─────────────────────────────────────────────────────────────────────────────

class BlockDataViewmodel extends Cubit<BlockDataState> with WidgetsBindingObserver {
  BlockDataViewmodel() : super(BlockDataState()) {
    WidgetsBinding.instance.addObserver(this);
    _attachControlModeListener();
  }

  final FusionNetworkClient _networkClient = serviceLocator<FusionNetworkClient>();

  // ── config subscription payload ──────────────────────────────────────────
  static const Map<String, dynamic> _configSubscriptionMessage = <String, dynamic>{
    'id': 'config-001',
    'version': 1,
    'type': 'config',
  };

  // ── internals ──────────────────────────────────────────────────────────────

  StreamSubscription<ResponseCallback<dynamic>>? _webSocketSubscription;

  /// Tracks which block+param combos the user is *currently* dragging/typing.
  /// Key: "$blockId.$parameter"  Value: debounce Timer
  /// While an entry exists, incoming server values for that key are ignored.
  final Map<String, Timer> _activeInteractions = <String, Timer>{};

  /// How long after the user's LAST input before we consider them "done"
  /// and allow server values to flow back in.
  /// Tune this to be slightly longer than your server round-trip.
  static const Duration _interactionCooldown = Duration(milliseconds: 10000);

  /// Debounce timers — coalesce rapid updates before sending to server.
  /// Key: "$blockId.$parameter"  Value: (timer, latest value, dimension)
  final Map<String, ({Timer timer, dynamic value, int? dimension})> _pendingSends = <String, ({int? dimension, Timer timer, dynamic value})>{};

  /// How long to wait after the last input before actually sending to server.
  static const Duration _sendDebounce = Duration(milliseconds: 150);

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

  /// Guards against overlapping connect/disconnect cycles.
  bool _isConnecting = false;

  // ── heartbeat (stale-connection detection) ─────────────────────────────────

  /// Periodic timer that checks whether we've received any data recently
  /// and re-sends the config subscription as a keepalive.
  Timer? _heartbeatTimer;

  /// How often the heartbeat check fires.
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  /// If no data arrives within this window the connection is considered stale.
  static const Duration _staleThreshold = Duration(seconds: 60);

  /// Timestamp of the last successfully received data frame.
  DateTime? _lastDataReceivedAt;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _controlModeSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _cancelWebsocket();
    return super.close();
  }

  // ── app lifecycle ──────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        debugPrint('[BlockData] App resumed — checking connection…');
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
  /// because WebSocket sockets often die silently during background.
  void _onAppResumed() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (!vm.isInControlMode) return;

    // Force a reconnect — the old socket is almost certainly stale after
    // the app was backgrounded (even for a short time, let alone days).
    _forceReconnect();
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
      startWebsocket();
    } else {
      stopWebsocket(reason: BlockDataInactiveReason.controlModeOff);
    }
  }

  // ── public API ─────────────────────────────────────────────────────────────

  void onProjectOpened() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (vm.isInControlMode) {
      startWebsocket();
    }
  }

  void onProjectClosed() {
    stopWebsocket(reason: BlockDataInactiveReason.projectClosed);
  }

  /// Request a full config refresh by re-sending the subscription message.
  void refreshSubscription() {
    stopWebsocket(reason: BlockDataInactiveReason.notStarted);
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (vm.isInControlMode) {
      startWebsocket();
    }
  }

  // ── connection ─────────────────────────────────────────────────────────────

  Future<void> startWebsocket() async {
    // Guard: do not double-subscribe or overlap with an in-flight connect.
    if (_webSocketSubscription != null || _isConnecting) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _intentionallyStopped = false;
    _isConnecting = true;

    final String? virtualIP = serviceLocator<ProjectViewModel>().virtualIP;
    if (virtualIP == null || virtualIP.isEmpty) {
      FusionLogger.log(tag: LogTag.dspConfig, message: '[BlockData] Cannot start WebSocket: virtualIP is null or empty');
      _isConnecting = false;
      return;
    }

    final String wsHost = virtualIP.contains(':') ? virtualIP : '$virtualIP:8080';
    final String wsUrl = 'ws://$wsHost/ws';
    debugPrint('[BlockData] Starting WebSocket to $wsUrl…');

    try {
      final ResponseCallback<dynamic> connectResponse = await _networkClient.connectWebSocket(url: wsUrl);
      if (!connectResponse.success) {
        // await _networkClient.sendWebSocketMessage(<String, Object>{"id": "config-001", "version": 1, "type": "config"});
        debugPrint('[BlockData] Connect failed: ${connectResponse.message}');
        _isConnecting = false;
        _scheduleReconnect();
        return;
      }
    } catch (e) {
      debugPrint('[BlockData] Connect exception: $e');
      _isConnecting = false;
      _scheduleReconnect();
      return;
    }

    // Send the config subscription message to start receiving updates.
    _sendConfigSubscription();

    _lastDataReceivedAt = DateTime.now();

    // Listen to incoming WebSocket messages.
    _webSocketSubscription = _networkClient.webSocketMessages.listen(
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

    // Reset backoff on successful connection.
    _reconnectDelay = const Duration(seconds: 2);
    _isConnecting = false;

    emit(state.copyWith(isConnected: true, clearInactiveReason: true));

    // Start the heartbeat checker to detect silent disconnects.
    _startHeartbeat();
  }

  /// Sends the config subscription message so the server starts pushing
  /// configuration updates (including `settings.audio` block data).
  void _sendConfigSubscription() {
    _networkClient.sendWebSocketMessage(_configSubscriptionMessage);
    debugPrint('[BlockData] Sent config subscription message');
  }

  /// Handles every message arriving from the WebSocket stream.
  void _onDataReceived(ResponseCallback<dynamic> message) {
    _lastDataReceivedAt = DateTime.now();

    if (!state.isConnected && !isClosed) {
      emit(state.copyWith(isConnected: true, clearInactiveReason: true));
    }

    if (!message.success || message.data == null) return;

    try {
      final dynamic rawData = message.data;
      if (rawData is! Map<String, dynamic>) return;

      final String? type = rawData['type'] as String?;
      if (type != 'config' && type != 'config_update') return;

      final Map<String, dynamic>? data = rawData['data'] as Map<String, dynamic>?;
      final Map<String, dynamic>? settings = data?['settings'] as Map<String, dynamic>?;
      final Map<String, dynamic>? audio = settings?['audio'] as Map<String, dynamic>?;
      if (audio == null) return;

      final Map<String, Map<String, dynamic>> updatedBlockData = Map<String, Map<String, dynamic>>.from(state.allBlockData);
      bool anyAccepted = false;

      audio.forEach((String blockId, dynamic value) {
        if (value is! Map<String, dynamic>) return;

        // Merge server data, but only apply to UI for params the user
        // is NOT actively interacting with.
        final Map<String, dynamic> merged = Map<String, dynamic>.from(
          updatedBlockData[blockId] ?? <String, dynamic>{},
        );

        bool blockHadAcceptedParam = false;
        value.forEach((String param, dynamic paramValue) {
          final String key = '$blockId.$param';
          if (_activeInteractions.containsKey(key)) {
            // User is still interacting — keep our optimistic value, discard server echo.
            debugPrint('[BlockData] Suppressing server echo for $key (interaction active)');
          } else {
            merged[param] = paramValue;
            blockHadAcceptedParam = true;
          }
        });

        updatedBlockData[blockId] = merged;
        if (blockHadAcceptedParam) anyAccepted = true;
      });

      if (anyAccepted && !isClosed) {
        emit(
          state.copyWith(
            allBlockData: updatedBlockData,
            isConnected: true,
            clearInactiveReason: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('[BlockData] Parse error: $e');
    }
  }

  // ── heartbeat (stale-connection detection) ─────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _checkLiveness();
    });
  }

  /// Checks whether data has been received within [_staleThreshold].
  /// Also re-sends the config subscription message as a keepalive so the
  /// server knows we're still listening.
  void _checkLiveness() {
    if (_intentionallyStopped || isClosed) return;

    // Re-send the subscription as a keepalive / data refresh.
    if (_networkClient.webSocketService.isConnected) {
      _sendConfigSubscription();
    }

    if (_lastDataReceivedAt == null) return;

    final Duration elapsed = DateTime.now().difference(_lastDataReceivedAt!);
    if (elapsed > _staleThreshold) {
      debugPrint(
        '[BlockData] No data for ${elapsed.inSeconds}s — treating as stale, reconnecting…',
      );
      _forceReconnect();
    }
  }

  // ── reconnection ──────────────────────────────────────────────────────────

  /// Tears down the current connection unconditionally and starts a fresh one.
  void _forceReconnect() {
    _cancelWebsocket();
    if (!isClosed) {
      emit(state.copyWith(isConnected: false));
    }
    // Small delay to let the old socket fully release.
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(milliseconds: 500), () {
      if (isClosed) return;
      startWebsocket();
    });
  }

  void _handleUnexpectedDisconnect() {
    _cancelWebsocket();
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

    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    if (!vm.isInControlMode) return;

    debugPrint(
      '[BlockData] Scheduling reconnect in ${_reconnectDelay.inSeconds}s…',
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
      startWebsocket();
    });
  }

  // ── teardown ───────────────────────────────────────────────────────────────

  void stopWebsocket({required BlockDataInactiveReason reason}) {
    debugPrint('[BlockData] Stopping WebSocket — reason: $reason');
    _intentionallyStopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectDelay = const Duration(seconds: 2);
    _lastDataReceivedAt = null;

    // Clean up new maps
    for (final Timer e in _activeInteractions.values) {
      e.cancel();
    }
    _activeInteractions.clear();
    for (final dynamic e in _pendingSends.values) {
      e.timer.cancel();
    }
    _pendingSends.clear();

    // Remove old in-flight map (no longer needed)
    // _inFlightBlocks.clear();  ← delete _inFlightBlocks entirely

    _cancelWebsocket();
    emit(
      BlockDataState(
        allBlockData: const <String, Map<String, dynamic>>{},
        isConnected: false,
        inactiveReason: reason,
      ),
    );
  }

  void _cancelWebsocket() {
    _isConnecting = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    // Fire-and-forget: disconnect is best-effort cleanup.
    _networkClient.disconnectWebSocket();
  }

  // ── REST-based block data (fallback / on-demand) ───────────────────────────

  Future<Map<String, dynamic>?> getBlockData({required String blockId}) async {
    // Prefer WebSocket-supplied data if available.
    final Map<String, dynamic>? wsData = state.allBlockData[blockId];
    if (wsData != null && wsData.isNotEmpty) {
      emit(state.copyWith(blockId: blockId, blockData: wsData));
      return wsData;
    }

    // Fallback to REST API.
    try {
      final ResponseCallback<Map<String, dynamic>?> response = await _networkClient.get(
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
          if (blockData["exists"] == true) {
            final Map<String, dynamic> currentValue = blockData["value"] as Map<String, dynamic>;
            // Merge into allBlockData so subsequent callers get it from cache.
            final Map<String, Map<String, dynamic>> updated = Map<String, Map<String, dynamic>>.from(state.allBlockData);
            updated[blockId] = currentValue;
            emit(state.copyWith(blockId: blockId, blockData: currentValue, allBlockData: updated));
            return currentValue;
          }
        } catch (ex) {
          FusionLogger.log(tag: LogTag.dspConfig, message: "Error parsing block data for $blockId: $ex");
        }
      } else {
        FusionLogger.log(tag: LogTag.dspConfig, message: "Failed to fetch block data for $blockId: ${response.message}");
      }
    } catch (ex) {
      FusionLogger.log(tag: LogTag.dspConfig, message: "Error fetching block data for $blockId: $ex");
    }
    return null;
  }

  /// Counter used to generate unique request IDs for WebSocket patch messages.
  int _patchRequestCounter = 0;

  Future<void> updateBlockParameter({
    required String blockId,
    required String parameter,
    required dynamic value,
    int? dimension,
  }) async {
    final String interactionKey = '$blockId.$parameter';

    // 1. Write optimistically to local state immediately — UI stays snappy.
    final Map<String, Map<String, dynamic>> optimistic = Map<String, Map<String, dynamic>>.from(state.allBlockData);
    final Map<String, dynamic> blockCopy = Map<String, dynamic>.from(
      optimistic[blockId] ?? <String, dynamic>{},
    );
    blockCopy[parameter] = value;
    optimistic[blockId] = blockCopy;
    if (!isClosed) emit(state.copyWith(allBlockData: optimistic));

    // 2. Mark this param as "user is interacting" — resets on every call.
    _activeInteractions[interactionKey]?.cancel();
    _activeInteractions[interactionKey] = Timer(_interactionCooldown, () {
      _activeInteractions.remove(interactionKey);
      debugPrint('[BlockData] Interaction released for $interactionKey');
    });

    // 3. Debounce the actual network send — only fires after user pauses.
    _pendingSends[interactionKey]?.timer.cancel();
    _pendingSends[interactionKey] = (
      value: value,
      dimension: dimension,
      timer: Timer(_sendDebounce, () async {
        _pendingSends.remove(interactionKey);
        await _flushParameterUpdate(
          blockId: blockId,
          parameter: parameter,
          value: value,
          dimension: dimension,
        );
      }),
    );
  }

  Future<void> updateBlockParameterViaAPi({required String blockId, required String parameter, required dynamic value, int? dimension}) async {
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
      final ResponseCallback<dynamic> response = await _networkClient.patch(
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

  /// The actual network call — called after debounce settles.
  Future<void> _flushParameterUpdate({
    required String blockId,
    required String parameter,
    required dynamic value,
    int? dimension,
  }) async {
    try {
      final Map<String, dynamic> dataPayload =
          dimension == null
              ? <String, dynamic>{
                "settings": <String, dynamic>{
                  "audio": <String, dynamic>{
                    blockId: <String, dynamic>{parameter: value},
                  },
                },
              }
              : <String, dynamic>{
                "settings": <String, dynamic>{
                  "audio": <String, dynamic>{
                    blockId: <String, dynamic>{
                      parameter: _buildDimensionList(value, dimension),
                    },
                  },
                },
              };

      if (_networkClient.webSocketService.isConnected) {
        _sendPatchConfig(dataPayload);
      } else {
        await _ensureWebSocketConnected();
        if (_networkClient.webSocketService.isConnected) {
          _sendPatchConfig(dataPayload);
        } else {
          final ResponseCallback<dynamic> response = await _networkClient.patch(
            api: FusionApiEndpoint.fusionValue,
            isSecure: false,
            urlParameters: dimension != null ? <String, dynamic>{"key": "settings.audio.$blockId.$parameter[$dimension]"} : null,
            baseUrlToOverride: serviceLocator<ProjectViewModel>().virtualIP,
            data: dimension != null ? <String, dynamic>{"value": value} : dataPayload,
          );
          if (!response.success) {
            FusionLogger.log(
              tag: LogTag.dspConfig,
              message: "Failed to update $blockId.$parameter: ${response.message}",
            );
          }
        }
      }
    } catch (ex) {
      FusionLogger.log(
        tag: LogTag.dspConfig,
        message: "Error updating $blockId.$parameter: $ex",
      );
    }
  }

  /// Sends a `patch_config` WebSocket message with the given data payload.
  void _sendPatchConfig(Map<String, dynamic> dataPayload) {
    _patchRequestCounter++;
    final Map<String, dynamic> wsMessage = <String, dynamic>{
      "id": "patch-$_patchRequestCounter",
      "version": 1,
      "type": "patch_config",
      "data": dataPayload,
    };
    _networkClient.sendWebSocketMessage(wsMessage);
  }

  /// Tries to establish a WebSocket connection if not already connected.
  /// Awaits a short delay to allow the connection handshake to complete.
  Future<void> _ensureWebSocketConnected() async {
    if (_networkClient.webSocketService.isConnected) return;

    final String? virtualIP = serviceLocator<ProjectViewModel>().virtualIP;
    if (virtualIP == null || virtualIP.isEmpty) return;

    final String wsHost = virtualIP.contains(':') ? virtualIP : '$virtualIP:8080';
    final String wsUrl = 'ws://$wsHost/ws';

    try {
      await _networkClient.connectWebSocket(url: wsUrl);
      // Give the handshake a moment to complete.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (_networkClient.webSocketService.isConnected) {
        // Re-subscribe for config updates on the fresh connection.
        _sendConfigSubscription();
        // If there's no active listener yet, start one.
        if (_webSocketSubscription == null) {
          await startWebsocket();
        }
      }
    } catch (e) {
      debugPrint('[BlockData] _ensureWebSocketConnected failed: $e');
    }
  }

  /// Builds a sparse list with [value] at [dimension] index and null elsewhere,
  /// used when updating a single dimension of an array parameter.
  List<dynamic> _buildDimensionList(dynamic value, int dimension) {
    final List<dynamic> list = List<dynamic>.filled(dimension + 1, null);
    list[dimension] = value;
    return list;
  }
}
