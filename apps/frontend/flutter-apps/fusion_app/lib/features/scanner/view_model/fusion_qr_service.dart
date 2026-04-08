import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_app/core/models/scheme_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionQRService {

  final FusionNetworkClient networkClient;

  FusionQRService({required this.networkClient});


  /// Login
  Future<ResponseCallback<SchemaModel>> getSchema() async {

    ResponseCallback<SchemaModel> response  = await networkClient.get(
        api: FusionApiEndpoint.fusionValue,
      isSecure: false,
        baseUrlToOverride: "192.168.1.110:8080",
        fromJson: (dynamic json) => SchemaModel.fromJson(json),
    );
    return response;
  }


}
