import 'package:fusion_lib/fusion_lib.dart';

class FusionDeviceService {
  final FusionNetworkClient networkClient;

  FusionDeviceService({required this.networkClient});

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
