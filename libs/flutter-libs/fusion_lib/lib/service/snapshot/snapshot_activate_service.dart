import 'package:fusion_lib/fusion_lib.dart';

class SnapshotActivateService {
  final FusionNetworkClient networkClient;

  SnapshotActivateService({required this.networkClient});

  Future<ResponseCallback<bool>> activateSnapshot({
    required String vip,
    required String name,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.snapshotsActivate,
        additionalPath: name,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        return ResponseCallback<bool>.success(true);
      }
      return ResponseCallback<bool>.failure(response.message);
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }

  /// Sends one request per [SnapshotItemDto] in [snapshotList] and one
  /// request per [SceneSetDto] in [sceneSetList].
  ///
  /// Behavior:
  /// 1. Fetches the existing snapshots (`GET /snapshots`) and scene-sets
  ///    (`GET /scene-sets`) from the device in parallel.
  /// 2. For every item we want to push:
  ///    - If its id (`SnapshotItemDto.id` / `SceneSetDto.setId`) is already
  ///      present on the device, the item is sent as a `PUT` (update).
  ///    - Otherwise the item is sent as a `POST` (create).
  /// 3. All create/update requests are dispatched in parallel via
  ///    [Future.wait]. Returns success only if every request succeeds,
  ///    otherwise returns a failure with the combined error messages.
  Future<ResponseCallback<bool>> updateSnapshotAndSceneSet({
    required String vip,
    required SnapshotsRequestDto? snapshotList,
    required SceneSetRequestDto? sceneSetList,
  }) async {
    try {
      final List<SnapshotItemDto> snapshots = snapshotList?.snapshots ?? <SnapshotItemDto>[];
      final List<SceneSetDto> sceneSets = sceneSetList?.sceneSets ?? <SceneSetDto>[];

      if (snapshots.isEmpty && sceneSets.isEmpty) {
        return ResponseCallback<bool>.success(true);
      }

      // Step 1: Fetch existing ids in parallel.
      final List<ResponseCallback<dynamic>> existing = await Future.wait(<Future<ResponseCallback<dynamic>>>[
        if (snapshots.isNotEmpty)
          networkClient.get<dynamic>(
            api: FusionApiEndpoint.snapshots,
            baseUrlToOverride: vip,
            isSecure: false,
          )
        else
          Future<ResponseCallback<dynamic>>.value(ResponseCallback<dynamic>.success(null)),
        if (sceneSets.isNotEmpty)
          networkClient.get<dynamic>(
            api: FusionApiEndpoint.sceneSets,
            baseUrlToOverride: vip,
            isSecure: false,
          )
        else
          Future<ResponseCallback<dynamic>>.value(ResponseCallback<dynamic>.success(null)),
      ]);

      final Set<String> existingSnapshotIds = _extractIds(
        existing[0].data,
        listKeys: const <String>[
          'snapshots',
        ],
        idKeys: const <String>['id'],
      );

      final Set<String> existingSceneSetIds = _extractIds(
        existing[1].data,
        listKeys: const <String>['scene_sets'],
        idKeys: const <String>['set_id'],
      );

      // Step 2: Build PUT / POST requests for each item.
      final List<Future<ResponseCallback<dynamic>>> requests = <Future<ResponseCallback<dynamic>>>[];

      for (final SnapshotItemDto snapshot in snapshots) {
        final Map<String, dynamic> body = snapshot.toJson();
        if (existingSnapshotIds.contains(snapshot.id)) {
          requests.add(
            networkClient.put<dynamic>(
              api: FusionApiEndpoint.snapshots,
              additionalPath: snapshot.id,
              data: body,
              baseUrlToOverride: vip,
              isSecure: false,
            ),
          );
        } else {
          requests.add(
            networkClient.post<dynamic>(
              api: FusionApiEndpoint.snapshots,
              data: body,
              baseUrlToOverride: vip,
              isSecure: false,
            ),
          );
        }
      }

      for (final SceneSetDto sceneSet in sceneSets) {
        final Map<String, dynamic> body = sceneSet.toJson();
        if (existingSceneSetIds.contains(sceneSet.setId)) {
          requests.add(
            networkClient.put<dynamic>(
              api: FusionApiEndpoint.sceneSets,
              additionalPath: sceneSet.setId,
              data: body,
              baseUrlToOverride: vip,
              isSecure: false,
            ),
          );
        } else {
          requests.add(
            networkClient.post<dynamic>(
              api: FusionApiEndpoint.sceneSets,
              data: body,
              baseUrlToOverride: vip,
              isSecure: false,
            ),
          );
        }
      }

      if (requests.isEmpty) {
        return ResponseCallback<bool>.success(true);
      }

      final List<ResponseCallback<dynamic>> responses = await Future.wait(requests);

      final List<String> failures = <String>[
        for (final ResponseCallback<dynamic> r in responses)
          if (!r.success) r.message,
      ];

      if (failures.isEmpty) {
        return ResponseCallback<bool>.success(true);
      }
      return ResponseCallback<bool>.failure(failures.join('; '));
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }

  /// Extracts a set of ids from a GET response payload.
  ///
  /// The payload is expected to be either:
  /// - A `List` of items, or
  /// - A `Map` containing one of [listKeys] whose value is a list of items.
  ///
  /// Each item is then probed for the first matching key in [idKeys].
  Set<String> _extractIds(
    dynamic payload, {
    required List<String> listKeys,
    required List<String> idKeys,
  }) {
    if (payload == null) return <String>{};

    List<dynamic>? items;
    if (payload is List<dynamic>) {
      items = payload;
    } else if (payload is Map<String, dynamic>) {
      for (final String key in listKeys) {
        final dynamic value = payload[key];
        if (value is List<dynamic>) {
          items = value;
          break;
        }
      }
    }

    if (items == null) return <String>{};

    final Set<String> ids = <String>{};
    for (final dynamic item in items) {
      if (item is Map<String, dynamic>) {
        for (final String idKey in idKeys) {
          final dynamic id = item[idKey];
          if (id is String && id.isNotEmpty) {
            ids.add(id);
            break;
          }
        }
      }
    }
    return ids;
  }
}
