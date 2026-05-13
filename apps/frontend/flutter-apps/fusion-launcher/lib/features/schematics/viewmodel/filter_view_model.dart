import 'dart:async';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/models/project_entities/equip_location.dart';
import 'package:fusion_lib/models/project_entities/floor_model.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../state/filter_state.dart';

class FilterViewModel extends Cubit<FilterViewModelState> {
  FilterViewModel() : super(const FilterViewModelState());

  // ── TextEditingController management ──────────────────────────────────────

  final Map<String, TextEditingController> _floorControllers = <String, TextEditingController>{};
  final Map<String, TextEditingController> _areaControllers = <String, TextEditingController>{};
  final Map<String, TextEditingController> _locationControllers = <String, TextEditingController>{};

  Map<String, TextEditingController> get floorControllers => _floorControllers;
  Map<String, TextEditingController> get areaControllers => _areaControllers;
  Map<String, TextEditingController> get locationControllers => _locationControllers;

  TextEditingController getOrCreateFloorController(String id, String initialText) =>
      _floorControllers.putIfAbsent(id, () => TextEditingController(text: initialText));

  TextEditingController getOrCreateAreaController(String id, String initialText) =>
      _areaControllers.putIfAbsent(id, () => TextEditingController(text: initialText));

  TextEditingController getOrCreateLocationController(String id, String initialText) =>
      _locationControllers.putIfAbsent(id, () => TextEditingController(text: initialText));

  void cleanupFloorController(String id) {
    _floorControllers[id]?.dispose();
    _floorControllers.remove(id);
  }

  void cleanupAreaController(String id) {
    _areaControllers[id]?.dispose();
    _areaControllers.remove(id);
  }

  void cleanupLocationController(String id) {
    _locationControllers[id]?.dispose();
    _locationControllers.remove(id);
  }

  // ── Filter mode ───────────────────────────────────────────────────────────

  void toggleFilterMode() => emit(state.copyWith(filterMode: !state.filterMode));

  void exitFilterMode() => emit(
    state.copyWith(
      filterMode: false,
      floorChecked: const <String, bool>{},
      areaChecked: const <String, bool>{},
      zoneChecked: const <String, bool>{},
      subZoneChecked: const <String, bool>{},
      locationChecked: const <String, bool>{},
    ),
  );

  // ── Toggles ───────────────────────────────────────────────────────────────

  void toggleFloorOpen(String id) => emit(state.copyWith(floorOpen: _toggled(state.floorOpen, id)));
  void toggleFloor(String id) => emit(state.copyWith(floorChecked: _toggled(state.floorChecked, id)));
  void toggleArea(String id) => emit(state.copyWith(areaChecked: _toggled(state.areaChecked, id)));
  void toggleZone(String id) => emit(state.copyWith(zoneChecked: _toggled(state.zoneChecked, id)));
  void toggleSubZone(String id) => emit(state.copyWith(subZoneChecked: _toggled(state.subZoneChecked, id)));
  void toggleLocation(String id) => emit(state.copyWith(locationChecked: _toggled(state.locationChecked, id)));

  // ── Edit mode toggles ─────────────────────────────────────────────────────

  void toggleFloorEditMode(String id) => emit(state.copyWith(editingFloors: _toggled(state.editingFloors, id)));
  void toggleAreaEditMode(String id) => emit(state.copyWith(editingAreas: _toggled(state.editingAreas, id)));
  void toggleLocationEditMode(String id) => emit(state.copyWith(editingLocations: _toggled(state.editingLocations, id)));

  // ── Clear filters ─────────────────────────────────────────────────────────

  void clearAllFilters() => emit(
    state.copyWith(
      floorChecked: const <String, bool>{},
      areaChecked: const <String, bool>{},
      zoneChecked: const <String, bool>{},
      subZoneChecked: const <String, bool>{},
      locationChecked: const <String, bool>{},
    ),
  );

  // ── Private ───────────────────────────────────────────────────────────────

  Map<String, bool> _toggled(Map<String, bool> map, String id) {
    final Map<String, bool> updated = Map<String, bool>.from(map);
    updated[id] = !(updated[id] ?? false);
    return updated;
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    for (final TextEditingController c in _floorControllers.values) c.dispose();
    for (final TextEditingController c in _areaControllers.values) c.dispose();
    for (final TextEditingController c in _locationControllers.values) c.dispose();
    _floorControllers.clear();
    _areaControllers.clear();
    _locationControllers.clear();
    return super.close();
  }

  // ── areAllSelected ────────────────────────────────────────────────────────
  //
  // BUG in original: only checked floors/zones/locations — never areas or
  // subzones. So unchecking a subzone left "Select All" showing as checked,
  // and after selectAll() the checkbox could disagree with actual state.
  //
  // FIX: check all five categories. Guard nested every() with isNotEmpty so
  // vacuous truth on empty child lists doesn't cause false positives.

  bool areAllSelected(
    List<FloorModel> floors,
    List<Zone> zones,
    List<EquipLocation> locations,
  ) {
    // Nothing exists yet → never "all selected"
    if (floors.isEmpty && zones.isEmpty && locations.isEmpty) return false;

    final ProjectViewModel projectVm = serviceLocator<ProjectViewModel>();

    // ── Floors ───────────────────────────────────────────────────────────
    if (!floors.every((FloorModel f) => state.isFloorChecked(f.id))) return false;

    // ── Listening Areas (children of floors) ─────────────────────────────
    // Guard with isNotEmpty: empty list would vacuously pass every() and
    // falsely indicate "all selected" for floors that have no areas yet.
    for (final FloorModel f in floors) {
      final List<ListeningArea> areas = projectVm.getListeningAreasForFloor(floorId: f.id);
      if (areas.isNotEmpty && !areas.every((ListeningArea a) => state.isAreaChecked(a.id))) {
        return false;
      }
    }

    // ── Zones ─────────────────────────────────────────────────────────────
    if (!zones.every((Zone z) => state.isZoneChecked(z.id))) return false;

    // ── SubZones (children of zones) ──────────────────────────────────────
    // Same guard: a zone with no subzones must not block the overall result.
    for (final Zone z in zones) {
      final List<SubZone> subs = projectVm.getSubZonesForZone(parentZoneId: z.id);
      if (subs.isNotEmpty && !subs.every((SubZone s) => state.isSubZoneChecked(s.id))) {
        return false;
      }
    }

    // ── Equipment Locations ───────────────────────────────────────────────
    if (!locations.every((EquipLocation l) => state.isLocationChecked(l.id))) {
      return false;
    }

    return true;
  }

  // ── selectAll ─────────────────────────────────────────────────────────────

  void selectAll({
    required List<FloorModel> floors,
    required List<Zone> zones,
    required List<EquipLocation> locations,
  }) {
    final ProjectViewModel projectVm = serviceLocator<ProjectViewModel>();

    final Map<String, bool> floorChecked = <String, bool>{
      for (final FloorModel f in floors) f.id: true,
    };

    final Map<String, bool> areaChecked = <String, bool>{
      for (final FloorModel f in floors)
        for (final ListeningArea a in projectVm.getListeningAreasForFloor(floorId: f.id)) a.id: true,
    };

    final Map<String, bool> zoneChecked = <String, bool>{
      for (final Zone z in zones) z.id: true,
    };

    final Map<String, bool> subZoneChecked = <String, bool>{
      for (final Zone z in zones)
        for (final SubZone s in projectVm.getSubZonesForZone(parentZoneId: z.id)) s.id: true,
    };

    final Map<String, bool> locationChecked = <String, bool>{
      for (final EquipLocation l in locations) l.id: true,
    };

    emit(
      state.copyWith(
        floorChecked: floorChecked,
        areaChecked: areaChecked,
        zoneChecked: zoneChecked,
        subZoneChecked: subZoneChecked,
        locationChecked: locationChecked,
      ),
    );
  }

  // ── deselectAll ───────────────────────────────────────────────────────────

  void deselectAll() => emit(
    state.copyWith(
      floorChecked: const <String, bool>{},
      areaChecked: const <String, bool>{},
      zoneChecked: const <String, bool>{},
      subZoneChecked: const <String, bool>{},
      locationChecked: const <String, bool>{},
    ),
  );
}
