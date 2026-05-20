import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../devices/services/fusion_device_discovery_service.dart';

class DeviceAlreadyRegisteredException implements Exception {
  final String certificate;
  final String fusionDeviceId;
  const DeviceAlreadyRegisteredException(this.certificate, this.fusionDeviceId);
}

class NoInternetException implements Exception {
  final String message;
  const NoInternetException([this.message = 'No internet connection']);

  @override
  String toString() => message;
}

class DeviceRegistrationRepository {
  final String vip;
  final FusionDeviceService fusionDeviceService;
  final FusionDeviceDiscoveryService fusionDeviceDiscoveryService;

  DeviceRegistrationRepository({
    required this.vip,
    required this.fusionDeviceService,
    required this.fusionDeviceDiscoveryService,
  });

  Never _throwNoInternetException() => throw const NoInternetException();

  void _throwNoInternetIfSocketError(DioException exception) {
    if (exception.error is SocketException ||
        exception.type == DioExceptionType.connectionError) {
      _throwNoInternetException();
    }
  }

  String _extractErrorMessage({
    required dynamic responseData,
    required String? responseMessage,
  }) {
    if (responseData is String) {
      final String message = responseData.trim();
      if (message.isNotEmpty) return message;
    }

    final Map<String, dynamic> errorObject =
        responseData is Map<String, dynamic>
            ? responseData
            : <String, dynamic>{};

    String clean(dynamic value) => value is String ? value.trim() : '';

    final List<String?> candidates = <String?>[
      clean(errorObject['message']),
      clean(errorObject['error']),
      clean(errorObject['details']),
      responseMessage,
    ];

    for (final String? candidate in candidates) {
      final String cleaned = (candidate ?? '').trim();
      if (cleaned.isNotEmpty) return cleaned;
    }

    return 'Unknown error';
  }

  Future<List<FusionNetworkDevice>>
  getFusionNetworkUnRegisteredDevices() async {
    try {
      final ResponseCallback<List<FusionNetworkDevice>> response =
          await fusionDeviceDiscoveryService.getAvailableDevicesOnNetwork(
            ip: vip,
          );

      if (response.success) {
        final List<FusionNetworkDevice> devices =
            response.data ?? <FusionNetworkDevice>[];
        return devices
            .where(
              (FusionNetworkDevice element) =>
                  !element.isDeviceCertificateValid,
            )
            .toList();
      }

      final String errorMessage = _extractErrorMessage(
        responseData: response.data,
        responseMessage: response.message,
      );
      throw Exception(errorMessage);
    } on SocketException {
      _throwNoInternetException();
    } on DioException catch (exception) {
      _throwNoInternetIfSocketError(exception);
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<CloudDeviceRegisterResult> registerSingleDevice({
    required String projectId,
    required String csrCertificate,
    required FusionNetworkDevice device,
  }) async {
    try {
      final ResponseCallback<CloudDeviceRegisterResult> response =
          await fusionDeviceService.registerSingleDevice(
            device: device,
            vip: vip,
            projectId: projectId,
            csrCertificate: csrCertificate,
          );

      if (response.success && response.data != null) {
        return response.data!;
      }

      final String errorMessage = _extractErrorMessage(
        responseData: response.data,
        responseMessage: response.message,
      );

      if (response.statusCode == 400) {
        throw DeviceAlreadyRegisteredException(csrCertificate, device.id);
      }
      throw Exception(errorMessage);
    } on SocketException {
      _throwNoInternetException();
    } on DioException catch (exception) {
      _throwNoInternetIfSocketError(exception);
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getCSRCertificate(String deviceId) async {
    try {
      final ResponseCallback<String> response = await fusionDeviceService
          .getCsrCertificate(vip: vip, deviceId: deviceId);

      if (response.success && response.data != null) {
        return response.data!;
      }

      final String errorMessage = _extractErrorMessage(
        responseData: response.data,
        responseMessage: response.message,
      );
      throw Exception(errorMessage);
    } on SocketException {
      _throwNoInternetException();
    } on DioException catch (exception) {
      _throwNoInternetIfSocketError(exception);
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateCsrInFusionDevice({
    required String fusionDeviceId,
    required String certificate,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await fusionDeviceService
          .updateCsrInFusionDevice(
            vip: vip,
            fusionDeviceId: fusionDeviceId,
            certificate: certificate,
          );

      if (response.success) {
        return true;
      }

      final String errorMessage = _extractErrorMessage(
        responseData: response.data,
        responseMessage: response.message,
      );
      throw Exception(errorMessage);
    } on SocketException {
      _throwNoInternetException();
    } on DioException catch (exception) {
      _throwNoInternetIfSocketError(exception);
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> resetDeviceCertificate({
    required String fusionDeviceSerialNumber,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await fusionDeviceService
          .resetDeviceCertificate(
            vip: vip,
            fusionDeviceSerialNumber: fusionDeviceSerialNumber,
          );

      if (response.success) return true;
      return false;
    } on SocketException {
      _throwNoInternetException();
    } on DioException catch (exception) {
      _throwNoInternetIfSocketError(exception);
      return false;
    } catch (e) {
      return false;
    }
  }
}
