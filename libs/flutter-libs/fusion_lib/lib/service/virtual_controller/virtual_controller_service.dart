import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/fusion_networking/network/models/fusion_state_models.dart';
import 'package:fusion_lib/models/response_callback.dart';
import 'package:fusion_lib/models/virtual_controller/gain_model.dart';
import 'package:fusion_lib/models/virtual_controller/source_input.dart';

class FusionVirtualControllerService {
  final FusionNetworkClient networkClient;

  FusionVirtualControllerService({required this.networkClient});

  Future<ResponseCallback<InputConfig>> getSourceSelect(
    Map<String, dynamic> pathParams,
    String vipAddress,
  ) async {
    final String key = pathParams['key'] as String? ?? '';
    final ResponseCallback<FusionStateValue<InputValue>> response =
        await networkClient.getStateValue<InputValue>(
          key: key,
          baseUrlToOverride: vipAddress,
          isSecure: false,
          decodeValue: (dynamic value) =>
              InputValue.fromJson(value as Map<String, dynamic>),
        );

    if (!response.success || response.data == null) {
      return ResponseCallback<InputConfig>.failure(
        response.message,
        statusCode: response.statusCode,
      );
    }

    return ResponseCallback<InputConfig>.success(
      InputConfig(
        exists: response.data!.exists,
        value: response.data!.value ?? InputValue(input: 0),
      ),
      statusCode: response.statusCode,
    );
  }

  Future<ResponseCallback<GainConfig>> getGain(
    Map<String, dynamic> pathParams,
    String vipAddress,
  ) async {
    final String key = pathParams['key'] as String? ?? '';
    final ResponseCallback<FusionStateValue<GainValue>> response =
        await networkClient.getStateValue<GainValue>(
          key: key,
          baseUrlToOverride: vipAddress,
          isSecure: false,
          decodeValue: (dynamic value) =>
              GainValue.fromJson(value as Map<String, dynamic>),
        );

    if (!response.success || response.data == null) {
      return ResponseCallback<GainConfig>.failure(
        response.message,
        statusCode: response.statusCode,
      );
    }

    return ResponseCallback<GainConfig>.success(
      GainConfig(
        exists: response.data!.exists,
        value: response.data!.value ?? GainValue(gain: 0, mute: false),
      ),
      statusCode: response.statusCode,
    );
  }
}
