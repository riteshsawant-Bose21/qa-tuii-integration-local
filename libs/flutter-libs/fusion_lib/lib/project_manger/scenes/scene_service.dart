import 'package:fusion_lib/fusion_lib.dart';

extension SceneService on ProjectService {
  void addNewSnapshots(SnapshotsModel scene) {
    snapshots.add(scene.id, scene);
  }

  void updateSnapshots(SnapshotsModel scene) {
    if (!snapshots.exists(scene.id)) {
      throw Exception("Scene with id ${scene.id} does not exist.");
    }
    snapshots.add(scene.id, scene);
  }

  void addNewSceneAction({required SceneActionModel action}) {
    sceneActions.add(action.id, action);
  }

  void removeSceneAction(String actionId) {
    if (!sceneActions.exists(actionId)) {
      throw Exception("Scene Action with id $actionId does not exist.");
    }
    sceneActions.remove(actionId);

    final parentId = relationships.getParent(RelationshipType.sceneActions, actionId);
    if (parentId != null) {
      relationships.unlink(RelationshipType.sceneActions, parentId, actionId);
    }
  }

  void addSceneActionToSnapshot({required String sceneId, required SceneActionModel action}) {
    final scene = snapshots.get(sceneId);
    if (scene == null) {
      throw Exception("Scene with id $sceneId does not exist.");
    }
    sceneActions.add(action.id, action);
    relationships.link(RelationshipType.sceneActions, sceneId, action.id);
  }

  void removeSceneActionFromSnapshot({required String sceneId, required String actionId}) {
    if (!sceneActions.exists(actionId)) {
      throw Exception("Scene Action with id $actionId does not exist.");
    }
    relationships.unlink(RelationshipType.sceneActions, sceneId, actionId);
    sceneActions.remove(actionId);
  }

  List<SceneActionModel> getSceneActionsForSnapshot(String sceneId) {
    final actionIds = relationships.getChildren(RelationshipType.sceneActions, sceneId);
    return actionIds.map((id) => sceneActions.get(id)).whereType<SceneActionModel>().toList();
  }

  void updateSceneActionType({required String actionId, required SceneActionType actionType}) {
    final sceneAction = sceneActions.get(actionId);
    if (sceneAction == null) {
      throw Exception("Scene Action with id $actionId does not exist ");
    }
    final updatedScene = sceneAction.copyWith(actionType: actionType, item: null, param: null, value: null);
    sceneActions.add(actionId, updatedScene);
  }

  void updateSceneActionItem({required String actionId, required SceneItem item}) {
    final action = sceneActions.get(actionId);
    if (action == null) {
      throw Exception("SceneAction with id $action does not exist.");
    }
    final updatedScene = action.copyWith(item: item, param: null, value: null);
    sceneActions.add(actionId, updatedScene);
  }

  void updateSceneActionParam({required String actionId, required SceneParam param}) {
    final scene = sceneActions.get(actionId);
    if (scene == null) {
      throw Exception("SceneAction with id $actionId does not exist.");
    }
    //add a empty value based on param type for rendering purposes
    SceneValue value = SceneValue(
      valueType: param.type.valueType,
      label: param.type.valueLabel,
    );
    final updatedScene = scene.copyWith(param: param, value: value);
    sceneActions.add(actionId, updatedScene);
  }

  void updateSceneActionValue({required String actionId, required SceneValue value}) {
    final scene = sceneActions.get(actionId);
    if (scene == null) {
      throw Exception("SceneAction with id $actionId does not exist.");
    }
    final updatedScene = scene.copyWith(value: value);
    sceneActions.add(actionId, updatedScene);
  }

  void removeSnapshots(String sceneId) {
    if (!snapshots.exists(sceneId)) {
      throw Exception("Scene with id $sceneId does not exist.");
    }

    //remove all scene actions linked to this scene
    final actionIds = relationships.getChildren(RelationshipType.sceneActions, sceneId);
    final List<String> actionsToRemove = List.from(actionIds);
    for (var actionId in actionsToRemove) {
      removeSceneActionFromSnapshot(sceneId: sceneId, actionId: actionId);
    }
    //check if scene is in any scene set
    final parentSets = relationships.getParent(RelationshipType.sceneSetScenes, sceneId);
    if (parentSets != null) {
      removeSnapshotFromSceneSet(sceneSetId: parentSets, sceneId: sceneId);
    }
    snapshots.remove(sceneId);
  }

  List<SceneActionType> getSceneActionTypes() {
    return SceneActionType.values;
  }

  //Get Action Items based on Action Type
  List<SceneItemDropdown> getActionItemsByType(SceneActionType actionType) {
    switch (actionType) {
      case SceneActionType.zoneControl:
        return zones.getAll().map((zone) => SceneItemDropdown(id: zone.id, name: zone.name)).toList();
      // case SceneActionType.sourceControl:
      //   return hardware.getAll().whereType<Source>().map((source) => SceneItemDropdown(id: source.id, name: source.name)).toList();
      case SceneActionType.deviceControl:
        //return only power smart amplifiers, need a better flag in hardware in future
        final List<String> powerSmartAmplifierSkus = [
          'PSM-4150',
          'PSM-4300',
          'PSM-4600',
          'PSM-8300',
          'PSM-8600',
          'PSM-41500',
        ];
        return hardware
            .getAll()
            .whereType<Amplifier>()
            .where((amp) => powerSmartAmplifierSkus.contains(amp.sku))
            .map(
              (device) => SceneItemDropdown(
                id: device.id,
                name: device.name,
              ),
            )
            .toList();
      case SceneActionType.gpOut:
        return gpioConfigs
            .getAll()
            .where((gpio) => (gpio.direction == GpioDirection.output))
            .map(
              (gpOut) => SceneItemDropdown(
                id: gpOut.id,
                name: gpOut.name,
              ),
            )
            .toList();
      case SceneActionType.scene:
        return sceneSets.getAll().map((scene) => SceneItemDropdown(id: scene.id, name: scene.name)).toList();
      case SceneActionType.snapshot:
        return []; // Snapshots might not have direct items
    }
  }

  List<SceneParam> getParamsByActionTypeAndItem(SceneActionType actionType, SceneItem item) {
    switch (actionType) {
      case SceneActionType.zoneControl:
        return _getZoneControlParams(item);
      case SceneActionType.deviceControl:
        return [_createParam(SceneParamType.standby)];
      case SceneActionType.gpOut:
        return [
          _createParam(SceneParamType.setState),
          _createParam(SceneParamType.pulse),
        ];
      case SceneActionType.scene:
      case SceneActionType.snapshot:
        return [_createParam(SceneParamType.recall)];
    }
  }

  // Helper method to create a SceneParam
  SceneParam _createParam(SceneParamType type, {String? associatedId}) {
    return SceneParam(
      label: type.displayName,
      type: type,
      associatedId: associatedId,
    );
  }

  // Helper method to get common zone parameters
  List<SceneParam> _getCommonZoneParams() {
    return [
      _createParam(SceneParamType.volume),
      _createParam(SceneParamType.mute),
    ];
  }

  // Helper method to get priority parameters
  List<SceneParam> _getPriorityParams() {
    return [
      _createParam(SceneParamType.prioritySelect1),
      _createParam(SceneParamType.prioritySelect2),
    ];
  }

  // Helper method to get source mix parameters
  List<SceneParam> _getSourceMixParams(String zoneId) {
    final params = <SceneParam>[_createParam(SceneParamType.mixScene)];
    final sourcesInZone = getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);

    for (var source in sourcesInZone) {
      params.addAll([
        SceneParam(
          label: '${source.name} level',
          type: SceneParamType.inputLevel,
          associatedId: source.id,
        ),
        SceneParam(
          label: '${source.name} mute',
          type: SceneParamType.inputMute,
          associatedId: source.id,
        ),
      ]);
    }

    return params;
  }

  // Main zone control logic
  List<SceneParam> _getZoneControlParams(SceneItem item) {
    final params = _getCommonZoneParams();
    final zoneFunction = getZoneFunction(zoneId: item.itemId);

    if (zoneFunction == null) return params;

    switch (zoneFunction.type) {
      case ZoneFunctionsType.sourceSelect:
        params.add(_createParam(SceneParamType.sourceSelect));

      case ZoneFunctionsType.sourceSelectWithPriority:
        params.add(_createParam(SceneParamType.sourceSelect));
        params.addAll(_getPriorityParams());

      case ZoneFunctionsType.sourceMix:
        params.addAll(_getSourceMixParams(item.itemId));

      case ZoneFunctionsType.sourceMixWithPriority:
        params.addAll(_getSourceMixParams(item.itemId));
        params.addAll(_getPriorityParams());

      case ZoneFunctionsType.miniMatrix:
        params.add(_createParam(SceneParamType.mixScene));

      case ZoneFunctionsType.miniMatrixWithPriority:
        params.add(_createParam(SceneParamType.mixScene));
        params.addAll(_getPriorityParams());
    }

    return params;
  }

  //get Dropdown value for a SceneParam
  List<SceneValueDropdown> getSceneActionValueDropdownItems(String actionId) {
    final scene = sceneActions.get(actionId);
    if (scene == null || scene.item == null || scene.param == null) {
      throw Exception("SceneAction or SceneParam or SceneItem with id $actionId does not exist.");
    }

    final param = scene.param!;
    final actionType = scene.actionType;

    switch (param.type) {
      case SceneParamType.sourceSelect:
        final zoneFunction = getZoneFunction(zoneId: scene.item!.itemId);
        if (zoneFunction == null) return [];
        final sourcesInZone = getSourcesAndSourceSetSourcesInZone(zoneId: scene.item!.itemId);
        return sourcesInZone
            .map(
              (source) => SceneValueDropdown(
                label: source.name,
                value: source.id,
              ),
            )
            .toList();
      case SceneParamType.mixScene:
        final zoneFunction = getZoneFunction(zoneId: scene.item!.itemId);
        if (zoneFunction == null) return [];
        return zoneFunction.mixScenes
            .map(
              (mixScene) => SceneValueDropdown(
                value: mixScene.id,
                label: mixScene.name,
              ),
            )
            .toList();
      case SceneParamType.recall:
        if (actionType == SceneActionType.scene) {
          return getSnapshotInSceneSet(scene.item!.itemId)
              .map(
                (SnapshotsModel scene) => SceneValueDropdown(
                  value: scene.id,
                  label: scene.name,
                ),
              )
              .toList();
        } else if (actionType == SceneActionType.snapshot) {
          return getAllSnapshots()
              .map(
                (SnapshotsModel snapshot) => SceneValueDropdown(
                  value: snapshot.id,
                  label: snapshot.name,
                ),
              )
              .toList();
        } else {
          return [];
        }

      case SceneParamType.prioritySelect1:
      case SceneParamType.prioritySelect2:
        final zoneFunction = getZoneFunction(zoneId: scene.item!.itemId);
        if (zoneFunction == null) return [];
        final sourcesInZone = getSourcesAndSourceSetSourcesInZone(zoneId: scene.item!.itemId);
        return sourcesInZone
            .map(
              (source) => SceneValueDropdown(
                label: source.name,
                value: source.id,
              ),
            )
            .toList();
      default:
        return [];
    }
  }

  List<SnapshotsModel> getAllSnapshots() {
    //return scenes which are not in any scene set, where get parent is null
    final List<SnapshotsModel> allScenes = snapshots.getAll();

    final List<SnapshotsModel> standaloneScenes = allScenes.where((scene) {
      final parentSet = relationships.getParent(RelationshipType.sceneSetScenes, scene.id);
      return parentSet == null || parentSet.isEmpty;
    }).toList();

    return standaloneScenes;
  }

  SnapshotsModel? getSnapshotById(String sceneId) {
    return snapshots.get(sceneId);
  }

  //Scene Sets
  void addNewSceneSet(SceneSetModel sceneSet) {
    sceneSets.add(sceneSet.id, sceneSet);
  }

  void updateSceneSet(SceneSetModel sceneSet) {
    if (!sceneSets.exists(sceneSet.id)) {
      throw Exception("Scene Set with id ${sceneSet.id} does not exist.");
    }
    sceneSets.add(sceneSet.id, sceneSet);
  }

  void deleteSceneSet(String sceneSetId) {
    if (!sceneSets.exists(sceneSetId)) {
      throw Exception("Scene Set with id $sceneSetId does not exist.");
    }
    sceneSets.remove(sceneSetId);
    // Optionally, also remove all relationships
    relationships.removeAllRelationships(sceneSetId);
  }

  List<SceneSetModel> getAllSceneSets() {
    return sceneSets.getAll();
  }

  void addNewSnapshotToSceneSet({required String sceneSetId, required SnapshotsModel scene}) {
    final sceneSet = sceneSets.get(sceneSetId);
    if (sceneSet == null) {
      throw Exception("Scene Set with id $sceneSetId does not exist.");
    }
    addNewSnapshots(scene);
    relationships.link(RelationshipType.sceneSetScenes, sceneSetId, scene.id);
  }

  void addSnapshotToSceneSet({required String sceneSetId, required String sceneId}) {
    final sceneSet = sceneSets.get(sceneSetId);
    if (sceneSet == null) {
      throw Exception("Scene Set with id $sceneSetId does not exist.");
    }
    if (!snapshots.exists(sceneId)) {
      throw Exception("Scene with id $sceneId does not exist.");
    }
    relationships.link(RelationshipType.sceneSetScenes, sceneSetId, sceneId);
  }

  void removeSnapshotFromSceneSet({required String sceneSetId, required String sceneId}) {
    final sceneSet = sceneSets.get(sceneSetId);
    if (sceneSet == null) {
      throw Exception("Scene Set with id $sceneSetId does not exist.");
    }
    if (!snapshots.exists(sceneId)) {
      throw Exception("Scene with id $sceneId does not exist.");
    }
    relationships.unlink(RelationshipType.sceneSetScenes, sceneSetId, sceneId);
  }

  List<SnapshotsModel> getSnapshotInSceneSet(String sceneSetId) {
    final sceneIds = relationships.getChildren(RelationshipType.sceneSetScenes, sceneSetId);
    return sceneIds.map((id) => snapshots.get(id)).whereType<SnapshotsModel>().toList();
  }

  //Reorder Scenes in Scene Set
  void reOrderSnapshotInSceneSet(String parentId, int oldIndex, int newIndex) {
    final scenesInSceneSet = relationships.getChildren(RelationshipType.sceneSetScenes, parentId).toList();

    final item = scenesInSceneSet.removeAt(oldIndex);
    scenesInSceneSet.insert(newIndex, item);

    relationships.reOrder(RelationshipType.sceneSetScenes, parentId, scenesInSceneSet);
  }

  void reOderSceneActionsInSnapshot(String parentId, int oldIndex, int newIndex) {
    final actionsInScene = relationships.getChildren(RelationshipType.sceneActions, parentId).toList();

    final item = actionsInScene.removeAt(oldIndex);
    actionsInScene.insert(newIndex, item);

    relationships.reOrder(RelationshipType.sceneActions, parentId, actionsInScene);
  }

  Map<String, SceneSetModel> reOderSceneSets({
    required String sceneSetIdToMove,
    required String sceneSetAtNewIndexId,
  }) {
    List<SceneSetModel> items = sceneSets.getAll();

    // Find indices
    int fromIndex = items.indexWhere((ss) => ss.id == sceneSetIdToMove);
    int toIndex = items.indexWhere((ss) => ss.id == sceneSetAtNewIndexId);

    // Validate
    if (fromIndex == -1 || toIndex == -1) {
      throw ArgumentError('Invalid SceneSet IDs');
    }

    // Reorder using List operations
    SceneSetModel item = items.removeAt(fromIndex);
    items.insert(toIndex, item);

    // Convert back to Map
    return {for (var ss in items) ss.id: ss};
  }

  Map<String, SnapshotsModel> reOderSnapshots({
    required String sceneIdToMove,
    required String sceneAtNewIndexId,
  }) {
    List<SnapshotsModel> items = snapshots.getAll();

    // Find indices
    int fromIndex = items.indexWhere((s) => s.id == sceneIdToMove);
    int toIndex = items.indexWhere((s) => s.id == sceneAtNewIndexId);

    // Validate
    if (fromIndex == -1 || toIndex == -1) {
      throw ArgumentError('Invalid Scene IDs');
    }

    // Reorder using List operations
    SnapshotsModel item = items.removeAt(fromIndex);
    items.insert(toIndex, item);

    // Convert back to Map
    return {for (var s in items) s.id: s};
  }

  void duplicateSceneAction(String actionId) {
    final originalAction = sceneActions.get(actionId);
    if (originalAction == null) {
      throw Exception("Scene Action with id $actionId does not exist.");
    }

    final duplicatedAction = originalAction.copyWith(
      id: "ACTION${FusionUtils.shortStringUUID()}",
    );

    sceneActions.add(duplicatedAction.id, duplicatedAction);

    final parentId = relationships.getParent(RelationshipType.sceneActions, actionId);
    if (parentId != null) {
      relationships.link(RelationshipType.sceneActions, parentId, duplicatedAction.id);
    }
  }

  void duplicateSnapshot(String sceneId) {
    final originalScene = snapshots.get(sceneId);
    if (originalScene == null) {
      throw Exception("Scene with id $sceneId does not exist.");
    }

    final duplicatedScene = originalScene.copyWith(
      id: "SCENE${FusionUtils.shortStringUUID()}",
      name: "${originalScene.name} Copy",
    );

    snapshots.add(duplicatedScene.id, duplicatedScene);

    final parentSetId = relationships.getParent(RelationshipType.sceneSetScenes, sceneId);
    if (parentSetId != null) {
      relationships.link(RelationshipType.sceneSetScenes, parentSetId, duplicatedScene.id);
    }

    List<String> actionIds = relationships.getChildren(RelationshipType.sceneActions, sceneId).toList();
    for (var actionId in actionIds) {
      final originalAction = sceneActions.get(actionId);
      if (originalAction != null) {
        final duplicatedAction = originalAction.copyWith(
          id: "ACTION${FusionUtils.shortStringUUID()}",
        );
        sceneActions.add(duplicatedAction.id, duplicatedAction);
        relationships.link(RelationshipType.sceneActions, duplicatedScene.id, duplicatedAction.id);
      }
    }
  }

  void duplicateSceneSet(String sceneSetId) {
    final originalSceneSet = sceneSets.get(sceneSetId);
    if (originalSceneSet == null) {
      throw Exception("Scene Set with id $sceneSetId does not exist.");
    }

    final duplicatedSceneSet = originalSceneSet.copyWith(
      id: "SCENESET${FusionUtils.shortStringUUID()}",
      name: "${originalSceneSet.name} Copy",
    );

    sceneSets.add(duplicatedSceneSet.id, duplicatedSceneSet);

    List<String> sceneIds = relationships.getChildren(RelationshipType.sceneSetScenes, sceneSetId).toList();
    for (var sceneId in sceneIds) {
      duplicateSnapshot(sceneId);
    }
  }
}
