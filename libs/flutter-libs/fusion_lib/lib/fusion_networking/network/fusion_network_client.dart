import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_networking/network/rest_client/dio_client.dart';

import '../../service/auth/fusion_auth_service.dart';
import 'dartzmq_stub.dart' if (dart.library.io) 'package:dartzmq/dartzmq.dart';

enum ServerUpdateType { forceUpdate, metadata, localValue }

class FusionNetworkClient {
  final DioClient httpClient;
  final SharedPreferencesHandler sharedPreferencesHandler;
  final TelemetryData telemetryData;
  final FusionSecureStorage secureStorageService;
  final FusionAuthService fusionAuthService;
  final String apiBaseUrl;
  final WebSocketService webSocketService;

  FusionNetworkClient({
    required this.httpClient,
    required this.sharedPreferencesHandler,
    required this.telemetryData,
    required this.secureStorageService,
    required this.fusionAuthService,
    required this.apiBaseUrl,
    required this.webSocketService,
  });

  ZSocket? subscriberSocket;
  final ZContext _context = ZContext();

  // ── WebSocket ping/pong heartbeat ─────────────────────────────────────────
  //
  // Managed here so every consumer gets liveness events from a single source.
  // Consumers listen to [wsAliveStream]; they do not implement ping/pong themselves.

  /// Broadcasts `false` when a pong timeout occurs (connection is dead).
  /// Consumers should trigger a reconnect on `false`.
  final StreamController<bool> _wsAliveController = StreamController<bool>.broadcast();
  Stream<bool> get wsAliveStream => _wsAliveController.stream;

  Timer? _wsPingTimer;
  Timer? _wsPongTimeoutTimer;
  StreamSubscription<dynamic>? _wsPongListenerSubscription;
  bool _wsWaitingForPong = false;

  static const Duration _kWsPingInterval = Duration(seconds: 8);
  static const Duration _kWsPongTimeout = Duration(seconds: 5);

  String geApiUrl(FusionApiEndpoint api, {String? baseUrlToOverride, bool isSecure = true}) {
    if (baseUrlToOverride != null) {
      return isSecure
          ? "https://$baseUrlToOverride${api.path}"
          : "http://${baseUrlToOverride.contains(':') ? baseUrlToOverride : '$baseUrlToOverride:8080'}${api.path}";
    }
    if (api.type == FusionApiType.droServer) {
      return "http://localhost:8080${api.path}";
    } else if (api.type == FusionApiType.fusionServer) {
      return "http://TODO:8080${api.path}";
    } else if (api.type == FusionApiType.backendServer) {
      return "$apiBaseUrl${api.path}";
    } else {
      throw Exception("Invalid API type: ${api.type}");
    }
  }

  // return token fro shared preferences only if FusionApiEndpoint api == FusionApiType.backendServer
  Future<String?> getAccessTokenForApi(FusionApiEndpoint api) async {
    if (api.type == FusionApiType.backendServer) {
      final String? storedAccessToken = await fusionAuthService.getValidAccessToken();
      return storedAccessToken;
    }
    return null;
  }

  bool canCallCloudApis(FusionApiType api) => api == FusionApiType.backendServer && !HAS_CLOUD_ACCESS;

  Future<ResponseCallback<T>> get<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? urlParameters,
    String? additionalPath,
    String? baseUrlToOverride,
    bool isSecure = true,
    T Function(dynamic)? fromJson,
  }) async {
    if (canCallCloudApis(api.type)) return ResponseCallback<T>(success: false, message: "Access to APIs is not allowed.", statusCode: null);

    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure)}/$additionalPath"
          : geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure);

      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final bool isBinary = T == Uint8List;

      final Options options = Options(headers: <String, dynamic>{...headers}, responseType: isBinary ? ResponseType.bytes : ResponseType.json);

      final Response<dynamic> response = await httpClient.dioInstance.get(url, options: options, queryParameters: urlParameters);

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        if (isBinary) {
          return ResponseCallback<T>(success: true, message: "Binary file fetched successfully", data: response.data as T?, statusCode: response.statusCode);
        } else {
          T? data = fromJson != null ? fromJson(response.data) : response.data;
          return ResponseCallback<T>.success(data, statusCode: response.statusCode);
        }
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode), statusCode: response.statusCode);
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.get() - $ex", statusCode: null);
    }
  }

  Future<ResponseCallback<T>> put<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? urlParameters,
    dynamic data,
    String? additionalPath,
    String? baseUrlToOverride,
    bool isSecure = true,
    T Function(dynamic)? fromJson,
  }) async {
    if (canCallCloudApis(api.type)) return ResponseCallback<T>(success: false, message: "Access to APIs is not allowed.", statusCode: null);

    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure)}/$additionalPath"
          : geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure);

      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final Options options = Options(headers: <String, dynamic>{...headers});

      final Response<dynamic> response = await httpClient.dioInstance.put(url, options: options, data: data);

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T data = fromJson != null ? fromJson(response.data) : response.data;
        return ResponseCallback<T>.success(data, statusCode: response.statusCode);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode), statusCode: response.statusCode);
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.put() - $ex");
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.put() - $ex", statusCode: null);
    }
  }

  Future<ResponseCallback<T>> post<T>({
    required FusionApiEndpoint api,
    dynamic data,
    String? additionalPath,
    String? baseUrlToOverride,
    Map<String, dynamic>? urlParameters,
    bool isSecure = true,
    T Function(dynamic)? fromJson,
  }) async {
    if (canCallCloudApis(api.type)) return ResponseCallback<T>(success: false, message: "Access to APIs is not allowed.", statusCode: null);

    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure)}/$additionalPath"
          : geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure);

      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      /// Detect content type based on data type
      final Options options = Options(
        headers: <String, dynamic>{...headers, if (data is FormData) 'Content-Type': 'multipart/form-data' else 'Content-Type': 'application/json'},
      );

      // final dynamic body = data is FormData ? data : jsonEncode(data);

      final Response<dynamic> response = await httpClient.dioInstance.post(
        url,
        data: data,
        options: options,
        queryParameters: urlParameters,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T data = fromJson != null ? fromJson(response.data) : response.data;
        return ResponseCallback<T>.success(data, statusCode: response.statusCode);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode), statusCode: response.statusCode);
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.post() - $ex");
      return ResponseCallback.failure("Exception in FusionNetworkClient.post() - $ex", statusCode: null);
    }
  }

  Future<ResponseCallback<T>> patch<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? data,
    Map<String, dynamic>? urlParameters,
    String? additionalPath,
    String? baseUrlToOverride,
    bool isSecure = true,
    T Function(dynamic)? fromJson,
  }) async {
    if (canCallCloudApis(api.type)) return ResponseCallback<T>(success: false, message: "Access to APIs is not allowed.", statusCode: null);

    try {
      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      /// Detect content type based on data type
      final Options options = Options(
        headers: <String, dynamic>{...headers, if (data is FormData) 'Content-Type': 'multipart/form-data' else 'Content-Type': 'application/json'},
      );

      final Response<dynamic> response = await httpClient.dioInstance.patch(
        additionalPath != null
            ? "${geApiUrl(
                api,
                baseUrlToOverride: baseUrlToOverride,
                isSecure: isSecure,
              )}/$additionalPath"
            : geApiUrl(
                api,
                baseUrlToOverride: baseUrlToOverride,
                isSecure: isSecure,
              ),
        options: options,
        data: data,
        queryParameters: urlParameters,
      );
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T data = fromJson != null ? fromJson(response.data) : response.data;
        return ResponseCallback<T>.success(data, statusCode: response.statusCode);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode), statusCode: response.statusCode);
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      // FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.patch() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.patch() - $ex", statusCode: null);
    }
  }

  Future<ResponseCallback<T>> delete<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? urlParameters,
    T Function(dynamic)? fromJson,
    String? additionalPath,
    bool isSecure = true,
    String? baseUrlToOverride,
  }) async {
    if (canCallCloudApis(api.type)) return ResponseCallback<T>(success: false, message: "Access to APIs is not allowed.", statusCode: null);

    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure)}/$additionalPath"
          : geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure);

      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      /// Detect content type based on data type
      final Options options = Options(headers: <String, dynamic>{...headers});

      final Response<dynamic> response = await httpClient.dioInstance.delete(url, options: options, queryParameters: urlParameters);

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T? data = fromJson != null ? fromJson(response.data) : response.data;
        return ResponseCallback<T>.success(data, statusCode: response.statusCode);
      } else if (response.statusCode == 204 || response.statusCode == 200 || response.statusCode == 202) {
        return ResponseCallback<T>(success: true, message: "Resource deleted successfully", statusCode: response.statusCode);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode), statusCode: response.statusCode);
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      // FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.delete() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.delete() - $ex", statusCode: null);
    }
  }

  // Downloads a file from an external pre-signed URL (e.g. S3) directly to disk.
  // Uses a clean Dio instance with no auth headers — pre-signed URLs are self-authenticating
  // and adding an Authorization header causes the remote server to reject the request.
  // Streams the response body directly to disk to avoid loading the entire file into RAM.
  Future<ResponseCallback<T>> downloadFile<T>({
    required String url,
    required String savePath,
    required CancelToken cancelToken,
    required void Function(int received, int total) onProgress,
  }) async {
    final isNetworkUrl = url.startsWith('http://') || url.startsWith('https://');
    if (isNetworkUrl && !HAS_CLOUD_ACCESS) return ResponseCallback<T>(success: false, message: "Access to APIs is not allowed.", statusCode: null);

    final Dio cleanDio = Dio();
    try {
      await cleanDio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
        options: Options(
          // No Authorization header — the pre-signed URL carries its own credentials.
          headers: <String, dynamic>{'Accept': '*/*'},
        ),
      );
      return ResponseCallback<T>(success: true, message: 'File downloaded successfully', statusCode: 200);
    } catch (ex) {
      debugPrint('Exception in FusionNetworkClient.downloadFile() - $ex');
      return ResponseCallback<T>(success: false, message: 'Exception in FusionNetworkClient.downloadFile() - $ex', statusCode: null);
    } finally {
      cleanDio.close();
    }
  }

  Future<ResponseCallback<T>> connect<T>({required String vip}) async {
    if (!HAS_CLOUD_ACCESS) return ResponseCallback<T>(success: false, message: "Access to APIs is not allowed.", statusCode: null);

    try {
      // Close any existing socket to prevent leaks on reconnect.
      if (subscriberSocket != null) {
        try {
          subscriberSocket?.close();
        } catch (_) {
          // Best-effort cleanup — the old socket may already be dead.
        }
        subscriberSocket = null;
      }

      await telemetryData.initializeTelemetryAddresses(this, vip);
      subscriberSocket = _context.createSocket(SocketType.sub);
      for (String url in TelemetryData.telemetryAddresses) {
        subscriberSocket!.connect(url);
        FusionLogger.log(tag: LogTag.zmq, message: "ZMQ Subscriber Connected to $url!!!");
      }
      subscriberSocket!.subscribe(""); // Subscribe to all topics
      return ResponseCallback<T>(success: true, message: "ZMQ Subscriber Connected", statusCode: 200);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.connect() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.connect() - $ex", statusCode: null);
    }
  }

  Future<ResponseCallback<T>> disconnect<T>() async {
    try {
      if (subscriberSocket != null) {
        subscriberSocket?.close();
        subscriberSocket = null;
      }
      FusionLogger.log(tag: LogTag.zmq, message: "ZMQ Socket Disconnected!!!");
      return ResponseCallback<T>(success: true, message: "ZMQ Socket Disconnected", statusCode: 200);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.disconnect() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.disconnect() - $ex", statusCode: null);
    }
  }

  Stream<ResponseCallback<dynamic>> get responseMessages async* {
    if (subscriberSocket == null) {
      yield ResponseCallback<dynamic>(success: false, message: 'No server socket available', statusCode: null);
      return;
    }

    final ZSocket socket = subscriberSocket!;

    await for (final ZFrame frame in socket.frames) {
      // If the socket was replaced by a reconnect while iterating, stop
      // this generator so the old subscription can be garbage-collected.
      if (subscriberSocket != socket) return;

      try {
        final String message = utf8.decode(frame.payload, allowMalformed: true);
        yield ResponseCallback<dynamic>(success: true, message: "New data received", data: jsonDecode(message), statusCode: 200);
      } catch (ex) {
        yield ResponseCallback<dynamic>(success: false, message: 'Exception in FusionNetworkClient.responseMessages - $ex ', statusCode: null);
      }
    }
  }

  // ── WebSocket heartbeat management ────────────────────────────────────────

  /// Starts periodic ping/pong. Call once after [connectWebSocket] succeeds.
  /// Safe to call multiple times — any running heartbeat is replaced.
  void startWsHeartbeat() {
    stopWsHeartbeat();
    _wsPongListenerSubscription = webSocketService.stream.listen(
      (dynamic message) {
        try {
          final dynamic decoded = jsonDecode(message.toString());
          if (decoded is Map<String, dynamic> && decoded['type'] == 'pong') {
            _handleWsPong();
          }
        } catch (_) {}
      },
      onError: (_) {},
    );
    _wsPingTimer = Timer.periodic(_kWsPingInterval, (_) => _sendWsPing());
  }

  /// Stops the heartbeat and clears all pending timers.
  void stopWsHeartbeat() {
    _wsPingTimer?.cancel();
    _wsPingTimer = null;
    _wsPongTimeoutTimer?.cancel();
    _wsPongTimeoutTimer = null;
    _wsWaitingForPong = false;
    _wsPongListenerSubscription?.cancel();
    _wsPongListenerSubscription = null;
  }

  /// Sends a ping and starts the pong-timeout timer.
  void _sendWsPing() {
    if (!webSocketService.isConnected) {
      FusionLogger.log(tag: LogTag.network, message: '[WS Heartbeat] Ping skipped — not connected.');
      _wsAliveController.add(false);
      return;
    }

    if (_wsWaitingForPong) {
      // Previous ping never got a pong — connection is dead.
      FusionLogger.log(tag: LogTag.network, message: '[WS Heartbeat] Pong timeout — connection dead.');
      stopWsHeartbeat();
      _wsAliveController.add(false);
      return;
    }

    final String pingId = 'ping-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    webSocketService.sendMessage(jsonEncode(<String, dynamic>{
      'id': pingId,
      'version': 1,
      'type': 'ping',
    }));
    _wsWaitingForPong = true;
    // FusionLogger.log(tag: LogTag.network, message: '[WS Heartbeat] Ping sent ($pingId).');

    _wsPongTimeoutTimer?.cancel();
    _wsPongTimeoutTimer = Timer(_kWsPongTimeout, () {
      if (_wsWaitingForPong) {
        FusionLogger.log(tag: LogTag.network, message: '[WS Heartbeat] Pong timeout expired.');
        _wsWaitingForPong = false;
        _wsAliveController.add(false);
      }
    });
  }

  /// Called internally when a pong frame arrives on the WebSocket stream.
  void _handleWsPong() {
    _wsPongTimeoutTimer?.cancel();
    _wsPongTimeoutTimer = null;
    _wsWaitingForPong = false;
    // FusionLogger.log(tag: LogTag.network, message: '[WS Heartbeat] Pong received — connection alive.');
  }

  /// Connects to a WebSocket URL using the injected WebSocketService
  Future<ResponseCallback<T>> connectWebSocket<T>({required String url}) async {
    try {
      webSocketService.connect(url);
      FusionLogger.log(tag: LogTag.network, message: "WebSocket connecting to $url");

      return ResponseCallback<T>(success: true, message: "WebSocket connection initiated", statusCode: 200);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.connectWebSocket() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.connectWebSocket() - $ex", statusCode: null);
    }
  }

  /// Sends a message through the active WebSocket connection
  Future<ResponseCallback<T>> sendWebSocketMessage<T>(dynamic message) async {
    try {
      if (!webSocketService.isConnected) {
        return ResponseCallback<T>(success: false, message: "WebSocket is not connected", statusCode: null);
      }

      // If the message isn't a string (e.g., a Map), JSON encode it
      final dynamic payload = message is String ? message : jsonEncode(message);
      webSocketService.sendMessage(payload);

      FusionLogger.log(tag: LogTag.dspConfig, message: "WS Payload $payload");

      return ResponseCallback<T>(success: true, message: "Message sent successfully", statusCode: 200);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.sendWebSocketMessage() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.sendWebSocketMessage() - $ex", statusCode: null);
    }
  }

  /// Disconnects the active WebSocket connection
  Future<ResponseCallback<T>> disconnectWebSocket<T>() async {
    try {
      stopWsHeartbeat();
      webSocketService.disconnect();
      FusionLogger.log(tag: LogTag.network, message: "WebSocket Disconnected!!!");

      return ResponseCallback<T>(success: true, message: "WebSocket Disconnected", statusCode: 200);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.disconnectWebSocket() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.disconnectWebSocket() - $ex", statusCode: null);
    }
  }

  /// Async* stream to listen to incoming WebSocket messages mapped to ResponseCallback.
  Stream<ResponseCallback<dynamic>> get webSocketMessages async* {
    if (!webSocketService.isConnected) {
      yield ResponseCallback<dynamic>(success: false, message: 'No active WebSocket connection', statusCode: null);
    }

    try {
      await for (final dynamic message in webSocketService.stream) {
        try {
            // Attempt to decode JSON if applicable, otherwise return raw string
          dynamic decodedData;
          try {
            decodedData = jsonDecode(message.toString());
          } catch (_) {
            decodedData = message; // Fallback to raw message
          }

        yield ResponseCallback<dynamic>(success: true, message: "New WebSocket data received", data: decodedData, statusCode: 200);
        } catch (ex) {
          yield ResponseCallback<dynamic>(success: false, message: 'Exception in FusionNetworkClient.webSocketMessages - $ex ', statusCode: null);
        }
      }
    } catch (ex) {
      // WebSocket disconnected — stream error propagated from WebSocketService.
      FusionLogger.log(tag: LogTag.network, message: '[WS] Stream error (connection dropped): $ex');
      yield ResponseCallback<dynamic>(success: false, message: 'WebSocket disconnected: $ex', statusCode: null);
    }
  }
}

enum FusionApiType { fusionServer, droServer, backendServer }

enum FusionApiEndpoint {
  //Fusion Backend endpoints
  process('/process', FusionApiType.droServer), //DRO endpoint
  fusionValue('/value', FusionApiType.fusionServer),
  fusionGetEndPoints('/endpoints', FusionApiType.fusionServer),
  fusionDelete('/clear', FusionApiType.fusionServer),

  //Backend server endpoints
  getProfile("/users/authorization", FusionApiType.backendServer),
  projects("/projects", FusionApiType.backendServer),
  products('/products', FusionApiType.backendServer),
  devicesCloud('/devices', FusionApiType.backendServer),
  firmwareUpdateCheck('/firmware/updates/check', FusionApiType.backendServer),
  firmwareBundleDownloadUrl('/firmware/bundles', FusionApiType.backendServer),
  firmwareUpdateStatus('/firmware/updates/status', FusionApiType.backendServer),

  //fusion server setup apis
  fusionDevice('/devices', FusionApiType.fusionServer),
  setVip('/devices/vip', FusionApiType.fusionServer),
  sapSessions('/sessions', FusionApiType.fusionServer),
  pavaMessages('/pava/messages', FusionApiType.fusionServer),
  sceneSetsActivate('/scene-sets/activate', FusionApiType.fusionServer),
  snapshotsActivate('/snapshots/activate', FusionApiType.fusionServer),
  tasks('/tasks', FusionApiType.fusionServer);

  final String path;
  final FusionApiType type;

  const FusionApiEndpoint(this.path, this.type);
}

extension ApiEndpointTypeCheckExtension on String {
  bool isFusionServerEndpoint() {
    return contains(FusionApiEndpoint.fusionValue.path) ||
        contains(FusionApiEndpoint.fusionGetEndPoints.path) ||
        contains(FusionApiEndpoint.fusionDelete.path) ||
        contains(FusionApiEndpoint.fusionDevice.path) ||
        contains(FusionApiEndpoint.setVip.path) ||
        contains(FusionApiEndpoint.sapSessions.path);
  }

  bool isDroServerEndpoint() {
    return contains(FusionApiEndpoint.process.path);
  }

  bool isBackendServerEndpoint() {
    return contains(FusionApiEndpoint.getProfile.path) || contains(FusionApiEndpoint.projects.path) || contains(FusionApiEndpoint.devicesCloud.path);
  }

  bool isTokenRequired() {
    return isBackendServerEndpoint();
  }
}
