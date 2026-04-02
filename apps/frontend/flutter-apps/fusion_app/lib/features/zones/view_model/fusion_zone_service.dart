import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_app/core/models/scheme_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionZoneService {

  final FusionNetworkClient networkClient;

  FusionZoneService({required this.networkClient});


  Future<ResponseCallback<SchemaModel>> updateGain(Map<String,dynamic> data,Map<String,dynamic> pathParams) async {

    ResponseCallback<SchemaModel> response  = await networkClient.patch(
      api: FusionApiEndpoint.fusionGetValue,
      data: data,
      urlParameters: pathParams,
      baseUrlToOverride: "192.168.1.100:8080",
      fromJson: (Map<String, dynamic> json) => SchemaModel.fromJson(json),
    );


    return response;
  }



}
