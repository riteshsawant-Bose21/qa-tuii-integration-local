import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FirmwareUpdateCheckResult {
  final bool updateAvailable;
  final bool appUpdateRequired;
  final String? bundleId;
  final String? version;
  final String? releaseNotes;
  final String? minDesktopAppVersion;

  const FirmwareUpdateCheckResult({
    required this.updateAvailable,
    required this.appUpdateRequired,
    this.bundleId,
    this.version,
    this.releaseNotes,
    this.minDesktopAppVersion,
  });

  factory FirmwareUpdateCheckResult.fromJson(Map<String, dynamic> json) {
    return FirmwareUpdateCheckResult(
      updateAvailable: json['update_available'] as bool? ?? false,
      appUpdateRequired: json['app_update_required'] as bool? ?? false,
      bundleId: json['bundle_id'] as String?,
      version: json['version'] as String?,
      releaseNotes: json['release_notes'] as String?,
      minDesktopAppVersion: json['min_desktop_app_version'] as String?,
    );
  }
}

class BundleDownloadUrlResult {
  final String downloadUrl;
  final String checksum;

  const BundleDownloadUrlResult({
    required this.downloadUrl,
    required this.checksum,
  });

  factory BundleDownloadUrlResult.fromJson(Map<String, dynamic> json) {
    return BundleDownloadUrlResult(
      downloadUrl: json['download_url'] as String? ?? '',
      checksum: json['checksum'] as String? ?? '',
    );
  }
}

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

  Future<ResponseCallback<FirmwareUpdateCheckResult>> checkForFirmwareUpdates({
    required String currentFirmwareVersion,
    required String currentDesktopAppVersion,
    String? channel,
  }) async {
    try {
      final ResponseCallback<FirmwareUpdateCheckResult> response = await networkClient.get<FirmwareUpdateCheckResult>(
        api: FusionApiEndpoint.firmwareUpdateCheck,
        urlParameters: <String, dynamic>{
          'current_firmware_version': currentFirmwareVersion,
          'current_desktop_app_version': currentDesktopAppVersion,
          if (channel != null && channel.trim().isNotEmpty) 'channel': channel.trim(),
        },
        fromJson: (dynamic json) {
          if (json is! Map<String, dynamic>) {
            throw Exception('Unexpected firmware update check response format.');
          }
          return FirmwareUpdateCheckResult.fromJson(json);
        },
      );
      return response;
    } catch (e) {
      return ResponseCallback<FirmwareUpdateCheckResult>.failure(e.toString());
    }
  }

  Future<ResponseCallback<BundleDownloadUrlResult>> requestFirmwareBundleDownloadUrl({required String bundleId}) async {
    try {
      final String trimmedBundleId = bundleId.trim();
      if (trimmedBundleId.isEmpty) {
        return ResponseCallback<BundleDownloadUrlResult>.failure('bundleId is required');
      }

      final ResponseCallback<BundleDownloadUrlResult> response = await networkClient.get<BundleDownloadUrlResult>(
        api: FusionApiEndpoint.firmwareBundleDownloadUrl,
        additionalPath: '$trimmedBundleId/request-download-url',
        fromJson: (dynamic json) {
          if (json is! Map<String, dynamic>) {
            throw Exception('Unexpected firmware bundle download response format.');
          }
          return BundleDownloadUrlResult.fromJson(json);
        },
      );

      return response;
    } catch (e) {
      return ResponseCallback<BundleDownloadUrlResult>.failure(e.toString());
    }
  }

  Future<ResponseCallback<void>> logFirmwareUpdateStatus({
    required String projectId,
    required String bundleVersion,
    required String previousVersion,
    required String launcherVersion,
    required String status,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post<dynamic>(
        api: FusionApiEndpoint.firmwareUpdateStatus,
        data: <String, dynamic>{
          'update_id': const Uuid().v4(),
          'project_id': projectId,
          'bundle_version': bundleVersion,
          'previous_version': previousVersion,
          'status': status,
          'launcher_version': launcherVersion,
          'installed_at': DateTime.now().toUtc().toIso8601String(),
        },
      );

      if (response.success) {
        return ResponseCallback<void>.success(null);
      }

      return ResponseCallback<void>.failure(response.message);
    } catch (e) {
      return ResponseCallback<void>.failure(e.toString());
    }
  }

  Future<ResponseCallback<void>> downloadFirmwareBundle({
    required String downloadUrl,
    required String targetFilePath,
    required CancelToken cancelToken,
    required void Function(int received, int total) onProgress,
  }) async {
    try {
      await networkClient.downloadFile(
        url: downloadUrl,
        savePath: targetFilePath,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );

      return ResponseCallback<void>.success(null);
    } on DioException {
      // Delete the partial file, then re-throw so callers can distinguish
      // a user cancellation (CancelToken.isCancel) from a network error.
      try {
        final File partial = File(targetFilePath);
        if (await partial.exists()) {
          await partial.delete();
        }
      } catch (_) {}
      rethrow;
    } catch (e) {
      // Non-Dio failure: clean up and return a plain failure result.
      try {
        final File partial = File(targetFilePath);
        if (await partial.exists()) {
          await partial.delete();
        }
      } catch (_) {}
      return ResponseCallback<void>.failure(e.toString());
    }
  }

  Future<ResponseCallback<void>> uploadFirmwareBundleToFusionServer({
    required String vip,
    required String bundleFilePath,
    required String checksum,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  }) async {
    try {
      final String host = vip.contains(':') ? vip : '$vip:8080';
      await networkClient.httpClient.dioInstance.post(
        'http://$host/softwareUpdate/upload',
        cancelToken: cancelToken,
        data: FormData.fromMap(
          <String, dynamic>{
            'checksum': checksum,
            'bundle': await MultipartFile.fromFile(bundleFilePath, filename: p.basename(bundleFilePath)),
          },
        ),
        onSendProgress: onProgress,
      );
      return ResponseCallback<void>.success(null);
    } catch (e) {
      return ResponseCallback<void>.failure(e.toString());
    }
  }

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
