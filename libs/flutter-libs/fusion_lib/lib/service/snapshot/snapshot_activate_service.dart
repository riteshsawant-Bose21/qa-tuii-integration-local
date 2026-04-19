import 'package:fusion_lib/fusion_lib.dart';

class SnapshotActivateService {
  final FusionNetworkClient networkClient;

  SnapshotActivateService({required this.networkClient});

  /// PUT /snapshots/activate/:name — activate a snapshot by name
  Future<ResponseCallback<bool>> activateSnapshot({
    required String vip,
    required String name,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.put(
        api: FusionApiEndpoint.snapshotsActivate,
        additionalPath: name,
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

  /// PATCH /Value
  Future<ResponseCallback<bool>> updateSnapshotAndSceneSet({
    required String vip,
    required SnapshotsRequestDto? snapshotList,
    required SceneSetRequestDto? sceneSetList,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.patch(
        api: FusionApiEndpoint.fusionValue,
        data: <String, dynamic>{
          ...(snapshotList?.toJson() ?? {'snapshots': []}),
          ...(sceneSetList?.toJson() ?? {'scene_sets': []}),
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
