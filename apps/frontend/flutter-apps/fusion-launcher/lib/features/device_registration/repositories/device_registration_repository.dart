import 'package:fusion_lib/fusion_lib.dart';

class DeviceAlreadyRegisteredException implements Exception {
  final String certificate;
  final String fusionDeviceId;
  const DeviceAlreadyRegisteredException(this.certificate, this.fusionDeviceId);
}

class DeviceRegistrationRepository {
  final String vip;
  final FusionDeviceService fusionDeviceService;
  DeviceRegistrationRepository({required this.vip, required this.fusionDeviceService});

  Future<List<FusionNetworkDevice>> getFusionNetworkUnRegisteredDevices() async {
    try {
      final ResponseCallback<List<FusionNetworkDevice>> response = await fusionDeviceService.getAvailableDevicesOnNetwork(ip: vip);
      if (response.success) {
        final List<FusionNetworkDevice> devices = response.data ?? <FusionNetworkDevice>[];
        return devices.where((FusionNetworkDevice element) => !element.isDeviceCertificateValid).toList();
      } else {
        final Map<String, dynamic> errorObject = response.data is Map<String, dynamic> ? (response.data as Map<String, dynamic>) : <String, dynamic>{};
        final String? errorMessage = errorObject['error'] ?? response.message ?? 'Unknown error';
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<CloudDeviceRegisterResult> registerSingleDevice(String projectId, String csrCertificate, FusionNetworkDevice device) async {
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
        final Map<String, dynamic> errorObject = response.data is Map<String, dynamic> ? (response.data as Map<String, dynamic>) : <String, dynamic>{};
        final String? errorType = errorObject['error'] ?? response.message ?? 'Unknown error';
        final String errorMessage = errorObject['message'] ?? response.message ?? 'Unknown error';

        if (errorType == "already_exists") {
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
        final Map<String, dynamic> errorObject = response.data is Map<String, dynamic> ? (response.data as Map<String, dynamic>) : <String, dynamic>{};
        final String? errorMessage = errorObject['error'] ?? response.message ?? 'Unknown error';
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

      if (response.success && response.data != null) {
        return true;
      } else {
        final Map<String, dynamic> errorObject = response.data is Map<String, dynamic> ? (response.data as Map<String, dynamic>) : <String, dynamic>{};
        final String? errorMessage = errorObject['error'] ?? response.message ?? 'Unknown error';
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }
}
