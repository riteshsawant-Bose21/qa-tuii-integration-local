import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_logger/logger.dart';
import 'package:fusion_lib/fusion_networking/network/rest_client/dio_client.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../fusion_utils/app_settings.dart';
import '../../fusion_utils/shared_preference_handler.dart';
import '../../fusion_utils/telemetry_data.dart';
import 'dartzmq_stub.dart' if (dart.library.io) 'package:dartzmq/dartzmq.dart';

enum ServerUpdateType { forceUpdate, metadata, localValue }

class FusionNetworkClient {
  final DioClient httpClient;
  final SharedPreferencesHandler sharedPreferencesHandler;
  final TelemetryData telemetryData;
  final FusionPreferences fusionPreferences;

  FusionNetworkClient({required this.httpClient, required this.sharedPreferencesHandler, required this.telemetryData, required this.fusionPreferences});

  ZSocket? subscriberSocket;
  final ZContext _context = ZContext();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiry;

  String? get accessToken {
    if (_accessToken != null && _expiry != null) {
      if (DateTime.now().isAfter(_expiry!)) {
        FusionLogger.log(tag: LogTag.fusion, message: "Access token expired");
        return null;
      }
      return _accessToken;
    } else {
      final String? storedAccessToken = sharedPreferencesHandler.getString(SharedPreferenceKeys.accessToken);
      final String? expiryTime = sharedPreferencesHandler.getString(SharedPreferenceKeys.expiry);
      if (storedAccessToken != null && expiryTime != null) {
        final DateTime dateTime = DateTime.parse(expiryTime);
        if (DateTime.now().isAfter(dateTime)) {
          FusionLogger.log(tag: LogTag.fusion, message: "Access token expired");
          return null;
        } else {
          _accessToken = storedAccessToken;
          _expiry = dateTime;
          return _accessToken;
        }
      }
    }
    return null;
  }

  String? get refreshToken {
    if (_refreshToken != null && _expiry != null) {
      if (DateTime.now().isAfter(_expiry!)) {
        FusionLogger.log(tag: LogTag.fusion, message: "Refresh token expired");
        return null;
      }
      return _refreshToken;
    } else {
      final String? storedRefreshToken = sharedPreferencesHandler.getString(SharedPreferenceKeys.refreshToken);
      if (storedRefreshToken != null) {
        _refreshToken = storedRefreshToken;
        return _refreshToken;
      }
    }
    return null;
  }

  String geApiUrl(FusionApiEndpoint api, {String? baseUrlToOverride}) {
    if (baseUrlToOverride != null) {
      return "http://$baseUrlToOverride${api.path}";
    }
    if (api.type == FusionApiType.droServer) {
      return "http://${fusionPreferences.droServerUrl}${api.path}";
    } else if (api.type == FusionApiType.fusionServer) {
      return "http://${fusionPreferences.virtualIp}:8080${api.path}";
    } else if (api.type == FusionApiType.backendServer) {
      return "http://${fusionPreferences.fusionCloudBackendUrl}/api/v1${api.path}";
    } else {
      throw Exception("Invalid API type: ${api.type}");
    }
  }

  // return token fro shared preferences only if FusionApiEndpoint api == FusionApiType.backendServer
  String? getAccessTokenForApi(FusionApiEndpoint api) {
    if (api.type == FusionApiType.backendServer) {
      final String? storedAccessToken = sharedPreferencesHandler.getString(SharedPreferenceKeys.accessToken);
      return storedAccessToken;
    }
    return null;
  }

  Future<ResponseCallback<T>> get<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? urlParameters,
    String? additionalPath,
    String? baseUrlToOverride,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride)}/$additionalPath"
          : geApiUrl(api, baseUrlToOverride: baseUrlToOverride);

      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final bool isBinary = T == Uint8List;

      final Options options = Options(headers: <String, dynamic>{...headers}, responseType: isBinary ? ResponseType.bytes : ResponseType.json);

      final Response<dynamic> response = await httpClient.dioInstance.get(url, options: options, queryParameters: urlParameters);

      if (response.data != null) {
        if (isBinary) {
          return ResponseCallback<T>(success: true, message: "Binary file fetched successfully", data: response.data as T);
        } else {
          return ResponseCallback<T>.fromJson(response.data, fromJson);
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
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride)}/$additionalPath"
          : geApiUrl(api, baseUrlToOverride: baseUrlToOverride);

      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final Options options = Options(headers: <String, dynamic>{...headers});

      final Response<dynamic> response = await httpClient.dioInstance.put(url, options: options, data: data);

      if (response.data != null) {
        return ResponseCallback<T>.fromJson(response.data, fromJson);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode));
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.get() - $ex");
    }
  }

  /// get list from get api
  Future<ResponseCallback<List<T>>> getList<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? urlParameters,
    String? additionalPath,
    String? baseUrlToOverride,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride)}/$additionalPath"
          : geApiUrl(api, baseUrlToOverride: baseUrlToOverride);

      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      /// Detect content type based on data type
      final Options options = Options(headers: <String, dynamic>{...headers});

      final Response<dynamic> response = await httpClient.dioInstance.get(url, options: options, queryParameters: urlParameters);

      final bool isSuccess = response.statusCode == 200 && response.data != null && response.data['status'] == 'success';

      if (isSuccess) {
        List<T> entities = <T>[];
        if (response.data['data'] != null) {
          final List<dynamic> dataList = response.data['data'] as List<dynamic>;

          entities = dataList.map((dynamic item) => fromJson(item as Map<String, dynamic>)).toList();
        }

        return ResponseCallback<List<T>>(success: true, message: response.data['message'] ?? 'Success', data: entities);
      } else {
        return ResponseCallback<List<T>>(success: false, message: httpClient.handleStatusCodeError(response.statusCode));
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.getList() - $ex");
      return ResponseCallback<List<T>>(success: false, message: "Exception in FusionNetworkClient.getList() - $ex");
    }
  }

  Future<ResponseCallback<T>> post<T>({
    required FusionApiEndpoint api,
    dynamic data,
    String? additionalPath,
    String? baseUrlToOverride,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride)}/$additionalPath"
          : geApiUrl(api, baseUrlToOverride: baseUrlToOverride);

      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      /// Detect content type based on data type
      final Options options = Options(
        headers: <String, dynamic>{...headers, if (data is FormData) 'Content-Type': 'multipart/form-data' else 'Content-Type': 'application/json'},
      );

      // final dynamic body = data is FormData ? data : jsonEncode(data);

      final Response<dynamic> response = await httpClient.dioInstance.post(url, data: data, options: options);

      if (response.data != null) {
        return ResponseCallback<T>.fromJson(response.data, fromJson);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode));
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.post() - $ex");
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.post() - $ex");
    }
  }

  Future<ResponseCallback<T>> patch<T>({
    required FusionApiEndpoint api,
    Map<String, dynamic>? data,
    Map<String, dynamic>? urlParameters,
    String? additionalPath,
    String? baseUrlToOverride,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final Response<dynamic> response = await httpClient.dioInstance.patch(
        additionalPath != null ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride)}/$additionalPath" : geApiUrl(api, baseUrlToOverride: baseUrlToOverride),

        data: data,
        queryParameters: urlParameters,
      );
      if (response.data != null) {
        return ResponseCallback<T>.fromJson(response.data, fromJson);
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
    T Function(Map<String, dynamic>)? fromJson,
    String? additionalPath,
    String? baseUrlToOverride,
  }) async {
    try {
      final String url = additionalPath != null
          ? "${geApiUrl(api, baseUrlToOverride: baseUrlToOverride)}/$additionalPath"
          : geApiUrl(api, baseUrlToOverride: baseUrlToOverride);

      final Map<String, dynamic> headers = httpClient.dioInstance.options.headers;
      final String? token = getAccessTokenForApi(api);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      /// Detect content type based on data type
      final Options options = Options(headers: <String, dynamic>{...headers});

      final Response<dynamic> response = await httpClient.dioInstance.delete(url, options: options, queryParameters: urlParameters);

      if (response.data != null) {
        return ResponseCallback<T>.fromJson(response.data, fromJson);
      } else {
        return ResponseCallback<T>(success: false, message: httpClient.handleStatusCodeError(response.statusCode));
      }
    } catch (ex) {
      debugPrint("Exception in FusionNetworkClient.get() - $ex");
      // FusionLogger.log(tag: LogTag.exceptions, message: "Exception in FusionNetworkClient.delete() - $ex", logLevel: LogLevel.error);
      return ResponseCallback<T>(success: false, message: "Exception in FusionNetworkClient.delete() - $ex");
    }
  }

  Future<ResponseCallback<T>> connect<T>() async {
    try {
      await telemetryData.initializeTelemetryAddresses(this);
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
    }

    await for (final ZFrame frame in subscriberSocket!.frames) {
      try {
        final String message = utf8.decode(frame.payload, allowMalformed: true);
        yield ResponseCallback<dynamic>(success: true, message: "New data received", data: jsonDecode(message));
      } catch (ex) {
        yield ResponseCallback<dynamic>(success: false, message: 'Exception in FusionNetworkClient.responseMessages - $ex ');
      }
    }
  }
}

enum FusionApiType { fusionServer, droServer, backendServer }

enum FusionApiEndpoint {
  //Fusion Backend endpoints
  dro('/dro-endpoint', FusionApiType.fusionServer),
  dsp('/dsp-endpoint', FusionApiType.fusionServer),
  process('/process', FusionApiType.droServer), //DRO endpoint
  fusionGetValue('/value', FusionApiType.fusionServer),
  fusionSetValue('/value', FusionApiType.fusionServer),
  fusionUpdateValue('/value', FusionApiType.fusionServer),
  fusionGetEndPoints('/endpoints', FusionApiType.fusionServer),
  fusionDelete('/clear', FusionApiType.fusionServer),

  //Backend server endpoints
  register('/auth/register', FusionApiType.backendServer),
  login('/auth/login', FusionApiType.backendServer),
  projects('/projects', FusionApiType.backendServer),
  uploadFile('/files/upload', FusionApiType.backendServer),
  fetchFile('/files', FusionApiType.backendServer),
  refreshToken('/auth/refresh-token', FusionApiType.backendServer),
  saveProfile("/users/metadata", FusionApiType.backendServer),
  getProfile("/users/me", FusionApiType.backendServer),

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
    return contains(FusionApiEndpoint.fusionGetValue.path) ||
        contains(FusionApiEndpoint.fusionSetValue.path) ||
        contains(FusionApiEndpoint.fusionUpdateValue.path) ||
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
    return contains(FusionApiEndpoint.register.path) ||
        contains(FusionApiEndpoint.login.path) ||
        contains(FusionApiEndpoint.projects.path) ||
        contains(FusionApiEndpoint.uploadFile.path) ||
        contains(FusionApiEndpoint.refreshToken.path) ||
        contains(FusionApiEndpoint.fetchFile.path) ||
        contains(FusionApiEndpoint.saveProfile.path) ||
        contains(FusionApiEndpoint.getProfile.path);
  }

  bool isTokenRequired() {
    return isBackendServerEndpoint() && !contains(FusionApiEndpoint.login.path) && !contains(FusionApiEndpoint.register.path);
  }
}
