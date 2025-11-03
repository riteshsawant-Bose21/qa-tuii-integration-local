import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/fusion_networking/network/rest_client/dio_client.dart';
import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../utils/fusion_utils.dart';

class AppInterceptors extends Interceptor {
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = <_PendingRequest>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (kDebugMode) {
      debugPrint("---API REQUEST CREATED---");
    }

    // final String? token = serviceLocator<FusionConfig>().accessToken;
    // if (token != null) {
    //   options.headers["Authorization"] = 'Bearer $token';
    // }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint(" Dio Error Code is ${err.response?.statusCode} ");
    // if (err.response?.statusCode == 401 && err.requestOptions.path.isBackendServerEndpoint() && err.requestOptions.path.isTokenRequired()) {
    //   // Handle 401 error - token expired
    //   await _handleTokenExpiry(err, handler);
    //   return;
    // }

    // Show error dialog for non-success responses
    // if(!err.requestOptions.path.isBackendServerEndpoint() || err.requestOptions.path.isTokenRequired()) {
    FusionUiUtils.showErrorDialog(err, fromError: true);
    // }

    // Handle other errors as before
    if (err.response != null && err.response?.statusCode != null) {
      if (err.response!.statusCode == 403) {
        // Handle 403 forbidden
      }

      if (err.response!.statusCode! > 499 || err.response!.statusCode == 403 || err.response!.statusCode == 400) {
        // Report to firebase or perform any other action
      }
    }

    return handler.next(err);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    if (kDebugMode) {
      debugPrint("--RESPONSE RECEIVED FROM API---");
    }

    if (response.statusCode == 401 && response.requestOptions.path.isBackendServerEndpoint() && response.requestOptions.path.isTokenRequired()) {
      // Handle 401 error - token expired
      await _handleTokenExpiry(response, handler);
      return;
    }

    // Check if response has error status flag
    _checkResponseForErrorStatus(response);

    // if we want to perform caching we can add the response to the cache here..
    // return previous response from cache on api error / if device went offline

    return handler.next(response);
  }

  Future<void> _handleTokenExpiry(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    if (_isRefreshing) {
      // If already refreshing, add to pending requests
      _pendingRequests.add(_PendingRequest(response, handler));
      return;
    }

    _isRefreshing = true;

    try {
      // Attempt to refresh token
      final bool refreshSuccess = await _refreshToken();

      if (refreshSuccess) {
        // Token refreshed successfully, retry original request
        final Response<dynamic> retryResponse = await _retryOriginalRequest(response.requestOptions);
        handler.next(retryResponse);

        // Retry all pending requests
        await _retryPendingRequests();
      } else {
        // Token refresh failed, perform logout
        // Show error dialog for non-success responses
        final DioException dioError = DioException(
          requestOptions: response.requestOptions,
          error: response.statusMessage,
          message: response.toString(),
        );
        FusionUiUtils.showErrorDialog(dioError, fromError: true);

        handler.next(response);
      }
    } catch (e) {
      // Token refresh failed

      // Show error dialog for non-success responses
      final DioException dioError = DioException(
        requestOptions: response.requestOptions,
        error: response.statusMessage,
        message: response.toString(),
      );
      FusionUiUtils.showErrorDialog(dioError, fromError: true);

      handler.next(response);
    } finally {
      _isRefreshing = false;
      _pendingRequests.clear();
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final String? refreshToken = serviceLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.refreshToken);
      if (refreshToken == null) {
        return false;
      }

      final Dio refreshDio = Dio(
        BaseOptions(
          connectTimeout: serviceLocator<DioClient>().dioInstance.options.connectTimeout,
          receiveTimeout: serviceLocator<DioClient>().dioInstance.options.receiveTimeout,
          sendTimeout: serviceLocator<DioClient>().dioInstance.options.sendTimeout,
        ),
      );

      refreshDio.interceptors.add(LogInterceptor());

      // Make refresh token API call
      final Response<dynamic> response = await refreshDio.post(
        serviceLocator<FusionNetworkClient>().geApiUrl(FusionApiEndpoint.refreshToken),
        data: <String, String>{
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: <String, dynamic>{
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Extract new tokens from response

        final ResponseCallback<LoginResponseDto> responseCallback = ResponseCallback<LoginResponseDto>.fromJson(response.data, LoginResponseDto.fromJson);

        if (responseCallback.data != null) {
          // Save new tokens
          await serviceLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.accessToken, responseCallback.data?.accessToken ?? "");
          if (responseCallback.data?.refreshToken != null) {
            await serviceLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.refreshToken, responseCallback.data?.refreshToken ?? "");
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Token refresh failed: $e');
      }
      return false;
    }
  }

  Future<Response<dynamic>> _retryOriginalRequest(RequestOptions requestOptions) async {
    // Get the new access token
    final String? newToken = serviceLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.accessToken);
    if (newToken != null) {
      requestOptions.headers["Authorization"] = 'Bearer $newToken';
    }

    // Handle FormData recreation for multipart requests
    dynamic requestData = requestOptions.data;
    if (requestData is FormData) {
      // Create a new FormData instance with the same fields and files
      final FormData newFormData = FormData();

      // Copy all fields from the original FormData
      for (final MapEntry<String, String> field in requestData.fields) {
        newFormData.fields.add(MapEntry<String, String>(field.key, field.value));
      }

      // Copy all files from the original FormData
      for (final MapEntry<String, MultipartFile> file in requestData.files) {
        final MultipartFile originalFile = file.value;

        // Create a new MultipartFile
        final MultipartFile newFile = originalFile.clone();

        newFormData.files.add(MapEntry<String, MultipartFile>(file.key, newFile));
      }

      requestData = newFormData;
    }

    debugPrint("Retrying request to ${requestOptions.path} with data: $requestData");
    // Retry the original request with the new/recreated data
    return await serviceLocator<DioClient>().dioInstance.request(
      requestOptions.path,
      data: requestData,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
        followRedirects: requestOptions.followRedirects,
        maxRedirects: requestOptions.maxRedirects,
        receiveTimeout: requestOptions.receiveTimeout,
        sendTimeout: requestOptions.sendTimeout,
        extra: requestOptions.extra,
      ),
    );
  }

  Future<void> _retryPendingRequests() async {
    for (final _PendingRequest pendingRequest in _pendingRequests) {
      try {
        final Response<dynamic> response = await _retryOriginalRequest(pendingRequest.response.requestOptions);

        // CASE 1: Success - resolve the handler with the response
        pendingRequest.handler.resolve(response);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Retry pending request failed: $e');
        }

        // CASE 2: Retry failed - pass the error to the handler
        if (e is DioException) {
          pendingRequest.handler.reject(e);
        } else {
          // Convert generic error to DioException
          final DioException dioError = DioException(
            requestOptions: pendingRequest.response.requestOptions,
            error: e,
            message: e.toString(),
          );
          pendingRequest.handler.reject(dioError);
        }
      }
    }
  }

  void _checkResponseForErrorStatus(Response<dynamic> response) {
    // Check if response data has error status flag
    if (response.data != null && response.data is Map) {
      final Map<String, dynamic> responseData = response.data;

      // Check for common error status patterns
      bool hasError = false;

      // Check for "status" field with "error" or false
      if (responseData.containsKey('status')) {
        final dynamic status = responseData['status'];
        if (status == 'error' || status == false) {
          hasError = true;
        }
      }

      // Check for "success" field with false
      if (responseData.containsKey('success') && responseData['success'] == false) {
        hasError = true;
      }

      // Check for "error" field
      if (responseData.containsKey('error')) {
        hasError = true;
      }

      // Check for status_code 500 in DRO
      if (responseData.containsKey('status_code') && responseData['status_code'] == 500) {
        hasError = true;
      }

      if (hasError) {
        // Create a DioException-like error for consistency
        final DioException dioError = DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'API returned error status',
        );

        FusionUiUtils.showErrorDialog(dioError);
      }
    }
  }
}

// Helper class to store pending requests with their handlers
class _PendingRequest {
  final Response<dynamic> response;
  final ResponseInterceptorHandler handler;

  _PendingRequest(this.response, this.handler);
}
