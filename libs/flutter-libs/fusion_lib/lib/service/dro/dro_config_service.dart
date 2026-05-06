import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';

import 'dro_native_resolver_service.dart';

class DroConfigService {
  final FusionNetworkClient _fusionNetworkClient;

  DroConfigService(this._fusionNetworkClient);

  Future<ResponseCallback<DroResponseData>> getRefinedConfig({
    required DroInputModel droInput,
    required String droServerUrl,
  }) async {
    try {
      // final ResponseCallback<DroResponseData> response = await _fusionNetworkClient.post(
      //   api: FusionApiEndpoint.process,
      //   data: droInput.toJson(),
      //   baseUrlToOverride: droServerUrl,
      //   isSecure: false,
      //   fromJson: (val) => DroResponseData.fromJson(val),
      // );

      final FusionDro dro = FusionDro();

      final inputJson = jsonEncode(droInput.toJson());

      final resultJson = dro.solve(inputJson);
      final result = jsonDecode(resultJson);
      FusionLogger.log(tag: LogTag.dro, message: "Response received from DRO ");
      DroResponseData response = DroResponseData.fromJson(result);

      if (response.statusCode == 200) {
        return ResponseCallback.success(response);
      } else {
        return ResponseCallback.failure(response.error ?? response.statusMessage ?? "Something went wrong", data: response);
      }
    } catch (ex) {
      return ResponseCallback.failure(ex.toString());
    }
  }
}
