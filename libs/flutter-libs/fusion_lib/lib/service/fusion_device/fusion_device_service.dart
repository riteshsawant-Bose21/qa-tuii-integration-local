import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FusionDeviceService {
  final FusionNetworkClient networkClient;

  FusionDeviceService({required this.networkClient});

  Future<ResponseCallback<FirmwareUpdateCheckResult>> checkForFirmwareUpdates({
    required String currentFirmwareVersion,
    required String currentDesktopAppVersion,
    required String jenkinsBuildNumber,
  }) async {
    try {
      final ResponseCallback<FirmwareUpdateCheckResult> response = await networkClient.get<FirmwareUpdateCheckResult>(
        api: FusionApiEndpoint.firmwareUpdateCheck,
        urlParameters: <String, dynamic>{
          'current_firmware_version': currentFirmwareVersion,
          'current_desktop_app_version': currentDesktopAppVersion,
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

  Future<ResponseCallback<BundleDownloadUrlResult>> requestFirmwareBundleDownloadUrl({required String version}) async {
    try {
      if (version.isEmpty) {
        return ResponseCallback<BundleDownloadUrlResult>.failure('bundleId is required');
      }

      final ResponseCallback<BundleDownloadUrlResult> response = await networkClient.get<BundleDownloadUrlResult>(
        api: FusionApiEndpoint.firmwareBundleDownloadUrl,
        additionalPath: '$version/request-download-url',
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
      final String host = _normalizeFusionHost(vip);
      await networkClient.httpClient.dioInstance.post(
        'http://$host/softwareUpdate/upload',
        cancelToken: cancelToken,
        data: FormData.fromMap(
          <String, dynamic>{
            'checksum': checksum,
            'bundle': await MultipartFile.fromFile(
              bundleFilePath,
              filename: p.basename(bundleFilePath),
            ),
          },
        ),
        onSendProgress: onProgress,
      );
      return ResponseCallback<void>.success(null);
    } catch (e) {
      return ResponseCallback<void>.failure(e.toString());
    }
  }

  Future<ResponseCallback<void>> connectFirmwareUpdateWebSocket({required String vip}) async {
    try {
      final String host = _normalizeFusionHost(vip);
      final ResponseCallback<void> response = await networkClient.connectWebSocket<void>(url: 'ws://$host/ws');
      return response;
    } catch (e) {
      return ResponseCallback<void>.failure(e.toString());
    }
  }

  Future<ResponseCallback<void>> sendStartFirmwareUpdateEvent({required String bundleId}) async {
    try {
      final ResponseCallback<void> response = await networkClient.sendWebSocketMessage<void>(<String, dynamic>{
        'id': bundleId,
        "version": 1,
        "type": "start_update",
      });
      return response;
    } catch (e) {
      return ResponseCallback<void>.failure(e.toString());
    }
  }

  Future<ResponseCallback<void>> sendRebootStartupdateEvent({required String bundleId}) async {
    try {
      final ResponseCallback<void> response = await networkClient.sendWebSocketMessage<void>(<String, dynamic>{
        'id': bundleId,
        "version": 1,
        "type": "sw_update_info",
      });
      return response;
    } catch (e) {
      return ResponseCallback<void>.failure(e.toString());
    }
  }

  Stream<ResponseCallback<FirmwareUpdateProgressEvent>> listenFirmwareUpdateProgressEvents() async* {
    await for (final ResponseCallback<dynamic> message in networkClient.webSocketMessages) {
      if (!message.success || message.data == null) {
        yield ResponseCallback<FirmwareUpdateProgressEvent>.failure(message.message);
        continue;
      }

      final dynamic payload = message.data;
      if (payload is! Map<String, dynamic>) {
        continue;
      }

      final FirmwareUpdateProgressEvent event = FirmwareUpdateProgressEvent.fromJson(payload);
      if (!event.isUpdateProgress) {
        continue;
      }

      yield ResponseCallback<FirmwareUpdateProgressEvent>.success(event);
    }
  }

  String _normalizeFusionHost(String vip) {
    final String trimmed = vip.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.contains(':') ? trimmed : '$trimmed:8080';
  }

  Future<ResponseCallback<void>> disconnectFirmwareUpdateWebSocket() async {
    try {
      return await networkClient.disconnectWebSocket<void>();
    } catch (e) {
      return ResponseCallback<void>.failure(e.toString());
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

  Future<ResponseCallback<String>> getCsrCertificate({required String vip, required String deviceId}) async {
    try {
      final ResponseCallback<String> csrResponse = await networkClient.get(
        api: FusionApiEndpoint.fusionDevice,
        baseUrlToOverride: vip,
        isSecure: false,
        additionalPath: "$deviceId/csr",
      );

      return csrResponse;
    } catch (e) {
      return ResponseCallback<String>.failure(e.toString());
    }
  }

  Future<ResponseCallback<CloudDeviceRegisterResult>> registerSingleDevice({
    required String vip,
    required FusionNetworkDevice device,
    required String projectId,
    required String csrCertificate,
  }) async {
    try {
      final payload = <String, dynamic>{
        'client_device_id': device.id,
        'csr': csrCertificate,
        'device_location': 'device.location', // TODO: SHARTH - REMOVE this hardcoded value.
        'device_zone': 'device.location', // TODO: SHARTH - REMOVE this hardcoded value.
        'device_name': device.name,
        'is_primary': device.isPrimary,
        'mac_address': device.macAddress,
        'model_name': device.modelName,
        'project_id': projectId,
        'serial_number': device.serialNumber,
        "firmware_version": device.softwareUpdateVersion,
      };

      final ResponseCallback<CloudDeviceRegisterResult> response = await networkClient.post(
        api: FusionApiEndpoint.devicesCloud,
        fromJson: (dynamic json) => CloudDeviceRegisterResult.fromJson(json as Map<String, dynamic>),
        data: payload,
      );

      return response;
    } catch (e) {
      return ResponseCallback<CloudDeviceRegisterResult>.failure(e.toString());
    }
  }

  Future<ResponseCallback<dynamic>> updateCsrInFusionDevice({required String vip, required String fusionDeviceId, required String certificate}) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.fusionDevice,
        baseUrlToOverride: vip,
        isSecure: false,
        additionalPath: "$fusionDeviceId/certificate",
        data: certificate,
      );

      return response;
    } catch (e) {
      return ResponseCallback<dynamic>.failure("Fusion device certificate update failed at $vip");
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

  Future<ResponseCallback<dynamic>> resetDeviceCertificate({required String vip, required String fusionDeviceSerialNumber}) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.delete(
        api: FusionApiEndpoint.devicesCloud,
        additionalPath: "$fusionDeviceSerialNumber/reset",
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
