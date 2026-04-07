import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_app/core/models/gain_model.dart';
import 'package:fusion_app/core/models/scheme_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionZoneService {

  final FusionNetworkClient networkClient;

  FusionZoneService({required this.networkClient});


  Future<ResponseCallback<SchemaModel>> updateGain(Map<String,dynamic> data) async {

    ResponseCallback<SchemaModel> response  = await networkClient.patch(
      api: FusionApiEndpoint.fusionGetValue,
      data: data,
      baseUrlToOverride: "192.168.1.110:8080",
      fromJson: (Map<String, dynamic> json) => SchemaModel.fromJson(json),
    );


    return response;
  }

  Future<ResponseCallback<GainConfig>> getGain(Map<String,dynamic> pathParams) async {

    print("pathParams");
    print(pathParams);

    ResponseCallback<GainConfig> response  = await networkClient.get(
      api: FusionApiEndpoint.fusionGetValue,
      urlParameters: pathParams,
      baseUrlToOverride: "192.168.1.110:8080",
      fromJson: (Map<String, dynamic> json) => GainConfig.fromJson(json),
    );


    return response;
  }

}
