import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/generated/proto/fusion/time_machine.pb.dart'
    as model;

import 'package:fusion_lib/generated/proto/google/protobuf/struct.pb.dart'
    as structpb;

class FusionSceneCatalogSyncService {
  final FusionNetworkClient networkClient;

  FusionSceneCatalogSyncService({required this.networkClient});

  Future<ResponseCallback<bool>> syncSceneCatalog({
    required String vip,
    required SnapshotsRequestDto? snapshotList,
    required SceneSetRequestDto? sceneSetList,
  }) async {
    try {
      for (final SnapshotItemDto snapshot
          in snapshotList?.snapshots ?? const <SnapshotItemDto>[]) {
        final model.SnapshotDefinition request = _toSnapshotDefinition(
          snapshot,
        );
        final ResponseCallback<dynamic> response = await networkClient.put(
          api: FusionApiEndpoint.snapshots,
          additionalPath: request.id,
          baseUrlToOverride: vip,
          isSecure: false,
          data: request,
        );

        if (!response.success) {
          return ResponseCallback<bool>.failure(
            'Failed to sync snapshot ${request.id}: ${response.message}',
          );
        }
      }

      for (final SceneSetDto sceneSet
          in sceneSetList?.sceneSets ?? const <SceneSetDto>[]) {
        final model.SceneSet request = _toSceneSet(sceneSet);
        final ResponseCallback<dynamic> response = await networkClient.put(
          api: FusionApiEndpoint.sceneSets,
          additionalPath: request.setId,
          baseUrlToOverride: vip,
          isSecure: false,
          data: request,
        );

        if (!response.success) {
          return ResponseCallback<bool>.failure(
            'Failed to sync scene set ${request.setId}: ${response.message}',
          );
        }
      }

      return ResponseCallback<bool>.success(true);
    } catch (e) {
      return ResponseCallback<bool>.failure(
        'Failed to sync scene catalog: $e',
      );
    }
  }

  model.SnapshotDefinition _toSnapshotDefinition(SnapshotItemDto snapshot) {
    return model.SnapshotDefinition()
      ..id = snapshot.id
      ..name = snapshot.name
      ..data = _structFromJson(snapshot.data.toJson());
  }

  model.Scene _toScene(SnapshotItemDto scene) {
    return model.Scene()
      ..id = scene.id
      ..name = scene.name
      ..data = _structFromJson(scene.data.toJson());
  }

  model.SceneSet _toSceneSet(SceneSetDto sceneSet) {
    final model.SceneSet request =
        model.SceneSet()
          ..setId = sceneSet.setId
          ..name = sceneSet.name
          ..scenes.addAll(sceneSet.scenes.map(_toScene));

    if (sceneSet.defaultScene != null && sceneSet.defaultScene!.isNotEmpty) {
      request.defaultScene = sceneSet.defaultScene!;
    }

    return request;
  }

  structpb.Struct _structFromJson(Map<String, dynamic> json) {
    final structpb.Struct value = structpb.Struct();
    value.mergeFromProto3Json(json);
    return value;
  }
}
