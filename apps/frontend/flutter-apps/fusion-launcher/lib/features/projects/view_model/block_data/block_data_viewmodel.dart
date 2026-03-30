import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

part 'block_data_viewmodel_state.dart';

class BlockDataViewmodel extends Cubit<BlockDataState> {
  BlockDataViewmodel() : super(BlockDataState()) {
    _attachControlModeListener();
  }

  /// Listens to [ProjectViewModel] state changes and reacts to
  /// [isInControlMode] flipping on/off.
  StreamSubscription<dynamic>? _controlModeSubscription;

  @override
  Future<void> close() {
    _controlModeSubscription?.cancel();
    _stopWebsocket();
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
      // startWebsocket();
    } else {
      // _stopWebsocket();
    }
  }

  StreamSubscription<ResponseCallback<dynamic>>? _webSocketSubscription;

  void startWebsocket() async {
    final String? virtualIP = serviceLocator<ProjectViewModel>().virtualIP;

    if (virtualIP == null || virtualIP.isEmpty) {
      FusionLogger.log(tag: LogTag.dspConfig, message: "Cannot start WebSocket: virtualIP is null or empty");
      return;
    }

    // Construct the WebSocket URL.
    // Note: Adjust the port and path (e.g., ':8080/ws') to match your backend exactly.
    final String wsUrl = "ws://$virtualIP/ws";

    final FusionNetworkClient networkClient = serviceLocator<FusionNetworkClient>();

    // 1. Initiate the connection
    final ResponseCallback<dynamic> connectResponse = await networkClient.connectWebSocket(url: wsUrl);

    if (!connectResponse.success) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Failed to connect to WS at $wsUrl: ${connectResponse.message}");
      return;
    }

    // 2. Clear any existing listener to prevent memory leaks
    await _webSocketSubscription?.cancel();

    // 3. Listen to the incoming message stream
    _webSocketSubscription = networkClient.webSocketMessages.listen(
      (ResponseCallback<dynamic> response) {
        if (response.success && response.data != null) {
          try {
            // TODO: Implement your specific business logic here.
            // Example: Check if the incoming data matches the current blockId,
            // then emit a new state with the updated parameter.
            /*
             final incomingData = response.data as Map<String, dynamic>;
             if (incomingData['blockId'] == state.blockId) {
               emit(state.copyWith(blockData: incomingData['value']));
             }
             */
            FusionLogger.log(tag: LogTag.dspConfig, message: "WS Stream Data: ${response.data}");
          } catch (ex) {
            FusionLogger.log(tag: LogTag.exceptions, message: "Error parsing WS data: $ex");
          }
        } else {
          FusionLogger.log(tag: LogTag.dspConfig, message: "WS Stream Message: ${response.message}");
        }
      },
      onError: (dynamic error) {
        FusionLogger.log(tag: LogTag.exceptions, message: "WebSocket stream error: $error");
      },
      onDone: () {
        FusionLogger.log(tag: LogTag.network, message: "WebSocket stream closed by server");
        _stopWebsocket();
      },
    );
  }

  // Updated stop method to also close the actual socket connection
  void _stopWebsocket() {
    _webSocketSubscription?.cancel();
    _webSocketSubscription = null;

    // Disconnect the client so the socket doesn't stay open in the background
    serviceLocator<FusionNetworkClient>().disconnectWebSocket();
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
            final Map<String, dynamic> currentValue = blockData["value"] as Map<String, dynamic>;
            emit(state.copyWith(blockId: blockId, blockData: currentValue));
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
