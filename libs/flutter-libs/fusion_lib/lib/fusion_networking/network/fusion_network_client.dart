import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/generated/proto/fusion/websocket.pb.dart' as wsmodel;
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_networking/network/rest_client/dio_client.dart';
import 'package:protobuf/protobuf.dart' as $pb;

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

  String geApiUrl(
    FusionApiEndpoint api, {
    String? baseUrlToOverride,
    bool isSecure = true,
  }) {
    if (baseUrlToOverride != null) {
      final String host = baseUrlToOverride.contains(':')
          ? baseUrlToOverride
          : switch (api.type) {
              FusionApiType.fusionAdminServer => '$baseUrlToOverride:9090',
              _ => '$baseUrlToOverride:8080',
            };
      return isSecure
          ? "https://$baseUrlToOverride${api.path}"
          : "http://$host${api.path}";
    }
    if (api.type == FusionApiType.droServer) {
      return "http://localhost:8080${api.path}";
    } else if (api.type == FusionApiType.fusionServer) {
      return "http://TODO:8080${api.path}";
    } else if (api.type == FusionApiType.fusionAdminServer) {
      return "http://TODO:9090${api.path}";
    } else if (api.type == FusionApiType.backendServer) {
      return "$apiBaseUrl${api.path}";
    } else {
      throw Exception("Invalid API type: ${api.type}");
    }
  }

  // return token fro shared preferences only if FusionApiEndpoint api == FusionApiType.backendServer
  Future<String?> getAccessTokenForApi(FusionApiEndpoint api) async {
    if (api.type == FusionApiType.backendServer) {
      final String? storedAccessToken = await fusionAuthService
          .getValidAccessToken();
      return storedAccessToken;
    }
    return null;
  }

  bool canCallCloudApis(FusionApiType api) =>
      api == FusionApiType.backendServer && !HAS_CLOUD_ACCESS;

  Future<ResponseCallback<T>> get<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? urlParameters,
    String? additionalPath,
    String? baseUrlToOverride,
    bool isSecure = true,
    T Function(dynamic)? fromJson,
  }) async {
    if (canCallCloudApis(api.type))
      return ResponseCallback<T>(
        success: false,
        message: "Access to APIs is not allowed.",
        statusCode: null,
      );

    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure)}/$additionalPath"
          : geApiUrl(
              api,
              baseUrlToOverride: baseUrlToOverride,
              isSecure: isSecure,
            );

      final Map<String, dynamic> headers =
          httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final bool isBinary = T == Uint8List;

      final Options options = Options(
        headers: <String, dynamic>{...headers},
        responseType: isBinary ? ResponseType.bytes : ResponseType.json,
      );

      final Response<dynamic> response = await httpClient.dioInstance.get(
        url,
        options: options,
        queryParameters: urlParameters,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        if (isBinary) {
          return ResponseCallback<T>(
            success: true,
            message: "Binary file fetched successfully",
            data: response.data as T?,
            statusCode: response.statusCode,
          );
        } else {
          T? data = fromJson != null ? fromJson(response.data) : response.data;
          return ResponseCallback<T>.success(
            data,
            statusCode: response.statusCode,
          );
        }
      } else {
        return ResponseCallback<T>(
          success: false,
          message: httpClient.handleStatusCodeError(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      return ResponseCallback<T>(
        success: false,
        message: "Exception in FusionNetworkClient.get() - $ex",
        statusCode: null,
      );
    }
  }

  Future<ResponseCallback<T>> getProto<T extends $pb.GeneratedMessage>({
    required FusionApiEndpoint api,
    required T Function() create,
    Map<String, dynamic>? urlParameters,
    String? additionalPath,
    String? baseUrlToOverride,
    bool isSecure = true,
  }) {
    return get<T>(
      api: api,
      urlParameters: urlParameters,
      additionalPath: additionalPath,
      baseUrlToOverride: baseUrlToOverride,
      isSecure: isSecure,
      fromJson: (dynamic json) => decodeProtoJson<T>(json, create),
    );
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
    if (canCallCloudApis(api.type))
      return ResponseCallback<T>(
        success: false,
        message: "Access to APIs is not allowed.",
        statusCode: null,
      );

    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure)}/$additionalPath"
          : geApiUrl(
              api,
              baseUrlToOverride: baseUrlToOverride,
              isSecure: isSecure,
            );

      final Map<String, dynamic> headers =
          httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final Options options = Options(headers: <String, dynamic>{...headers});

      final Response<dynamic> response = await httpClient.dioInstance.put(
        url,
        options: options,
        data: _normalizeRequestBody(data),
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T data = fromJson != null ? fromJson(response.data) : response.data;
        return ResponseCallback<T>.success(
          data,
          statusCode: response.statusCode,
        );
      } else {
        return ResponseCallback<T>(
          success: false,
          message: httpClient.handleStatusCodeError(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.put() - $ex");
      return ResponseCallback<T>(
        success: false,
        message: "Exception in FusionNetworkClient.put() - $ex",
        statusCode: null,
      );
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
    if (canCallCloudApis(api.type))
      return ResponseCallback<T>(
        success: false,
        message: "Access to APIs is not allowed.",
        statusCode: null,
      );

    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure)}/$additionalPath"
          : geApiUrl(
              api,
              baseUrlToOverride: baseUrlToOverride,
              isSecure: isSecure,
            );

      final Map<String, dynamic> headers =
          httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      /// Detect content type based on data type
      final Options options = Options(
        headers: <String, dynamic>{
          ...headers,
          if (data is FormData)
            'Content-Type': 'multipart/form-data'
          else
            'Content-Type': 'application/json',
        },
      );

      // final dynamic body = data is FormData ? data : jsonEncode(data);

      final Response<dynamic> response = await httpClient.dioInstance.post(
        url,
        data: _normalizeRequestBody(data),
        options: options,
        queryParameters: urlParameters,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T data = fromJson != null ? fromJson(response.data) : response.data;
        return ResponseCallback<T>.success(
          data,
          statusCode: response.statusCode,
        );
      } else {
        return ResponseCallback<T>(
          success: false,
          message: httpClient.handleStatusCodeError(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.post() - $ex");
      return ResponseCallback.failure(
        "Exception in FusionNetworkClient.post() - $ex",
        statusCode: null,
      );
    }
  }

  Future<ResponseCallback<T>> patch<T>({
    required FusionApiEndpoint api,
    dynamic data,
    Map<String, dynamic>? urlParameters,
    String? additionalPath,
    String? baseUrlToOverride,
    bool isSecure = true,
    T Function(dynamic)? fromJson,
  }) async {
    if (canCallCloudApis(api.type))
      return ResponseCallback<T>(
        success: false,
        message: "Access to APIs is not allowed.",
        statusCode: null,
      );

    try {
      final Map<String, dynamic> headers =
          httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      /// Detect content type based on data type
      final Options options = Options(
        headers: <String, dynamic>{
          ...headers,
          if (data is FormData)
            'Content-Type': 'multipart/form-data'
          else
            'Content-Type': 'application/json',
        },
      );

      final Response<dynamic> response = await httpClient.dioInstance.patch(
        additionalPath != null
            ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure)}/$additionalPath"
            : geApiUrl(
                api,
                baseUrlToOverride: baseUrlToOverride,
                isSecure: isSecure,
              ),
        options: options,
        data: _normalizeRequestBody(data),
        queryParameters: urlParameters,
      );
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T data = fromJson != null ? fromJson(response.data) : response.data;
        return ResponseCallback<T>.success(
          data,
          statusCode: response.statusCode,
        );
      } else {
        return ResponseCallback<T>(
          success: false,
          message: httpClient.handleStatusCodeError(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      // FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.patch() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(
        success: false,
        message: "Exception in FusionNetworkClient.patch() - $ex",
        statusCode: null,
      );
    }
  }

  Future<ResponseCallback<FusionStateSnapshot>> getStateSnapshot({
    required String baseUrlToOverride,
    bool isSecure = true,
  }) {
    return get<FusionStateSnapshot>(
      api: FusionApiEndpoint.fusionState,
      baseUrlToOverride: baseUrlToOverride,
      isSecure: isSecure,
      fromJson: FusionStateSnapshot.fromJson,
    );
  }

  Future<ResponseCallback<FusionStateValue<T>>> getStateValue<T>({
    required String key,
    required String baseUrlToOverride,
    required T Function(dynamic value) decodeValue,
    bool isSecure = true,
  }) {
    return get<FusionStateValue<T>>(
      api: FusionApiEndpoint.fusionState,
      baseUrlToOverride: baseUrlToOverride,
      isSecure: isSecure,
      urlParameters: <String, dynamic>{'key': key},
      fromJson: (dynamic json) =>
          FusionStateValue<T>.fromJson(json, decodeValue),
    );
  }

  Future<ResponseCallback<T>> delete<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? urlParameters,
    T Function(dynamic)? fromJson,
    String? additionalPath,
    bool isSecure = true,
    String? baseUrlToOverride,
  }) async {
    if (canCallCloudApis(api.type))
      return ResponseCallback<T>(
        success: false,
        message: "Access to APIs is not allowed.",
        statusCode: null,
      );

    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride, isSecure: isSecure)}/$additionalPath"
          : geApiUrl(
              api,
              baseUrlToOverride: baseUrlToOverride,
              isSecure: isSecure,
            );

      final Map<String, dynamic> headers =
          httpClient.dioInstance.options.headers;
      final String? token = await getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      /// Detect content type based on data type
      final Options options = Options(headers: <String, dynamic>{...headers});

      final Response<dynamic> response = await httpClient.dioInstance.delete(
        url,
        options: options,
        queryParameters: urlParameters,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T? data = fromJson != null ? fromJson(response.data) : response.data;
        return ResponseCallback<T>.success(
          data,
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 204 ||
          response.statusCode == 200 ||
          response.statusCode == 202) {
        return ResponseCallback<T>(
          success: true,
          message: "Resource deleted successfully",
          statusCode: response.statusCode,
        );
      } else {
        return ResponseCallback<T>(
          success: false,
          message: httpClient.handleStatusCodeError(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      // FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.delete() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(
        success: false,
        message: "Exception in FusionNetworkClient.delete() - $ex",
        statusCode: null,
      );
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
    final isNetworkUrl =
        url.startsWith('http://') || url.startsWith('https://');
    if (isNetworkUrl && !HAS_CLOUD_ACCESS)
      return ResponseCallback<T>(
        success: false,
        message: "Access to APIs is not allowed.",
        statusCode: null,
      );

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
      return ResponseCallback<T>(
        success: true,
        message: 'File downloaded successfully',
        statusCode: 200,
      );
    } catch (ex) {
      debugPrint('Exception in FusionNetworkClient.downloadFile() - $ex');
      return ResponseCallback<T>(
        success: false,
        message: 'Exception in FusionNetworkClient.downloadFile() - $ex',
        statusCode: null,
      );
    } finally {
      cleanDio.close();
    }
  }

  Future<ResponseCallback<T>> connect<T>({required String vip}) async {
    if (!HAS_CLOUD_ACCESS)
      return ResponseCallback<T>(
        success: false,
        message: "Access to APIs is not allowed.",
        statusCode: null,
      );

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
        FusionLogger.log(
          tag: LogTag.zmq,
          message: "ZMQ Subscriber Connected to $url!!!",
        );
      }
      subscriberSocket!.subscribe(""); // Subscribe to all topics
      return ResponseCallback<T>(
        success: true,
        message: "ZMQ Subscriber Connected",
        statusCode: 200,
      );
    } catch (ex) {
      FusionLogger.log(
        tag: LogTag.exceptions,
        message: "Exception in FusionNetworkClient.connect() - $ex",
        logLevel: LogLevel.error,
      );
      return ResponseCallback<T>(
        success: false,
        message: "Exception in FusionNetworkClient.connect() - $ex",
        statusCode: null,
      );
    }
  }

  Future<ResponseCallback<T>> disconnect<T>() async {
    try {
      if (subscriberSocket != null) {
        subscriberSocket?.close();
        subscriberSocket = null;
      }
      FusionLogger.log(tag: LogTag.zmq, message: "ZMQ Socket Disconnected!!!");
      return ResponseCallback<T>(
        success: true,
        message: "ZMQ Socket Disconnected",
        statusCode: 200,
      );
    } catch (ex) {
      FusionLogger.log(
        tag: LogTag.exceptions,
        message: "Exception in FusionNetworkClient.disconnect() - $ex",
        logLevel: LogLevel.error,
      );
      return ResponseCallback<T>(
        success: false,
        message: "Exception in FusionNetworkClient.disconnect() - $ex",
        statusCode: null,
      );
    }
  }

  Stream<ResponseCallback<dynamic>> get responseMessages async* {
    if (subscriberSocket == null) {
      yield ResponseCallback<dynamic>(
        success: false,
        message: 'No server socket available',
        statusCode: null,
      );
      return;
    }

    final ZSocket socket = subscriberSocket!;

    await for (final ZFrame frame in socket.frames) {
      // If the socket was replaced by a reconnect while iterating, stop
      // this generator so the old subscription can be garbage-collected.
      if (subscriberSocket != socket) return;

      try {
        final String message = utf8.decode(frame.payload, allowMalformed: true);
        yield ResponseCallback<dynamic>(
          success: true,
          message: "New data received",
          data: jsonDecode(message),
          statusCode: 200,
        );
      } catch (ex) {
        yield ResponseCallback<dynamic>(
          success: false,
          message: 'Exception in FusionNetworkClient.responseMessages - $ex ',
          statusCode: null,
        );
      }
    }
  }

  /// Connects to a WebSocket URL using the injected WebSocketService
  Future<ResponseCallback<T>> connectWebSocket<T>({required String url}) async {
    try {
      webSocketService.connect(url);
      FusionLogger.log(
        tag: LogTag.network,
        message: "WebSocket connecting to $url",
      );

      return ResponseCallback<T>(
        success: true,
        message: "WebSocket connection initiated",
        statusCode: 200,
      );
    } catch (ex) {
      FusionLogger.log(
        tag: LogTag.exceptions,
        message: "Exception in FusionNetworkClient.connectWebSocket() - $ex",
        logLevel: LogLevel.error,
      );
      return ResponseCallback<T>(
        success: false,
        message: "Exception in FusionNetworkClient.connectWebSocket() - $ex",
        statusCode: null,
      );
    }
  }

  /// Sends a message through the active WebSocket connection
  Future<ResponseCallback<T>> sendWebSocketMessage<T>(dynamic message) async {
    try {
      if (!webSocketService.isConnected) {
        return ResponseCallback<T>(
          success: false,
          message: "WebSocket is not connected",
          statusCode: null,
        );
      }

      // If the message isn't a string (e.g., a Map), JSON encode it
      final dynamic payload = message is String
          ? message
          : jsonEncode(_normalizeRequestBody(message));
      webSocketService.sendMessage(payload);

      FusionLogger.log(tag: LogTag.dspConfig, message: "WS Payload $payload");

      return ResponseCallback<T>(
        success: true,
        message: "Message sent successfully",
        statusCode: 200,
      );
    } catch (ex) {
      FusionLogger.log(
        tag: LogTag.exceptions,
        message:
            "Exception in FusionNetworkClient.sendWebSocketMessage() - $ex",
        logLevel: LogLevel.error,
      );
      return ResponseCallback<T>(
        success: false,
        message:
            "Exception in FusionNetworkClient.sendWebSocketMessage() - $ex",
        statusCode: null,
      );
    }
  }

  Future<ResponseCallback<T>> sendWebSocketRequest<T>(
    wsmodel.WebSocketRequest request,
  ) {
    return sendWebSocketMessage<T>(request);
  }

  /// Disconnects the active WebSocket connection
  Future<ResponseCallback<T>> disconnectWebSocket<T>() async {
    try {
      webSocketService.disconnect();
      FusionLogger.log(
        tag: LogTag.network,
        message: "WebSocket Disconnected!!!",
      );

      return ResponseCallback<T>(
        success: true,
        message: "WebSocket Disconnected",
        statusCode: 200,
      );
    } catch (ex) {
      FusionLogger.log(
        tag: LogTag.exceptions,
        message: "Exception in FusionNetworkClient.disconnectWebSocket() - $ex",
        logLevel: LogLevel.error,
      );
      return ResponseCallback<T>(
        success: false,
        message: "Exception in FusionNetworkClient.disconnectWebSocket() - $ex",
        statusCode: null,
      );
    }
  }

  /// Async* stream to listen to incoming WebSocket messages mapped to ResponseCallback
  Stream<ResponseCallback<dynamic>> get webSocketMessages async* {
    if (!webSocketService.isConnected) {
      yield ResponseCallback<dynamic>(
        success: false,
        message: 'No active WebSocket connection',
        statusCode: null,
      );
    }

    await for (final dynamic message in webSocketService.stream) {
      try {
        // Attempt to decode JSON if applicable, otherwise return raw string
        dynamic decodedData;
        try {
          decodedData = jsonDecode(message.toString());
        } catch (_) {
          decodedData = message; // Fallback to raw message
        }

        yield ResponseCallback<dynamic>(
          success: true,
          message: "New WebSocket data received",
          data: decodedData,
          statusCode: 200,
        );
      } catch (ex) {
        yield ResponseCallback<dynamic>(
          success: false,
          message: 'Exception in FusionNetworkClient.webSocketMessages - $ex ',
          statusCode: null,
        );
      }
    }
  }

  Stream<ResponseCallback<wsmodel.WebSocketResponse>>
  get webSocketResponseMessages async* {
    await for (final ResponseCallback<dynamic> message in webSocketMessages) {
      if (!message.success || message.data == null) {
        yield ResponseCallback<wsmodel.WebSocketResponse>.failure(
          message.message,
          statusCode: message.statusCode,
        );
        continue;
      }

      try {
        final wsmodel.WebSocketResponse decoded = message.data is String
            ? wsmodel.WebSocketResponse.fromJson(message.data as String)
            : decodeProtoJson<wsmodel.WebSocketResponse>(
                message.data,
                wsmodel.WebSocketResponse.create,
              );

        yield ResponseCallback<wsmodel.WebSocketResponse>.success(
          decoded,
          statusCode: message.statusCode,
        );
      } catch (ex) {
        yield ResponseCallback<wsmodel.WebSocketResponse>.failure(
          'Exception in FusionNetworkClient.webSocketResponseMessages - $ex',
          statusCode: message.statusCode,
        );
      }
    }
  }

  T decodeProtoJson<T extends $pb.GeneratedMessage>(
    dynamic json,
    T Function() create,
  ) {
    final T message = create();
    if (json is String) {
      message.mergeFromJson(json);
    } else {
      message.mergeFromJson(jsonEncode(json));
    }
    return message;
  }

  dynamic _normalizeRequestBody(dynamic data) {
    if (data is $pb.GeneratedMessage) {
      return jsonDecode(data.writeToJson());
    }
    return data;
  }
}

enum FusionApiType { fusionServer, fusionAdminServer, droServer, backendServer }

enum FusionApiEndpoint {
  //Fusion Backend endpoints
  process('/process', FusionApiType.droServer), //DRO endpoint
  fusionState('/state', FusionApiType.fusionAdminServer),
  fusionGetEndPoints('/endpoints', FusionApiType.fusionServer),

  //Backend server endpoints
  getProfile("/users/authorization", FusionApiType.backendServer),
  projects("/projects", FusionApiType.backendServer),
  products('/products', FusionApiType.backendServer),
  devicesCloud('/devices', FusionApiType.backendServer),
  firmwareUpdateCheck('/firmware/updates/check', FusionApiType.backendServer),
  firmwareBundleDownloadUrl('/firmware/bundles', FusionApiType.backendServer),
  firmwareUpdateStatus('/firmware/updates/status', FusionApiType.backendServer),

  //fusion server setup apis
  fusionDeviceConfig('/device', FusionApiType.fusionServer),
  fusionDevice('/devices', FusionApiType.fusionServer),
  setVip('/devices/vip', FusionApiType.fusionServer),
  audioSettings('/settings/audio', FusionApiType.fusionServer),
  snapshots('/snapshots', FusionApiType.fusionServer),
  sceneSets('/scene-sets', FusionApiType.fusionServer),
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
    return contains(FusionApiEndpoint.fusionState.path) ||
        contains(FusionApiEndpoint.fusionGetEndPoints.path) ||
        contains(FusionApiEndpoint.fusionDeviceConfig.path) ||
        contains(FusionApiEndpoint.fusionDevice.path) ||
        contains(FusionApiEndpoint.setVip.path) ||
        contains(FusionApiEndpoint.audioSettings.path) ||
        contains(FusionApiEndpoint.snapshots.path) ||
        contains(FusionApiEndpoint.sceneSets.path) ||
        contains(FusionApiEndpoint.sapSessions.path);
  }

  bool isDroServerEndpoint() {
    return contains(FusionApiEndpoint.process.path);
  }

  bool isBackendServerEndpoint() {
    return contains(FusionApiEndpoint.getProfile.path) ||
        contains(FusionApiEndpoint.projects.path) ||
        contains(FusionApiEndpoint.devicesCloud.path);
  }

  bool isTokenRequired() {
    return isBackendServerEndpoint();
  }
}
