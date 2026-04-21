import 'package:fusion_lib/fusion_lib.dart';

class SceneSetActivateService {
  final FusionNetworkClient networkClient;

  SceneSetActivateService({required this.networkClient});

  /// POST /scene-sets/activate — activate a scene set by set_id and scene_id
  Future<ResponseCallback<bool>> activateSceneSet({
    required String vip,
    required String setId,
    required String sceneId,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.sceneSetsActivate,
        data: <String, dynamic>{
          'set_id': setId,
          'scene_id': sceneId,
        },
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        return ResponseCallback<bool>.success(true);
      } else {
        return ResponseCallback<bool>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }
}
