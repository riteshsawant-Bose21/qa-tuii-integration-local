import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const int _defaultConnectTimeout = 10000;
const int _defaultReceiveTimeout = 50000;

class DioClient {
  final Dio dioInstance;

  final List<Interceptor>? interceptors;

  DioClient({
    required this.dioInstance,
    this.interceptors,
  }) {
    dioInstance
      ..options.connectTimeout = const Duration(milliseconds: _defaultConnectTimeout)
      ..options.receiveTimeout = const Duration(milliseconds: _defaultReceiveTimeout)
      ..httpClientAdapter
      ..options.headers = <String, dynamic>{'Content-Type': 'application/json; charset=UTF-8'};

    dioInstance.options.validateStatus = (int? status) {
      return status! < 500;
    };

    if (interceptors?.isNotEmpty ?? false) {
      dioInstance.interceptors.addAll(interceptors!);
    }

    if (kDebugMode) {
      dioInstance.interceptors.add(
        LogInterceptor(
          responseBody: true,
          error: true,
          requestHeader: true,
          responseHeader: false,
          request: true,
          requestBody: true,
        ),
      );
    }
  }

  String handleError(DioException error) {
    String errorDescription = "";
    switch (error.type) {
      case DioExceptionType.cancel:
        errorDescription = "Request to API server was cancelled";
        break;
      case DioExceptionType.connectionTimeout:
        errorDescription = "Connection timeout with API server";
        break;
      case DioExceptionType.unknown:
        errorDescription = "Connection to API server failed due to internet connection";
        break;
      case DioExceptionType.receiveTimeout:
        errorDescription = "Receive timeout in connection with API server";
        break;
      case DioExceptionType.badResponse:
        errorDescription = "Received invalid status code: ${error.response!.statusCode}";
        if (error.response!.data != null) {
          try {
            // var apiResponse = ApiResponse.fromJson(dioError.response!.data);
            // if (apiResponse.msg != null) {
            //   errorDescription = apiResponse.msg!;
            // }
          } catch (exception) {
            debugPrint(exception.toString());
          }
        }
        break;
      case DioExceptionType.sendTimeout:
        errorDescription = "Send timeout in connection with API server";
        break;
      case DioExceptionType.badCertificate:
        errorDescription = "Bad Certificate error!";
        break;
      case DioExceptionType.connectionError:
        errorDescription = "Connection Error with API server";
    }
    return errorDescription;
  }

  bool isSuccessResponse(int? statusCode) {
    if (statusCode != null) {
      if (statusCode >= 200 && statusCode < 300) {
        return true;
      }
    }
    return false;
  }

  String handleStatusCodeError(int? statusCode) {
    String errorDescription = "Something went wrong!";
    if (statusCode != null) {
      if (statusCode >= 300 && statusCode < 400) {
        errorDescription = "API redirected";
      } else if (statusCode >= 400 && statusCode < 500) {
        errorDescription = "UnAuthorised!";
      } else if (statusCode >= 500) {
        errorDescription = "Internal Server Error!";
      }
    }
    return errorDescription;
  }
}
