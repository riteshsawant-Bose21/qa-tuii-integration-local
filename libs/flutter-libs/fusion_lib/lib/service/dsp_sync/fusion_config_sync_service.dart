import 'package:fusion_lib/fusion_lib.dart';

class FusionConfigSyncService {
  final FusionNetworkClient networkClient;

  FusionConfigSyncService({required this.networkClient});

  Future<ResponseCallback<bool>> syncConfigToDsp({
    required Map<String, dynamic> config,
    required String vip,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.put(
        api: FusionApiEndpoint.fusionSync,
        data: config,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        return ResponseCallback.success(true);
      } else {
        return ResponseCallback<bool>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      return ResponseCallback<bool>(success: false, message: e.toString());
    }
  }

  //sync wall controller config to dsp
  Future<ResponseCallback<bool>> syncWallControllerConfig({
    required Map<String, dynamic> controllerConfig,
    required String vip,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.patch(
        api: FusionApiEndpoint.wallControllerConfig,
        data: controllerConfig,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        return ResponseCallback.success(true);
      } else {
        return ResponseCallback<bool>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      return ResponseCallback<bool>(success: false, message: e.toString());
    }
  }

  //sync touch ui config to dsp
  Future<ResponseCallback<bool>> syncTouchUiConfig({
    required Map<String, dynamic> touchUiConfig,
    required String vip,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.patch(
        api: FusionApiEndpoint.touchUiConfig,
        data: touchUiConfig,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        return ResponseCallback.success(true);
      } else {
        return ResponseCallback<bool>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      return ResponseCallback<bool>(success: false, message: e.toString());
    }
  }

  Future<ResponseCallback<Map<String, dynamic>>> getConfigFromDsp({
    required String vip,
  }) async {
    try {
      final ResponseCallback<FusionStateSnapshot> response = await networkClient.getStateSnapshot(baseUrlToOverride: vip, isSecure: false);

      if (!response.success || response.data == null) {
        return ResponseCallback<Map<String, dynamic>>.failure(
          response.message,
          statusCode: response.statusCode,
        );
      }

      return ResponseCallback<Map<String, dynamic>>.success(
        response.data!.state,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseCallback.failure(e.toString());
    }
  }
}
