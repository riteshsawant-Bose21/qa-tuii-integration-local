import 'package:fusion_lib/fusion_lib.dart';

class DroConfigService {
  final FusionNetworkClient _fusionNetworkClient;

  DroConfigService(this._fusionNetworkClient);

  Future<ResponseCallback<DroResponseData>> getRefinedConfig({
    required DroInputModel droInput,
    required String droServerUrl,
  }) async {
    try {
      final ResponseCallback<DroResponseData> response = await _fusionNetworkClient.post(
        api: FusionApiEndpoint.process,
        data: droInput.toJson(),
        baseUrlToOverride: droServerUrl,
        isSecure: false,
        fromJson: (val) => DroResponseData.fromJson(val),
      );
      print("received the response ${response.message}");
      if (response.success && response.data!.error == null) {
        return ResponseCallback.success(response.data);
      } else {
        return ResponseCallback.failure(response.data!.error ?? response.message, data: response.data);
      }
    } catch (ex) {
      return ResponseCallback.failure(ex.toString());
    }
  }
}
