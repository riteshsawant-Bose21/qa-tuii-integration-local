import '../../../fusion_lib.dart';

/// -------------------
/// Base Repository
/// -------------------
abstract class Repository<T> {
  final Map<String, T> _items = {};

  T? get(String id) => _items[id];

  void add(String id, T item) => _items[id] = item;

  void remove(String id) => _items.remove(id);

  List<T> getAll() => _items.values.toList();

  bool exists(String id) => _items.containsKey(id);

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonFn) {
    return _items.map((key, value) => MapEntry(key, toJsonFn(value)));
  }

  void fromJson(Map<String, dynamic>? json, T Function(Map<String, dynamic>) fromJsonFn) {
    if (json == null) return;
    _items.clear();
    json.forEach((key, value) {
      _items[key] = fromJsonFn(Map<String, dynamic>.from(value));
    });
  }

  /// Populate repository from a JSON *list-like* input.
  /// Accepts:
  ///  - a List of Map objects: [ { "id":"a", ... }, { "id":"b", ... } ]
  ///  - or a Map keyed by id: { "a": {...}, "b": {...} }
  /// Each list entry MUST contain an "id" field (stringable).
  void fromJsonList(dynamic json, T Function(Map<String, dynamic>) fromJsonFn, String idFieldName) {
    _items.clear();
    if (json == null) return;

    // If a map keyed by id is provided, treat it as id->object map
    if (json is Map) {
      json.forEach((key, value) {
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(value);
        _items[key] = fromJsonFn(itemMap);
      });
      return;
    }

    // If a list is provided, each entry must be a Map and must contain an 'id'
    if (json is List) {
      for (final entry in json) {
        if (entry is! Map) {
          throw FormatException('Repository.fromJsonList: expected list entry to be Map, got ${entry.runtimeType}');
        }
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(entry);
        final idValue = itemMap[idFieldName];
        if (idValue == null) {
          throw FormatException('Repository.fromJsonList: list entry is missing required "id" field: $itemMap');
        }
        final id = idValue.toString();
        _items[id] = fromJsonFn(itemMap);
      }
      return;
    }

    throw FormatException('Repository.fromJsonList: expected List or Map, got ${json.runtimeType}');
  }
}

/// -------------------
/// Repositories
/// -------------------
class FloorRepository extends Repository<FloorModel> {}

class ListeningAreaRepository extends Repository<ListeningArea> {}

class ZoneRepository extends Repository<Zone> {
  ZoneRepository copyWith(Map<String, Zone> items) {
    final newRepo = ZoneRepository();
    newRepo._items.addAll(items);
    return newRepo;
  }
}

class SubZoneRepository extends Repository<SubZone> {}

class SourceSetRepository extends Repository<SourceSet> {
  SourceSetRepository copyWith(Map<String, SourceSet> items) {
    final newRepo = SourceSetRepository();
    newRepo._items.addAll(items);
    return newRepo;
  }
}

class HardwareRepository extends Repository<HardwareComponent> {
  HardwareRepository copyWith(Map<String, HardwareComponent> items) {
    final newRepo = HardwareRepository();
    newRepo._items.addAll(items);
    return newRepo;
  }
}

class FusionDeviceRepository extends Repository<FusionDsp> {}

class AmplifierRepository extends Repository<Amplifier> {}

class CircuitRepository extends Repository<CircuitModel> {}

class WiringConnectionRepository extends Repository<WiringConnectionModel> {}

class ProcessingBlockRepository extends Repository<ProcessingBlockModel> {}

class ScenesRepository extends Repository<SnapshotsModel> {
  ScenesRepository copyWith(Map<String, SnapshotsModel> items) {
    final newRepo = ScenesRepository();
    newRepo._items.addAll(items);
    return newRepo;
  }
}

class SceneActionRepository extends Repository<SceneActionModel> {
  SceneActionRepository copyWith(Map<String, SceneActionModel> items) {
    final newRepo = SceneActionRepository();
    newRepo._items.addAll(items);
    return newRepo;
  }
}

class SceneSetRepository extends Repository<SceneSetModel> {
  SceneSetRepository copyWith(Map<String, SceneSetModel> items) {
    final newRepo = SceneSetRepository();
    newRepo._items.addAll(items);
    return newRepo;
  }
}

class GPIORepository extends Repository<GpioConfig> {}

class SchedulerRepository extends Repository<ScheduleConfig> {}

class EventsRepository extends Repository<FusionEvent> {
  EventsRepository copyWith(Map<String, FusionEvent> items) {
    final newRepo = EventsRepository();
    newRepo._items.addAll(items);
    return newRepo;
  }
}

class MediaFileRepository extends Repository<MediaFileModel> {}

class ZoneFunctionRepository extends Repository<ZoneFunctions> {
  // Get ZoneFunction by function id
  ZoneFunctions? getByFunctionId({required String functionId}) {
    try {
      return getAll().firstWhere((zf) => zf.id == functionId);
    } catch (e) {
      return null;
    }
  }

  // Get MixScene by scene id and fucntion id
  MixScene? getMixSceneById({required String functionId, required String sceneId}) {
    try {
      final zoneFunction = getByFunctionId(functionId: functionId);
      if (zoneFunction == null) return null;
      return zoneFunction.mixScenes.firstWhere((ms) => ms.id == sceneId);
    } catch (e) {
      return null;
    }
  }

  // Get MixSetting for source id, function id and scene id
  MixSettings? getMixSettingBySourceId({required String functionId, required String sceneId, required String sourceId}) {
    try {
      final zoneFunction = getByFunctionId(functionId: functionId);
      if (zoneFunction == null) return null;
      final mixScene = zoneFunction.mixScenes.firstWhere((ms) => ms.id == sceneId);
      if (mixScene is SourceMixScene) {
        return mixScene.mixSettings.firstWhere((ms) => ms.sourceId == sourceId);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  List<MixSettings> getAllMixSettingsForFunctionAndScene({required String functionId, required String sceneId}) {
    try {
      final zoneFunction = getByFunctionId(functionId: functionId);
      if (zoneFunction == null) return [];
      final mixScene = zoneFunction.mixScenes.firstWhere((ms) => ms.id == sceneId);
      if (mixScene is SourceMixScene) {
        return mixScene.mixSettings;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  MatrixMixer? getAllMatrixForFunctionAndScene({required String functionId, required String sceneId}) {
    try {
      final zoneFunction = getByFunctionId(functionId: functionId);
      if (zoneFunction == null) return null;
      final mixScene = zoneFunction.mixScenes.firstWhere((ms) => ms.id == sceneId);
      if (mixScene is MatrixMixScene) {
        return mixScene.mixerConfig;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  List<MatrixSettings> getAllMatrixSettingsFunctionAndScene({required String functionId, required String sceneId}) {
    try {
      final zoneFunction = getByFunctionId(functionId: functionId);
      if (zoneFunction == null) return [];
      final mixScene = zoneFunction.mixScenes.firstWhere((ms) => ms.id == sceneId);
      if (mixScene is MatrixMixScene) {
        return mixScene.mixerConfig.settings;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}

class PrioritySourceDataRepository extends Repository<PrioritySourceData> {
  PrioritySourceDataRepository() : super();

  List<PrioritySourceData> getByZone(String zoneId) {
    try {
      List<PrioritySourceData> priorityData = getAll().where((psd) => psd.zoneId == zoneId).toList();
      //order by priority ascending
      priorityData.sort((a, b) => a.priority.compareTo(b.priority));
      return priorityData;
    } catch (e) {
      return [];
    }
  }

  List<PrioritySourceData> getBySource(String sourceId) {
    try {
      return getAll().where((psd) => psd.sourceId == sourceId).toList();
    } catch (e) {
      return [];
    }
  }

  PrioritySourceData? getByZoneAndSource(String zoneId, String sourceId) {
    try {
      return getAll().firstWhere((psd) => psd.zoneId == zoneId && psd.sourceId == sourceId);
    } catch (e) {
      return null;
    }
  }
}

class EquipLocationRepository extends Repository<EquipLocation> {}
