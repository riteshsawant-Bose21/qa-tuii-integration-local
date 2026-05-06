import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/models/response_callback.dart';
import 'package:fusion_lib/models/virtual_controller/gain_model.dart';
import 'package:fusion_lib/models/virtual_controller/source_input.dart';

class FusionVirtualControllerService {

  final FusionNetworkClient networkClient;

  FusionVirtualControllerService({required this.networkClient});

  Future<ResponseCallback<InputConfig>> getSourceSelect(Map<String,dynamic> pathParams,String vipAddress,String funcID) async {

    ResponseCallback<InputConfig> response  = await networkClient.get(
      api: FusionApiEndpoint.fusionValue,
      urlParameters: pathParams,
      isSecure: false,
      baseUrlToOverride: vipAddress,
      fromJson: (dynamic json) => InputConfig.fromJson(json,funcID)
    );


    return response;
  }

  Future<ResponseCallback<GainConfig>> getGain(Map<String,dynamic> pathParams,String vipAddress) async {

    ResponseCallback<GainConfig> response  = await networkClient.get(
      api: FusionApiEndpoint.fusionValue,
      urlParameters: pathParams,
      isSecure: false,
      baseUrlToOverride: vipAddress,
      fromJson: (dynamic json) => GainConfig.fromJson(json),
    );


    return response;
  }

}