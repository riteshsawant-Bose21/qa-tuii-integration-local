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

  bool get hasActiveFilters =>
      checkedFloorIds.isNotEmpty || checkedAreaIds.isNotEmpty || checkedZoneIds.isNotEmpty || checkedSubZoneIds.isNotEmpty || checkedLocationIds.isNotEmpty;

  bool get hasActiveHardwareFilters => checkedFloorIds.isNotEmpty || checkedAreaIds.isNotEmpty;

  bool passesFilter(HardwareComponent device) {
    if (!hasActiveHardwareFilters) return true;

    final String? deviceFloorId = device.locationEntity.floorId;
    final String? deviceAreaId = device.locationEntity.listeningAreaId;

    // ── FIX ───────────────────────────────────────────────────────────────
    // BUG (original): null-check came before contains-check, so any device
    // with no floor/area was immediately excluded whenever a floor or area
    // filter was active — including after Select All.
    //
    // Correct rule: only exclude a device when it HAS a location value that
    // does NOT appear in the checked set. A null (unassigned) field is
    // never grounds for exclusion — you can't filter by a location that
    // hasn't been set yet.
    //
    // Examples with Select All (all floors + all areas checked):
    //   device { floor: "f1", area: null } → floor "f1" ∈ checked ✓, area null → skip ✓ → shown
    //   device { floor: null, area: null } → both null → both skipped ✓ → shown
    //   device { floor: "f1", area: "a1" } → both ∈ checked ✓ → shown
    //
    // Examples with Floor 1 only checked:
    //   device { floor: "f2", area: null } → floor "f2" ∉ checked → excluded ✓
    //   device { floor: null, area: null } → floor null → skip, area null → skip → shown
    // ─────────────────────────────────────────────────────────────────────

    // FLOOR: only exclude if the device has a floor that is NOT checked
    if (checkedFloorIds.isNotEmpty && deviceFloorId != null) {
      if (!checkedFloorIds.contains(deviceFloorId)) return false;
    }

    // AREA: only exclude if the device has an area that is NOT checked
    if (checkedAreaIds.isNotEmpty && deviceAreaId != null) {
      if (!checkedAreaIds.contains(deviceAreaId)) return false;
    }

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
