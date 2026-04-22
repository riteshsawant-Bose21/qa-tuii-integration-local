import 'package:fusion_app/core/models/gain_model.dart';
import 'package:fusion_app/core/models/scheme_model.dart';
import 'package:fusion_app/core/models/source_input.dart';
import 'package:fusion_app/core/utils/qr_data_parser.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionZoneService {

  final FusionNetworkClient networkClient;

  FusionZoneService({required this.networkClient});

  Future<ResponseCallback<InputConfig>> getSourceSelect(Map<String,dynamic> pathParams) async {

    ResponseCallback<InputConfig> response  = await networkClient.get(
      api: FusionApiEndpoint.fusionValue,
      urlParameters: pathParams,
      isSecure: false,
      baseUrlToOverride: vipAddress,
      fromJson: (dynamic json) =>InputConfig.fromJson(json)
    );


    return response;
  }

  Future<ResponseCallback<GainConfig>> getGain(Map<String,dynamic> pathParams) async {

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
