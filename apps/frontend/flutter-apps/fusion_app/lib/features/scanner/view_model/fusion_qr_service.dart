import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_app/core/models/scheme_model.dart';
import 'package:fusion_app/core/utils/qr_data_parser.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionQRService {

  final FusionNetworkClient networkClient;

  FusionQRService({required this.networkClient});


  /// Login
  Future<ResponseCallback<SchemaModel>> getSchema(vipAddress) async {

    ResponseCallback<SchemaModel> response  = await networkClient.get(
        api: FusionApiEndpoint.fusionValue,
        isSecure: false,
        baseUrlToOverride: vipAddress,
        fromJson: (dynamic json) => SchemaModel.fromJson(json),
    );
    return response;
  }


}
