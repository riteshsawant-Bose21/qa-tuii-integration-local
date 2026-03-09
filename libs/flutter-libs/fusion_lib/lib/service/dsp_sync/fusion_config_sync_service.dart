import 'package:fusion_lib/fusion_lib.dart';

class FusionConfigSyncService {
  final FusionNetworkClient networkClient;

  FusionConfigSyncService({required this.networkClient});

  Future<ResponseCallback<bool>> syncConfigToDsp({required Map<String, dynamic> config, required String vip}) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.fusionValue,
        data: config,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        return ResponseCallback.success(true);
      } else {
        return ResponseCallback<bool>(success: false, message: response.message);
      }
    } catch (e) {
      return ResponseCallback<bool>(success: false, message: e.toString());
    }
  }

  Future<ResponseCallback<Map<String, dynamic>>> getConfigFromDsp({required String vip}) async {
    try {
      final ResponseCallback<Map<String, dynamic>> response = await networkClient.get(
        api: FusionApiEndpoint.fusionValue,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      return response;
    } catch (e) {
      return ResponseCallback.failure(e.toString());
    }
  }
}
