import 'package:dio/dio.dart';
import 'package:fusion_lib/fusion_lib.dart';

// CUSTOM EXCEPTIONS based on error responses from the API,
// to allow more granular error handling in the ViewModel.
// For example, DeviceAlreadyRegisteredException can be caught separately to trigger a CSR update flow.
class DeviceAlreadyRegisteredException implements Exception {
  final String certificate;
  final String fusionDeviceId;
  const DeviceAlreadyRegisteredException(this.certificate, this.fusionDeviceId);
}

class DeviceRegistrationRepository {
  final String vip;
  final FusionDeviceService fusionDeviceService;
  DeviceRegistrationRepository({required this.vip, required this.fusionDeviceService});

  String _extractErrorMessage({required dynamic responseData, required String? responseMessage}) {
    // Some APIs return plain text bodies instead of JSON objects.
    if (responseData is String) {
      final String message = responseData.trim();
      if (message.isNotEmpty) return message;
    }

    final Map<String, dynamic> errorObject = responseData is Map<String, dynamic> ? responseData : <String, dynamic>{};

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

  Future<List<FusionNetworkDevice>> getFusionNetworkUnRegisteredDevices() async {
    try {
      final ResponseCallback<List<FusionNetworkDevice>> response = await fusionDeviceService.getAvailableDevicesOnNetwork(ip: vip);
      if (response.success) {
        final List<FusionNetworkDevice> devices = response.data ?? <FusionNetworkDevice>[];
        return devices.where((FusionNetworkDevice element) => !element.isDeviceCertificateValid).toList();
      } else {
        final String errorMessage = _extractErrorMessage(responseData: response.data, responseMessage: response.message);
        throw Exception(errorMessage);
      }
    } on DioException {
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
      final ResponseCallback<CloudDeviceRegisterResult> response = await fusionDeviceService.registerSingleDevice(
        device: device,
        vip: vip,
        projectId: projectId,
        csrCertificate: csrCertificate,
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        final String errorMessage = _extractErrorMessage(responseData: response.data, responseMessage: response.message);

        if (response.statusCode == 400) {
          throw DeviceAlreadyRegisteredException(csrCertificate, device.id);
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getCSRCertificate(String deviceId) async {
    try {
      final ResponseCallback<String> response = await fusionDeviceService.getCsrCertificate(vip: vip, deviceId: deviceId);

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        final String errorMessage = _extractErrorMessage(responseData: response.data, responseMessage: response.message);
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateCsrInFusionDevice({required String fusionDeviceId, required String certificate}) async {
    try {
      final ResponseCallback<dynamic> response = await fusionDeviceService.updateCsrInFusionDevice(
        vip: vip,
        fusionDeviceId: fusionDeviceId,
        certificate: certificate,
      );

      if (response.success) {
        return true;
      } else {
        final String errorMessage = _extractErrorMessage(responseData: response.data, responseMessage: response.message);
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  // resetDeviceCertificate
  Future<bool> resetDeviceCertificate({required String fusionDeviceSerialNumber}) async {
    try {
      final ResponseCallback<dynamic> response = await fusionDeviceService.resetDeviceCertificate(
        vip: vip,
        fusionDeviceSerialNumber: fusionDeviceSerialNumber,
      );

      if (response.success) return true;
      return false;
    } catch (e) {
      return false;
    }
  }
}
