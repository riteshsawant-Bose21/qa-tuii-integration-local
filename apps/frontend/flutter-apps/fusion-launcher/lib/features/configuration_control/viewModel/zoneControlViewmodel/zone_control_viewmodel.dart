import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'zone_control_state.dart';

/// ViewModel/Cubit for the Zone Control tab panel.
///
/// Manages zone and sub-zone selections for a controller.
/// Loads and persists data using [ProjectViewModel] relationships.
class ZoneControlViewModel extends Cubit<ZoneControlState> {
  late final StreamSubscription<ProjectViewModelState> _projectSubscription;

  ZoneControlViewModel() : super(const ZoneControlInitial()) {
    // Re-sync zone assignments whenever project data changes externally
    // (e.g. zone assignments edited via the edit controller dialog).
    _projectSubscription = _projectViewModel.stream.listen((_) {
      if (_loaded != null) refresh();
    });
  }

  @override
  Future<void> close() {
    _projectSubscription.cancel();
    return super.close();
  }

  /// Lazy reference to ProjectViewModel.
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  /// Get current loaded state, or null if not loaded.
  ZoneControlLoaded? get _loaded {
    final ZoneControlState s = state;
    return s is ZoneControlLoaded ? s : null;
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  /// Loads zone data for the specified controller.
  void loadData(String controllerId, {required bool isProController}) {
    emit(const ZoneControlLoading());

    try {
      // Load zones and sub-zones
      final List<Zone> zones = _projectViewModel.zones;
      final Map<String, List<SubZone>> subZonesInZones = <String, List<SubZone>>{
        for (final Zone zone in zones) zone.id: _projectViewModel.getSubZonesForZone(parentZoneId: zone.id),
      };

      // Load assigned zones from relationship
      final Set<String> assignedZoneIds = _projectViewModel.getAssignedZoneIds(controllerId);
      final Set<String> allSubZoneIds = _projectViewModel.subZones.map((SubZone s) => s.id).toSet();

      final Set<String> selectedZoneIds = <String>{};
      final Set<String> selectedSubZoneIds = <String>{};

      for (final String id in assignedZoneIds) {
        if (allSubZoneIds.contains(id)) {
          selectedSubZoneIds.add(id);
        } else {
          selectedZoneIds.add(id);
        }
      }

      emit(
        ZoneControlLoaded(
          zones: zones,
          subZonesInZones: subZonesInZones,
          selectedZoneIds: selectedZoneIds,
          selectedZoneId: selectedZoneIds.isNotEmpty ? selectedZoneIds.first : null,
          selectedSubZoneIds: selectedSubZoneIds,
          activeSubZoneId: selectedSubZoneIds.isNotEmpty ? selectedSubZoneIds.first : null,
          controllerId: controllerId,
          isProController: isProController,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ZoneControlViewModel: failed to load data: $e');
      emit(ZoneControlError(message: 'Failed to load zone data: $e'));
    }
  }

  /// Reloads data from persistence.
  void refresh() {
    final ZoneControlLoaded? loaded = _loaded;
    if (loaded?.controllerId != null) {
      loadData(loaded!.controllerId!, isProController: loaded.isProController);
    }
  }

  // ─── Zone Actions ──────────────────────────────────────────────────────────

  /// Select a zone (for LT: radio behavior; for Pro: just sets active).
  void selectZone(String zoneId) {
    final ZoneControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    if (!loaded.isProController) {
      // LT controllers: radio behavior - clear all and select only this zone
      final Set<String> singleSelection = <String>{zoneId};

      _persistZoneAssignments(
        controllerId: loaded.controllerId!,
        zoneIds: singleSelection,
        subZoneIds: <String>{},
      );

      emit(
        loaded.copyWith(
          selectedZoneId: zoneId,
          activeSubZoneId: null,
          selectedZoneIds: singleSelection,
          selectedSubZoneIds: <String>{},
        ),
      );
    } else {
      // Pro controllers: just set active zone
      emit(loaded.copyWith(selectedZoneId: zoneId, activeSubZoneId: null));
    }
  }

  /// Toggle zone checkbox (Pro controller multi-select).
  void toggleZoneSelection(String zoneId) {
    final ZoneControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final Set<String> updated = Set<String>.from(loaded.selectedZoneIds);
    if (updated.contains(zoneId)) {
      updated.remove(zoneId);
    } else {
      updated.add(zoneId);
    }

    _persistZoneAssignments(
      controllerId: loaded.controllerId!,
      zoneIds: updated,
      subZoneIds: loaded.selectedSubZoneIds,
    );

    emit(loaded.copyWith(selectedZoneIds: updated));
  }

  // ─── Sub-Zone Actions ──────────────────────────────────────────────────────

  /// Select a sub-zone (for LT: radio behavior; for Pro: just sets active).
  void selectSubZone(String subZoneId) {
    final ZoneControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    if (!loaded.isProController) {
      // LT controllers: radio behavior - clear all and select only this sub-zone
      final Set<String> singleSelection = <String>{subZoneId};

      _persistZoneAssignments(
        controllerId: loaded.controllerId!,
        zoneIds: <String>{},
        subZoneIds: singleSelection,
      );

      emit(
        loaded.copyWith(
          activeSubZoneId: subZoneId,
          selectedZoneId: null,
          selectedZoneIds: <String>{},
          selectedSubZoneIds: singleSelection,
        ),
      );
    } else {
      // Pro controllers: just set active sub-zone
      emit(loaded.copyWith(activeSubZoneId: subZoneId, selectedZoneId: null));
    }
  }

  /// Toggle sub-zone checkbox (Pro controller multi-select).
  void toggleSubZoneSelection(String subZoneId) {
    final ZoneControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final Set<String> updated = Set<String>.from(loaded.selectedSubZoneIds);
    if (updated.contains(subZoneId)) {
      updated.remove(subZoneId);
    } else {
      updated.add(subZoneId);
    }

    _persistZoneAssignments(
      controllerId: loaded.controllerId!,
      zoneIds: loaded.selectedZoneIds,
      subZoneIds: updated,
    );

    emit(loaded.copyWith(selectedSubZoneIds: updated));
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

  /// Persists zone assignments for the controller.
  void _persistZoneAssignments({
    required String controllerId,
    required Set<String> zoneIds,
    required Set<String> subZoneIds,
  }) {
    final Set<String> allAssignedIds = <String>{...zoneIds, ...subZoneIds};
    _projectViewModel.setAssignedZonesForController(
      controllerId: controllerId,
      zoneIds: allAssignedIds,
      autoSave: true,
    );
  }
}
