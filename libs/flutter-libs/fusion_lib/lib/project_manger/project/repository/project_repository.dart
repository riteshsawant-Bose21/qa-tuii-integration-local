import 'package:fusion_lib/models/project_entities/circuit_model.dart';

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

class ZoneFunctionRepository extends Repository<ZoneFunctions> {}

class PrioritySourceDataRepository extends Repository<PrioritySourceData> {
  PrioritySourceDataRepository() : super();

  List<PrioritySourceData> getByZone(String zoneId) {
    List<PrioritySourceData> priorityData = getAll().where((psd) => psd.zoneId == zoneId).toList();
    //order by priority ascending
    priorityData.sort((a, b) => a.priority.compareTo(b.priority));
    return priorityData;
  }

  List<PrioritySourceData> getBySource(String sourceId) {
    return getAll().where((psd) => psd.sourceId == sourceId).toList();
  }

  PrioritySourceData? getByZoneAndSource(String zoneId, String sourceId) {
    try {
      return getAll().firstWhere((psd) => psd.zoneId == zoneId && psd.sourceId == sourceId);
    } catch (e) {
      return null;
    }
  }
}

class MixSceneRepository extends Repository<MixScene> {
  MixSceneRepository() : super();
}

class MixSettingsRepository extends Repository<MixSettings> {
  MixSettingsRepository() : super();

  /// Get setting by the triple (function, scene, source)
  MixSettings? getByContext({
    required String functionId,
    required String sceneId,
    required String sourceId,
  }) {
    return getAll().firstWhere(
      (setting) => setting.functionId == functionId && setting.sceneId == sceneId && setting.sourceId == sourceId,
    );
  }

  /// Get all settings for a function
  List<MixSettings> getByFunction(String functionId) {
    return getAll().where((s) => s.functionId == functionId).toList();
  }

  /// Get all settings for a scene
  List<MixSettings> getByScene(String sceneId) {
    return getAll().where((s) => s.sceneId == sceneId).toList();
  }

  /// Get all settings for a source
  List<MixSettings> getBySource(String sourceId) {
    return getAll().where((s) => s.sourceId == sourceId).toList();
  }
}

class MatrixSettingsRepository extends Repository<MatrixSettings> {
  MatrixSettingsRepository() : super();

  /// Get setting by the triple (function, scene, source)
  MatrixSettings? getByContext({
    required String functionId,
    required String sceneId,
    required String sourceId,
  }) {
    return getAll().firstWhere(
      (setting) => setting.functionId == functionId && setting.sceneId == sceneId && setting.sourceId == sourceId,
    );
  }

  /// Get all settings for a function
  List<MatrixSettings> getByFunction(String functionId) {
    return getAll().where((s) => s.functionId == functionId).toList();
  }

  /// Get all settings for a scene
  List<MatrixSettings> getByScene(String sceneId) {
    return getAll().where((s) => s.sceneId == sceneId).toList();
  }

  /// Get all settings for a source
  List<MatrixSettings> getBySource(String sourceId) {
    return getAll().where((s) => s.sourceId == sourceId).toList();
  }
}
