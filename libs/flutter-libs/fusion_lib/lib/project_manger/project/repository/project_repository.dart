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
}

/// -------------------
/// Repositories
/// -------------------
class FloorRepository extends Repository<FloorModel> {}

class ListeningAreaRepository extends Repository<ListeningArea> {}

class ZoneRepository extends Repository<Zone> {}

class SourceSetRepository extends Repository<SourceSet> {}

class HardwareRepository extends Repository<HardwareComponent> {}

class FusionDeviceRepository extends Repository<FusionDevice> {}

class AmplifierRepository extends Repository<Amplifier> {}
