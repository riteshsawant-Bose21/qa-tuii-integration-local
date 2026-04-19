import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/snapshot_api/snapshots_request.dart';
import 'package:fusion_lib/models/project_entities/sncene_set/scene_set_request.dart';

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

    final itemIds = relationships.getChildren(RelationshipType.actionItemMapping, actionId);
    final copyOfItemIds = List<String>.from(itemIds);
    for (var itemId in copyOfItemIds) {
      relationships.unlink(RelationshipType.actionItemMapping, actionId, itemId);
    }

    final valueIds = relationships.getChildren(RelationshipType.actionValueMapping, actionId);
    final copyOfValueIds = List<String>.from(valueIds);
    for (var valueId in copyOfValueIds) {
      relationships.unlink(RelationshipType.actionValueMapping, actionId, valueId);
    }
  }

  SceneSetRequestDto? getSceneSetRequestDtoData() {
    try {
      final List<SceneSetDto> sceneSetDtos = [];
      final List<SceneSetModel> allSceneSets = sceneSets.getAll();
      if (allSceneSets.isEmpty) {
        return null;
      }

      for (SceneSetModel sceneSet in allSceneSets) {
        final List<SnapshotsModel> snapshotsInSet = getSnapshotInSceneSet(sceneSet.id);
        if (snapshotsInSet.isEmpty) {
          continue; //if there is no snapshot in scene set, skip this scene set
        }
        final List<SnapshotItemDto> scenesDto = [];
        for (SnapshotsModel snapshot in snapshotsInSet) {
          final List<SceneActionModel> actions = getSceneActionsForSnapshot(snapshot.id);
          final List<SceneActionModel> zoneActions = actions.where((action) => action.actionType == SceneActionType.zoneControl).toList();
          final Map<String, dynamic> audio = getDynamicDataForActions(zoneActions);
          final SnapshotItemDto snapshotDto = SnapshotItemDto(
            id: snapshot.id,
            name: snapshot.name,
            data: SnapshotDataDto(
              settings: SnapshotSettingsDto(
                audio: audio,
              ),
            ),
          );
          scenesDto.add(snapshotDto);
        }

        sceneSetDtos.add(
          SceneSetDto(
            setId: sceneSet.id,
            name: sceneSet.name,
            // defaultScene: sceneSet.defaultScene,
            scenes: scenesDto,
          ),
        );
      }

      return SceneSetRequestDto(sceneSets: sceneSetDtos);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get SceneSetRequestDto : $ex");
      return null;
    }
  }

  SnapshotsRequestDto? getSnapshotsRequestDtoData() {
    try {
      final List<SnapshotItemDto> snapshotsDto = [];
      final List<SnapshotsModel> allSnapshots = getAllSnapshots();
      if (allSnapshots.isEmpty) {
        return null;
      }

      for (SnapshotsModel snapshot in allSnapshots) {
        final List<SceneActionModel> actions = getSceneActionsForSnapshot(snapshot.id);
        final List<SceneActionModel> zoneActions = actions.where((action) => action.actionType == SceneActionType.zoneControl).toList();
        if (zoneActions.isEmpty) {
          continue;
        }
        final Map<String, dynamic> audio = getDynamicDataForActions(zoneActions);
        snapshotsDto.add(
          SnapshotItemDto(
            id: snapshot.id,
            name: snapshot.name,
            data: SnapshotDataDto(
              settings: SnapshotSettingsDto(
                audio: audio,
              ),
            ),
          ),
        );
      }

      //include all the actions in the events
      final List<FusionEvent> allEvents = events.getAll();
      for (FusionEvent event in allEvents) {
        final List<SceneActionModel> actions = getEventActionsForEvent(event.id);
        final List<SceneActionModel> zoneActions = actions.where((action) => action.actionType == SceneActionType.zoneControl).toList();
        if (zoneActions.isEmpty) {
          continue;
        }
        final Map<String, dynamic> audio = getDynamicDataForActions(zoneActions);
        snapshotsDto.add(
          SnapshotItemDto(
            id: event.id,
            name: event.name,
            data: SnapshotDataDto(
              settings: SnapshotSettingsDto(
                audio: audio,
              ),
            ),
          ),
        );
      }

      //todo: Include all the mixscene actions in the zones funtions
      // final List<ZoneFunctions> allZoneFunctions = zoneFunctions.getAll();
      // for (ZoneFunctions zoneFunction in allZoneFunctions) {
      //   final List<MixScene> mixScenes = zoneFunction.mixScenes;
      //
      // }

      return SnapshotsRequestDto(snapshots: snapshotsDto);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get SnapshotsRequestDto : $ex");
      return null;
    }
  }

  Map<String, dynamic> getDynamicDataForActions(List<SceneActionModel> sceneActions) {
    final Map<String, dynamic> data = {};
    for (SceneActionModel action in sceneActions) {
      final SceneActionType? actionType = action.actionType;

      //todo: we need to add support for all other action types in future
      if (actionType != SceneActionType.zoneControl) {
        continue; // Currently, we are only interested in zone control actions for audio data
      }
      final SceneItem? item = action.item;
      if (item == null) {
        continue; // If item is null, skip this action
      }
      final SceneParam? param = action.param;
      if (param == null) {
        continue; // If param is null, skip this action
      }
      final SceneValue? value = action.value;
      if (value == null) {
        continue; // If value is null, skip this action
      }

      switch (param.type) {
        case SceneParamType.volume:
        case SceneParamType.mute:
          //Get the user facing zone control and set its gain or mute to the value
          final ProcessingBlockModel? userFacingGain = getUserFacingGainBlockForParent(item.itemId);
          if (userFacingGain == null) {
            continue; //if there is no user facing gain block, skip this action
          }
          if (param.type == SceneParamType.volume) {
            final double gainValue = FusionUtils().percentageToDbfs(double.tryParse(value.value ?? "0") ?? 0);
            data[userFacingGain.id] = {
              "gain": gainValue,
            };
          } else if (param.type == SceneParamType.mute) {
            bool isMuted = value.value?.toLowerCase() == "mute";
            data[userFacingGain.id] = {
              "mute": isMuted,
            };
          }
        case SceneParamType.sourceSelect:
          //set the source index as the source
          final String? sourceId = value.value;
          if (sourceId == null) {
            continue; //if there is no source selected, skip this action
          }
          final ZoneFunctions? zoneFunction = getZoneFunction(zoneOrSubZoneId: item.itemId);
          if (zoneFunction == null) {
            continue; //if there is no zone function, skip this action
          }
          final int? sourceIndex = zoneFunction.sourceIndex != null && zoneFunction.sourceIndex!.containsKey(sourceId)
              ? zoneFunction.sourceIndex![sourceId]
              : null;
          if (sourceIndex == null) {
            continue; //if source index is not found, skip this action
          }
          data[zoneFunction.id] = {
            "input": sourceIndex + 1,
          };
        case SceneParamType.inputLevel:
        case SceneParamType.inputMute:
          //set the source index as the source
          final String? sourceId = param.associatedId;
          if (sourceId == null) {
            continue; //if there is no source selected, skip this action
          }
          final ZoneFunctions? zoneFunction = getZoneFunction(zoneOrSubZoneId: item.itemId);
          if (zoneFunction == null) {
            continue; //if there is no zone function, skip this action
          }
          final int? sourceIndex = zoneFunction.sourceIndex != null && zoneFunction.sourceIndex!.containsKey(sourceId)
              ? zoneFunction.sourceIndex![sourceId]
              : null;
          if (sourceIndex == null) {
            continue; //if source index is not found, skip this action
          }
          if (param.type == SceneParamType.inputLevel) {
            final double levelValue = double.tryParse(value.value ?? "0") ?? 0;

            Map<String, dynamic> algorithmData = data[zoneFunction.id] != null
                ? data[zoneFunction.id] is Map<String, dynamic>
                      ? data[zoneFunction.id]
                      : <String, dynamic>{}
                : <String, dynamic>{};

            List<dynamic> valueList = algorithmData["input_gain"] is List<dynamic> ? data["input_gain"] as List<dynamic> : <dynamic>[];
            if (valueList.length <= sourceIndex) {
              valueList.addAll(List<dynamic>.filled(sourceIndex - valueList.length + 1, null));
            }
            valueList[sourceIndex] = levelValue;
            algorithmData["input_gain"] = valueList;

            data[zoneFunction.id] = algorithmData;
          } else if (param.type == SceneParamType.inputMute) {
            bool isMuted = value.value?.toLowerCase() == "mute";
            Map<String, dynamic> algorithmData = data[zoneFunction.id] != null
                ? data[zoneFunction.id] is Map<String, dynamic>
                      ? data[zoneFunction.id]
                      : <String, dynamic>{}
                : <String, dynamic>{};
            List<dynamic> valueList = algorithmData["input_mute"] is List<dynamic> ? data["input_mute"] as List<dynamic> : <dynamic>[];
            if (valueList.length <= sourceIndex) {
              valueList.addAll(List<dynamic>.filled(sourceIndex - valueList.length + 1, null));
            }
            valueList[sourceIndex] = isMuted;
            algorithmData["input_mute"] = valueList;
            data[zoneFunction.id] = algorithmData;
          }

        //bellow cases are not implemented yet, we will add support for them in future, for now we just skip them in data generation
        case SceneParamType.mixScene:
        case SceneParamType.prioritySelect1:
        case SceneParamType.prioritySelect2:
        case SceneParamType.recall:
        case SceneParamType.pulse:
        case SceneParamType.standby:
        case SceneParamType.setState:
          continue;
      }
    }
    return data;
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
    removeSceneAction(actionId);
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
    final updatedScene = sceneAction.updateActionType(actionType);
    sceneActions.add(actionId, updatedScene);
  }

  void updateSceneActionItem({required String actionId, required SceneItem item}) {
    final action = sceneActions.get(actionId);
    if (action == null) {
      throw Exception("SceneAction with id $action does not exist.");
    }
    final updatedScene = action.updateItem(item);
    //check and unlink old item relationship
    final oldItemId = relationships.getChildren(RelationshipType.actionItemMapping, actionId);
    if (oldItemId.isNotEmpty) {
      relationships.unlink(RelationshipType.actionItemMapping, actionId, oldItemId.first);
    }
    //link new item relationship
    relationships.link(RelationshipType.actionItemMapping, actionId, item.itemId);
    sceneActions.add(actionId, updatedScene);
  }

  void updateSceneActionParam({required String actionId, required SceneParam param, String? eventId}) {
    final scene = sceneActions.get(actionId);
    if (scene == null) {
      throw Exception("SceneAction with id $actionId does not exist.");
    }
    bool enalbled = true;

    bool hasStates = false;
    print("Event ID in updateSceneActionParam: $eventId");
    //for events with threshold or state change condition, we need  save value for two states
    if (eventId != null) {
      final event = events.get(eventId);
      if (event != null && event.condition != null && (event.condition is ThresholdCondition || event.condition is StateChangeCondition)) {
        hasStates = true;
      } else if (event != null && event.condition != null && (event.condition is ValueChangeCondition)) {
        //only for value change condition, we do not give option to edit value, because values are set based on analog voltage value levels
        enalbled = false;
      }
    }

    if (param.type == SceneParamType.inputLevel && param.associatedId != null) {
      final oldValueIds = relationships.getChildren(RelationshipType.actionValueMapping, actionId);
      final copyOfOldValueIds = List<String>.from(oldValueIds);
      for (var oldValueId in copyOfOldValueIds) {
        relationships.unlink(RelationshipType.actionValueMapping, actionId, oldValueId);
      }

      relationships.link(RelationshipType.actionValueMapping, actionId, param.associatedId!);
    }

    //add a empty value based on param type for rendering purposes
    SceneValue value = SceneValue(
      valueType: param.type.valueType,
      label: param.type.valueLabel,
      hasStates: hasStates,
      enabled: enalbled,
      states: hasStates ? SceneStateValue() : null,
    );
    final updatedScene = scene.copyWith(param: param, value: value);
    sceneActions.add(actionId, updatedScene);
  }

  void updateSceneActionValue({required String actionId, required SceneValue value}) {
    final scene = sceneActions.get(actionId);
    if (scene == null) {
      throw Exception("SceneAction with id $actionId does not exist.");
    }
    //save dropdown value for mapping
    if (value.valueType == SceneParamValueType.dropdownSingle) {
      //remove old mapping
      final oldValueIds = relationships.getChildren(RelationshipType.actionValueMapping, actionId);
      final copyOfOldValueIds = List<String>.from(oldValueIds);
      for (var oldValueId in copyOfOldValueIds) {
        relationships.unlink(RelationshipType.actionValueMapping, actionId, oldValueId);
      }

      //link new value
      if (value.hasStates && value.states != null) {
        //link both states
        if (value.states!.value1 != null) {
          relationships.link(RelationshipType.actionValueMapping, actionId, value.states!.value1!);
        }

        if (value.states!.value2 != null) {
          relationships.link(RelationshipType.actionValueMapping, actionId, value.states!.value2!);
        }
      } else {
        if (value.value != null) {
          relationships.link(RelationshipType.actionValueMapping, actionId, value.value!);
        }
      }
    }

    final updatedScene = scene.copyWith(value: value);
    sceneActions.add(actionId, updatedScene);
  }

  void removeSnapshots(String snapshotId) {
    if (!snapshots.exists(snapshotId)) {
      throw Exception("Scene with id $snapshotId does not exist.");
    }

    //remove all scene actions linked to this scene
    final actionIds = relationships.getChildren(RelationshipType.sceneActions, snapshotId);
    final List<String> actionsToRemove = List.from(actionIds);
    for (var actionId in actionsToRemove) {
      removeSceneActionFromSnapshot(sceneId: snapshotId, actionId: actionId);
    }
    //check if scene is in any scene set
    final parentSets = relationships.getParent(RelationshipType.sceneSetScenes, snapshotId);
    if (parentSets != null) {
      removeSnapshotFromSceneSet(sceneSetId: parentSets, sceneId: snapshotId);
    }
    snapshots.remove(snapshotId);
  }

  List<SceneActionType> getSceneActionTypes({String? eventId, required bool isFromSnapshot}) {
    //for events return values based on condition
    if (eventId != null) {
      //get event to check if its value change condition
      final event = events.get(eventId);
      if (event != null && event.condition != null && event.condition is ValueChangeCondition) {
        //for value change condition, only allow zone control actions
        return [
          SceneActionType.zoneControl,
        ];
      }
    }
    if (isFromSnapshot) {
      //if action is being added from snapshot, do not allow snapshot action type
      return SceneActionType.values.where((type) => type != SceneActionType.snapshot).toList();
    }

    return SceneActionType.values;
  }

  SceneSetModel? getSceneSetForSnapshot(String snapshotId) {
    final parentSetId = relationships.getParent(RelationshipType.sceneSetScenes, snapshotId);
    if (parentSetId != null) {
      return sceneSets.get(parentSetId);
    }
    return null;
  }

  //Get Action Items based on Action Type
  List<SceneItemDropdown> getActionItemsByType(SceneActionType actionType) {
    switch (actionType) {
      case SceneActionType.zoneControl:
        List<Zone> zonesList = zones.getAll();

        List<SubZone> subZonesList = subZones.getAll();

        return [
          ...zonesList.map((zone) => SceneItemDropdown(id: zone.id, name: zone.name)),
          ...subZonesList.map(
            (subZone) => SceneItemDropdown(
              id: subZone.id,
              name: "${getZoneForSubZone(subZoneId: subZone.id).name}/${subZone.name}",
            ),
          ),
        ].toList();

      // return zones.getAll().map((zone) => SceneItemDropdown(id: zone.id, name: zone.name)).toList();
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

  List<SceneParam> getParamsByActionTypeAndItem({required SceneActionType actionType, required SceneItem item, String? eventId}) {
    switch (actionType) {
      case SceneActionType.zoneControl:
        return _getZoneControlParams(item: item, eventId: eventId);
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
  List<SceneParam> _getCommonZoneParams(bool addOnlyLevelParam, String zoneOrSubZoneId) {
    //check if it is subzone or zone
    final bool isZone = zones.exists(zoneOrSubZoneId);
    //check if zone has subzones
    final bool hasSubZones = isZone && relationships.getChildren(RelationshipType.zoneSubZones, zoneOrSubZoneId).isNotEmpty;
    if (hasSubZones) {
      //if zone has subzones, do not allow volume/mute control at zone level
      return [];
    }
    return [
      _createParam(SceneParamType.volume),
      if (!addOnlyLevelParam) _createParam(SceneParamType.mute),
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
  List<SceneParam> _getSourceMixParams(String zoneId, bool addOnlyLevelParam) {
    final params = <SceneParam>[
      if (!addOnlyLevelParam) _createParam(SceneParamType.mixScene),
    ];
    final sourcesInZone = getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);

    for (var source in sourcesInZone) {
      params.addAll([
        SceneParam(
          label: '${source.name} level',
          type: SceneParamType.inputLevel,
          associatedId: source.id,
        ),
        if (!addOnlyLevelParam)
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
  List<SceneParam> _getZoneControlParams({required SceneItem item, String? eventId}) {
    bool addOnlyLevelParam = false;
    //for events with value change condition, only add volume level
    if (eventId != null) {
      final event = events.get(eventId);
      if (event != null && event.condition != null && event.condition is ValueChangeCondition) {
        addOnlyLevelParam = true;
      }
    }

    final params = _getCommonZoneParams(addOnlyLevelParam, item.itemId);
    final zoneFunction = getZoneFunction(zoneOrSubZoneId: item.itemId);

    if (zoneFunction == null) return params;

    switch (zoneFunction.type) {
      case ZoneFunctionsType.sourceSelect:
        if (addOnlyLevelParam) break;
        params.add(_createParam(SceneParamType.sourceSelect));

      case ZoneFunctionsType.sourceSelectWithPriority:
        if (addOnlyLevelParam) break;
        params.add(_createParam(SceneParamType.sourceSelect));
        params.addAll(_getPriorityParams());

      case ZoneFunctionsType.sourceMix:
        params.addAll(_getSourceMixParams(item.itemId, addOnlyLevelParam));

      case ZoneFunctionsType.sourceMixWithPriority:
        params.addAll(_getSourceMixParams(item.itemId, addOnlyLevelParam));
        if (!addOnlyLevelParam) {
          params.addAll(_getPriorityParams());
        }

      case ZoneFunctionsType.sourceMatrix:
        if (addOnlyLevelParam) break;
        params.add(_createParam(SceneParamType.mixScene));

      case ZoneFunctionsType.sourceMatrixWithPriority:
        if (addOnlyLevelParam) break;
        params.add(_createParam(SceneParamType.mixScene));
        params.addAll(_getPriorityParams());
    }

    return params;
  }

  //get Dropdown value for a SceneParam
  List<SceneValueDropdown> getSceneActionValueDropdownItems(String actionId) {
    final scene = sceneActions.get(actionId);
    if (scene == null || (scene.actionType != SceneActionType.snapshot && scene.item == null) || scene.param == null) {
      throw Exception("SceneAction or SceneParam or SceneItem with id $actionId does not exist.");
    }

    final param = scene.param!;
    final actionType = scene.actionType;

    switch (param.type) {
      case SceneParamType.sourceSelect:
        final zoneFunction = getZoneFunction(zoneOrSubZoneId: scene.item!.itemId);
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
        final zoneFunction = getZoneFunction(zoneOrSubZoneId: scene.item!.itemId);
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

    //remove all snapshots linked to this scene set
    final snapshotIds = relationships.getChildren(RelationshipType.sceneSetScenes, sceneSetId);
    final List<String> snapshotsToRemove = List.from(snapshotIds);
    for (var snapshotId in snapshotsToRemove) {
      removeSnapshots(snapshotId);
    }

    //remove actions associated with scene set
    final actionIds = relationships.getParents(RelationshipType.actionItemMapping, sceneSetId);
    final List<String> actionsToRemove = List.from(actionIds);
    for (var actionId in actionsToRemove) {
      removeSceneAction(actionId);
    }

    sceneSets.remove(sceneSetId);
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

    //check if any action has snapshot recall with this snapshot and remove it
    final actionIds = relationships.getParents(RelationshipType.actionValueMapping, sceneId);
    for (var actionId in actionIds) {
      removeSceneAction(actionId);
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

    //check if any action has scene recall with this snapshot and remove it
    final actionIds = relationships.getParents(RelationshipType.actionValueMapping, sceneId);
    for (var actionId in actionIds) {
      removeSceneAction(actionId);
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
