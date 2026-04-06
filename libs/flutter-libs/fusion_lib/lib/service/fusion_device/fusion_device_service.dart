import 'package:fusion_lib/fusion_lib.dart';

/// Cloud-side registration + claim status for a single device.
class CloudDeviceStatus {
  final String id;
  final bool registered;
  final bool claimed;

  const CloudDeviceStatus({
    required this.id,
    required this.registered,
    required this.claimed,
  });

  factory CloudDeviceStatus.fromJson(Map<String, dynamic> json) {
    return CloudDeviceStatus(
      id: json['id'] as String? ?? '',
      registered: json['registered'] as bool? ?? false,
      claimed: json['claimed'] as bool? ?? false,
    );
  }
}

class DeviceBulkRegisterResult {
  final bool success;
  final String deviceId;
  final String error;

  const DeviceBulkRegisterResult({
    required this.success,
    required this.deviceId,
    required this.error,
  });

  factory DeviceBulkRegisterResult.fromJson(Map<String, dynamic> json) {
    return DeviceBulkRegisterResult(
      success: json['success'] as bool? ?? false,
      deviceId: json['device_id'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );
  }
}

class FusionDeviceService {
  final FusionNetworkClient networkClient;

  FusionDeviceService({required this.networkClient});

  /// Fetches the cloud registration + claim status for all devices belonging
  /// to the given project from the cloud backend.
  Future<ResponseCallback<List<CloudDeviceStatus>>> getCloudDevicesStatus({required String projectId}) async {
    try {
      final ResponseCallback<List<CloudDeviceStatus>> response = await networkClient.get(
        api: FusionApiEndpoint.devicesCloud,
        urlParameters: <String, dynamic>{'project_id': projectId},
        fromJson: (dynamic json) => (json as List<dynamic>).whereType<Map<String, dynamic>>().map(CloudDeviceStatus.fromJson).toList(),
      );
      return response;
    } catch (e) {
      return ResponseCallback<List<CloudDeviceStatus>>.failure(e.toString());
    }
  }

  /// Bulk-registers [HardwareComponent] devices in the cloud via POST /devices/bulk.
  Future<ResponseCallback<List<DeviceBulkRegisterResult>>> registerHardwareDevicesBulk({
    required List<HardwareComponent> hardwares,
    required String projectId,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.devicesBulkCloud,
        data: <String, dynamic>{
          'devices': [
            ...hardwares.map(
              (HardwareComponent hw) {
                return <String, dynamic>{
                  'client_device_id': hw.id,
                  'csr': '', // TODO: SHARATH
                  'device_location': '', // TODO: SHARATH
                  'device_name': hw.name,
                  'device_zone': '', // TODO: SHARATH
                  'firmware_version': '', // TODO: SHARATH
                  'is_primary': false,
                  'mac_address': '', // TODO: SHARATH
                  'model_name': hw.hardwareName,
                  'project_id': projectId,
                  'serial_number': '', // TODO: SHARATH
                };
              },
            ),
          ],
        },
      );
      if (response.success) {
        final Map<String, dynamic> data = (response.data as Map<String, dynamic>?) ?? <String, dynamic>{};
        final List<dynamic> resultsJson = (data['results'] as List<dynamic>?) ?? <dynamic>[];
        final List<DeviceBulkRegisterResult> results = resultsJson.whereType<Map<String, dynamic>>().map(DeviceBulkRegisterResult.fromJson).toList();
        return ResponseCallback<List<DeviceBulkRegisterResult>>.success(results);
      }
      return ResponseCallback<List<DeviceBulkRegisterResult>>.failure(response.message);
    } catch (e) {
      return ResponseCallback<List<DeviceBulkRegisterResult>>.failure(e.toString());
    }
  }

  Future<ResponseCallback<List<FusionNetworkDevice>>> getAvailableDevicesOnNetwork({required String ip}) async {
    try {
      ResponseCallback<List<FusionNetworkDevice>> responseCallback = await networkClient.get(
        api: FusionApiEndpoint.fusionDevice,
        baseUrlToOverride: ip,
        isSecure: false,
        fromJson: (dynamic json) => List<FusionNetworkDevice>.from(
          (json as List<dynamic>).map((e) => FusionNetworkDevice.fromJson(e as Map<String, dynamic>)),
        ),
      );

      return responseCallback;
    } catch (e) {
      return ResponseCallback<List<FusionNetworkDevice>>.failure(e.toString());
    }
  }

  Future<ResponseCallback<List<DeviceBulkRegisterResult>>> registerDevicesBulk({required List<FusionNetworkDevice> devices, required String projectId}) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.devicesBulkCloud,
        data: <String, dynamic>{
          'devices': [
            ...devices.map(
              (FusionNetworkDevice device) => <String, dynamic>{
                'client_device_id': device.id,
                'csr': '', // TODO: SHARATH
                'device_location': device.location,
                'device_name': device.name,
                'device_zone': '', // TODO: SHARATH
                'firmware_version': '', // TODO: SHARATH
                'is_primary': device.isPrimary,
                'mac_address': '', // TODO: SHARATH
                'model_name': device.modelName,
                'project_id': projectId,
                'serial_number': device.serialNumber,
              },
            ),
          ],
        },
      );
      if (response.success) {
        final Map<String, dynamic> data = (response.data as Map<String, dynamic>?) ?? <String, dynamic>{};
        final List<dynamic> resultsJson = (data['results'] as List<dynamic>?) ?? <dynamic>[];
        final List<DeviceBulkRegisterResult> results = resultsJson.whereType<Map<String, dynamic>>().map(DeviceBulkRegisterResult.fromJson).toList();
        return ResponseCallback<List<DeviceBulkRegisterResult>>.success(results);
      } else {
        return ResponseCallback<List<DeviceBulkRegisterResult>>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<List<DeviceBulkRegisterResult>>.failure(e.toString());
    }
  }

  Future<ResponseCallback<bool>> claimDevice({required String deviceId, required String projectId, required String csr}) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.devicesCloud,
        additionalPath: '$deviceId/claim',
        data: <String, dynamic>{
          'project_id': projectId,
          'csr': csr,
        },
      );

      if (response.success) return ResponseCallback<bool>.success(true);
      return ResponseCallback<bool>.failure(response.message);
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }

  Future<ResponseCallback<bool>> updateDeviceDetails({
    required String currentDeviceId,
    required String newDeviceId,
    required String name,
    required String location,
    required String vip,
  }) async {
    try {
      final ResponseCallback<dynamic> responseCallback = await networkClient.patch(
        api: FusionApiEndpoint.fusionDevice,
        additionalPath: currentDeviceId,
        data: {
          'id': newDeviceId,
          'name': name,
          'location': location,
        },
        baseUrlToOverride: vip,
        isSecure: false,
      );
      if (responseCallback.success) {
        return ResponseCallback<bool>.success(true);
      } else {
        return ResponseCallback<bool>.failure(responseCallback.message);
      }
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }
}
