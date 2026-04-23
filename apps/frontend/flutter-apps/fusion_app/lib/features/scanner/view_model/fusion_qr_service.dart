import 'package:fusion_lib/fusion_lib.dart';

class FusionQRService {

  final FusionNetworkClient networkClient;

  FusionQRService({required this.networkClient});

  Future<ResponseCallback<WallControllerConfig>> getSchema(vipAddress) async {

    ResponseCallback<WallControllerConfig> response  = await networkClient.get(
        api: FusionApiEndpoint.fusionValue,
        isSecure: false,
        baseUrlToOverride: vipAddress,
        fromJson: (dynamic json) => WallControllerConfig.fromJson(json),
    );
    return response;
  }


}
