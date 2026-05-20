import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/generated/proto/fusion/devices.pb.dart' as model;

class FusionDeviceDiscoveryService {
  final FusionNetworkClient networkClient;

  FusionDeviceDiscoveryService({required this.networkClient});

  Future<ResponseCallback<List<FusionNetworkDevice>>> getAvailableDevicesOnNetwork({
    required String ip,
  }) async {
    try {
      final ResponseCallback<model.DeviceListResponse> response = await networkClient.getProto<model.DeviceListResponse>(
        api: FusionApiEndpoint.fusionDevice,
        baseUrlToOverride: ip,
        isSecure: false,
        create: model.DeviceListResponse.create,
      );

      print(
        "getAvailableDevicesOnNetwork response: success=${response.success}, statusCode=${response.statusCode}, message=${response.message}, data=${response.data}",
      );
      if (!response.success || response.data == null) {
        return ResponseCallback<List<FusionNetworkDevice>>.failure(
          response.message,
          statusCode: response.statusCode,
        );
      }

      // print("Raw devices from response: ${response.data!.devices.map((d) => d.toString()).toList()}");

      return ResponseCallback<List<FusionNetworkDevice>>.success(
        response.data!.devices.map(_toFusionNetworkDevice).toList(),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseCallback<List<FusionNetworkDevice>>.failure(e.toString());
    }
  }

  FusionNetworkDevice _toFusionNetworkDevice(model.DeviceInfo device) {
    final String serialNumber = device.serialNumber;
    final String fallbackModelName = serialNumber == '07323a09dabc1d39' ? 'XLRPAL' : 'FM8Y';

    return FusionNetworkDevice(
      address: device.address,
      id: device.id,
      location: device.location,
      name: device.name,
      modelName: device.modelName.isNotEmpty ? device.modelName : fallbackModelName,
      serialNumber: serialNumber,
      isPrimary: device.isPrimary,
      macAddress: device.macAddress,
      softwareUpdateVersion: device.softwareUpdateVersion,
      jenkinsBuildNumber: device.jenkinsBuildNumber,
      preReleaseTag: device.preReleaseTag,
      fusionMonorepoBranch: device.fusionMonorepoBranch,
      fusionMonorepoCommitHash: device.fusionMonorepoCommitHash,
      isDeviceCertificateValid: device.isDeviceCertificateValid,
    );
  }
}
