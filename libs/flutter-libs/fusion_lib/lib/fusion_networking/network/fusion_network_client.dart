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

  Future<ResponseCallback<T>> get<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? urlParameters,
    String? additionalPath,
    String? baseUrlToOverride,
    bool isSecure = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride)}/$additionalPath"
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
          return ResponseCallback<T>(success: true, message: "Binary file fetched successfully", data: response.data as T?);
        } else {
          T? data = fromJson != null ? fromJson(response.data) : response.data;
          return ResponseCallback<T>.success(data);
        }
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode));
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.get() - $ex");
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
        return ResponseCallback<T>.success(data);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode));
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.get() - $ex");
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
        return ResponseCallback<T>.success(data);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode));
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.post() - $ex");
      return ResponseCallback.failure("Exception in FusionNetworkClient.post() - $ex");
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
        return ResponseCallback<T>.success(data);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode));
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      // FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.patch() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.patch() - $ex");
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
    try {
      final String url = additionalPath != null
          ? "${geApiUrl(
              api,
              baseUrlToOverride: baseUrlToOverride,
              isSecure: isSecure,
            )}/$additionalPath"
          : geApiUrl(
              api,
              baseUrlToOverride: baseUrlToOverride,
              isSecure: isSecure,
            );

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
        return ResponseCallback<T>.success(data);
      } else if (response.statusCode == 204 || response.statusCode == 200 || response.statusCode == 202) {
        return ResponseCallback<T>(success: true, message: "Resource deleted successfully");
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode));
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      // FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.delete() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.delete() - $ex");
    }
  }

  Future<ResponseCallback<T>> connect<T>({required String vip}) async {
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
      return ResponseCallback<T>(success: true, message: "ZMQ Subscriber Connected");
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.connect() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.connect() - $ex");
    }
  }

  Future<ResponseCallback<T>> disconnect<T>() async {
    try {
      if (subscriberSocket != null) {
        subscriberSocket?.close();
        subscriberSocket = null;
      }
      FusionLogger.log(tag: LogTag.zmq, message: "ZMQ Socket Disconnected!!!");
      return ResponseCallback<T>(success: true, message: "ZMQ Socket Disconnected");
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.disconnect() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.disconnect() - $ex");
    }
  }

  Stream<ResponseCallback<dynamic>> get responseMessages async* {
    if (subscriberSocket == null) {
      yield ResponseCallback<dynamic>(success: false, message: 'No server socket available');
      return;
    }

    final ZSocket socket = subscriberSocket!;

    await for (final ZFrame frame in socket.frames) {
      // If the socket was replaced by a reconnect while iterating, stop
      // this generator so the old subscription can be garbage-collected.
      if (subscriberSocket != socket) return;

      try {
        final String message = utf8.decode(frame.payload, allowMalformed: true);
        yield ResponseCallback<dynamic>(success: true, message: "New data received", data: jsonDecode(message));
      } catch (ex) {
        yield ResponseCallback<dynamic>(success: false, message: 'Exception in FusionNetworkClient.responseMessages - $ex ');
      }
    }
  }

  /// Connects to a WebSocket URL using the injected WebSocketService
  Future<ResponseCallback<T>> connectWebSocket<T>({required String url}) async {
    try {
      webSocketService.connect(url);
      FusionLogger.log(tag: LogTag.network, message: "WebSocket connecting to $url");

      return ResponseCallback<T>(success: true, message: "WebSocket connection initiated");
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.connectWebSocket() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.connectWebSocket() - $ex");
    }
  }

  /// Sends a message through the active WebSocket connection
  Future<ResponseCallback<T>> sendWebSocketMessage<T>(dynamic message) async {
    try {
      if (!webSocketService.isConnected) {
        return ResponseCallback<T>(success: false, message: "WebSocket is not connected");
      }

      // If the message isn't a string (e.g., a Map), JSON encode it
      final dynamic payload = message is String ? message : jsonEncode(message);
      webSocketService.sendMessage(payload);

      return ResponseCallback<T>(success: true, message: "Message sent successfully");
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.sendWebSocketMessage() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.sendWebSocketMessage() - $ex");
    }
  }

  /// Disconnects the active WebSocket connection
  Future<ResponseCallback<T>> disconnectWebSocket<T>() async {
    try {
      webSocketService.disconnect();
      FusionLogger.log(tag: LogTag.network, message: "WebSocket Disconnected!!!");

      return ResponseCallback<T>(success: true, message: "WebSocket Disconnected");
    } catch (ex) {
      FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.disconnectWebSocket() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.disconnectWebSocket() - $ex");
    }
  }

  /// Async* stream to listen to incoming WebSocket messages mapped to ResponseCallback
  Stream<ResponseCallback<dynamic>> get webSocketMessages async* {
    if (!webSocketService.isConnected) {
      yield ResponseCallback<dynamic>(success: false, message: 'No active WebSocket connection');
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

        yield ResponseCallback<dynamic>(success: true, message: "New WebSocket data received", data: decodedData);
      } catch (ex) {
        yield ResponseCallback<dynamic>(success: false, message: 'Exception in FusionNetworkClient.webSocketMessages - $ex ');
      }
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
  devicesBulkCloud('/devices/bulk', FusionApiType.backendServer),
  devicesCloud('/devices', FusionApiType.backendServer),

  //fusion server setup apis
  fusionDevice('/devices', FusionApiType.fusionServer),
  setVip('/devices/vip', FusionApiType.fusionServer),
  sapSessions('/sessions', FusionApiType.fusionServer);

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
