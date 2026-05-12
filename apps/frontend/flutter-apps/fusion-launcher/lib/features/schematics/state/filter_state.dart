import 'package:fusion_lib/fusion_lib.dart';

class FilterViewModelState {
  const FilterViewModelState({
    this.filterMode = false,
    this.floorOpen = const <String, bool>{},
    this.floorChecked = const <String, bool>{},
    this.areaChecked = const <String, bool>{},
    this.zoneChecked = const <String, bool>{},
    this.subZoneChecked = const <String, bool>{},
    this.locationChecked = const <String, bool>{},
    this.editingFloors = const <String, bool>{},
    this.editingAreas = const <String, bool>{},
    this.editingLocations = const <String, bool>{},
  });

  final bool filterMode;
  final Map<String, bool> floorOpen;
  final Map<String, bool> floorChecked;
  final Map<String, bool> areaChecked;
  final Map<String, bool> zoneChecked;
  final Map<String, bool> subZoneChecked;
  final Map<String, bool> locationChecked;
  final Map<String, bool> editingFloors;
  final Map<String, bool> editingAreas;
  final Map<String, bool> editingLocations;

  // ── Convenience getters ───────────────────────────────────────────────────

  bool isFloorOpen(String id) => floorOpen[id] ?? false;
  bool isFloorChecked(String id) => floorChecked[id] ?? false;
  bool isAreaChecked(String id) => areaChecked[id] ?? false;
  bool isZoneChecked(String id) => zoneChecked[id] ?? false;
  bool isSubZoneChecked(String id) => subZoneChecked[id] ?? false;
  bool isLocationChecked(String id) => locationChecked[id] ?? false;
  bool isFloorEditing(String id) => editingFloors[id] ?? false;
  bool isAreaEditing(String id) => editingAreas[id] ?? false;
  bool isLocationEditing(String id) => editingLocations[id] ?? false;

  List<String> get checkedFloorIds => floorChecked.entries.where((MapEntry<String, bool> e) => e.value).map((MapEntry<String, bool> e) => e.key).toList();

  List<String> get checkedAreaIds => areaChecked.entries.where((MapEntry<String, bool> e) => e.value).map((MapEntry<String, bool> e) => e.key).toList();

  List<String> get checkedZoneIds => zoneChecked.entries.where((MapEntry<String, bool> e) => e.value).map((MapEntry<String, bool> e) => e.key).toList();

  List<String> get checkedSubZoneIds => subZoneChecked.entries.where((MapEntry<String, bool> e) => e.value).map((MapEntry<String, bool> e) => e.key).toList();

  List<String> get checkedLocationIds => locationChecked.entries.where((MapEntry<String, bool> e) => e.value).map((MapEntry<String, bool> e) => e.key).toList();

  // ── hasActiveFilters — all categories ────────────────────────────────────

  bool get hasActiveFilters =>
      checkedFloorIds.isNotEmpty || checkedAreaIds.isNotEmpty || checkedZoneIds.isNotEmpty || checkedSubZoneIds.isNotEmpty || checkedLocationIds.isNotEmpty;

  // ── passesFilter ──────────────────────────────────────────────────────────
  //
  // Logic: AND across categories; OR within each category.
  //
  // LocationModel only exposes `floorId` and `listeningAreaId`, so only
  // those two categories can be applied at the device level right now.
  //
  // Zone, SubZone, and EquipmentLocation filters are intentionally left out:
  // LocationModel has no zoneId / subZoneId / equipLocationId fields.
  // The checkboxes for those sections still render in the UI and their state
  // is stored, but they will have no effect on filtering until those fields
  // are added to LocationModel (and this method is extended accordingly).

  bool passesFilter(HardwareComponent device) {
    if (!hasActiveFilters) return true;

    final String? deviceFloorId = device.locationEntity.floorId;
    final String? deviceAreaId = device.locationEntity.listeningAreaId;

    // ── FLOOR filter (AND) ───────────────────────────────────────────────
    if (checkedFloorIds.isNotEmpty) {
      if (deviceFloorId == null || !checkedFloorIds.contains(deviceFloorId)) {
        return false;
      }
    }

    // ── LISTENING AREA filter (AND) ──────────────────────────────────────
    if (checkedAreaIds.isNotEmpty) {
      if (deviceAreaId == null || !checkedAreaIds.contains(deviceAreaId)) {
        return false;
      }
    }

    // ── ZONE / SUB-ZONE / EQUIPMENT LOCATION ─────────────────────────────
    // TODO: LocationModel does not yet carry zoneId, subZoneId, or
    // equipLocationId. Extend LocationModel and add filter checks here once
    // those fields are available.

    return true;
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  FilterViewModelState copyWith({
    bool? filterMode,
    Map<String, bool>? floorOpen,
    Map<String, bool>? floorChecked,
    Map<String, bool>? areaChecked,
    Map<String, bool>? zoneChecked,
    Map<String, bool>? subZoneChecked,
    Map<String, bool>? locationChecked,
    Map<String, bool>? editingFloors,
    Map<String, bool>? editingAreas,
    Map<String, bool>? editingLocations,
  }) {
    return FilterViewModelState(
      filterMode: filterMode ?? this.filterMode,
      floorOpen: floorOpen ?? this.floorOpen,
      floorChecked: floorChecked ?? this.floorChecked,
      areaChecked: areaChecked ?? this.areaChecked,
      zoneChecked: zoneChecked ?? this.zoneChecked,
      subZoneChecked: subZoneChecked ?? this.subZoneChecked,
      locationChecked: locationChecked ?? this.locationChecked,
      editingFloors: editingFloors ?? this.editingFloors,
      editingAreas: editingAreas ?? this.editingAreas,
      editingLocations: editingLocations ?? this.editingLocations,
    );
  }
}
