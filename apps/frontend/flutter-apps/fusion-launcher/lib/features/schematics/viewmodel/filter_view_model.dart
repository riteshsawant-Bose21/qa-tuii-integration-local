import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/filter_state.dart';

class FilterViewModel extends Cubit<FilterViewModelState> {
  FilterViewModel() : super(const FilterViewModelState());

  // ── TextEditingController management ────────────────────────────────────

  final Map<String, TextEditingController> _floorControllers = <String, TextEditingController>{};
  final Map<String, TextEditingController> _areaControllers = <String, TextEditingController>{};
  final Map<String, TextEditingController> _locationControllers = <String, TextEditingController>{};

  // ── Public accessors ───────────────────────────────────────────────────────

  Map<String, TextEditingController> get floorControllers => _floorControllers;
  Map<String, TextEditingController> get areaControllers => _areaControllers;
  Map<String, TextEditingController> get locationControllers => _locationControllers;

  // ── Factory methods ────────────────────────────────────────────────────────

  TextEditingController getOrCreateFloorController(String id, String initialText) {
    return _floorControllers.putIfAbsent(id, () => TextEditingController(text: initialText));
  }

  TextEditingController getOrCreateAreaController(String id, String initialText) {
    return _areaControllers.putIfAbsent(id, () => TextEditingController(text: initialText));
  }

  TextEditingController getOrCreateLocationController(String id, String initialText) {
    return _locationControllers.putIfAbsent(id, () => TextEditingController(text: initialText));
  }

  // ── Cleanup methods ────────────────────────────────────────────────────────

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
  //
  // toggleFilterMode: entering filter mode shows checkboxes; tapping "Done"
  //   exits filter mode but KEEPS checked selections so results stay filtered.
  //
  // exitFilterMode (clearAllFilters + exit): clears all selections and exits.
  //
  // BUG FIX: The original exitFilterMode was also clearing editingFloors /
  // editingAreas / editingLocations. Those maps belong to edit mode (inline
  // rename), not to filter mode. Clearing them on filter exit could silently
  // cancel an in-progress rename if filter mode was toggled mid-edit.
  // They are now left untouched by exitFilterMode.

  void toggleFilterMode() => emit(state.copyWith(filterMode: !state.filterMode));

  void exitFilterMode() => emit(
    state.copyWith(
      filterMode: false,
      floorChecked: const <String, bool>{},
      areaChecked: const <String, bool>{},
      zoneChecked: const <String, bool>{},
      subZoneChecked: const <String, bool>{},
      locationChecked: const <String, bool>{},
      // editingFloors / editingAreas / editingLocations intentionally NOT reset
      // here — they are edit-mode state, not filter state.
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

  // ── Clear all filter selections (without exiting filter mode) ─────────────

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
    for (final TextEditingController c in _floorControllers.values) {
      c.dispose();
    }
    for (final TextEditingController c in _areaControllers.values) {
      c.dispose();
    }
    for (final TextEditingController c in _locationControllers.values) {
      c.dispose();
    }
    _floorControllers.clear();
    _areaControllers.clear();
    _locationControllers.clear();
    return super.close();
  }
}
