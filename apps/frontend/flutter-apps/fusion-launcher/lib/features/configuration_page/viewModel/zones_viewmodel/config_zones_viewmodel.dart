import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_page/viewModel/zones_viewmodel/config_zones_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Cubit for managing Zones feature state and business logic
class ConfigZonesViewmodel extends Cubit<ConfigZonesState> {
  final ProjectViewModel _projectViewModel;

  ConfigZonesViewmodel({
    required ProjectViewModel projectViewModel,
  }) : _projectViewModel = projectViewModel,
       super(const ZonesInitial()) {
    _loadZones();
  }

  /// Load zones from ProjectViewModel
  void _loadZones() {
    try {
      final List<Zone> zones = _projectViewModel.zones;
      final Map<String, List<SubZone>> subZonesMap = _buildSubZonesMap(zones);
      emit(
        ZonesLoaded(
          zones: zones,
          subZonesInZones: subZonesMap,
        ),
      );
    } catch (e) {
      emit(ZonesError(message: e.toString()));
    }
  }

  /// Build sub-zones map for all zones
  Map<String, List<SubZone>> _buildSubZonesMap(List<Zone> zones) {
    final Map<String, List<SubZone>> subZonesMap = <String, List<SubZone>>{};
    for (final Zone zone in zones) {
      subZonesMap[zone.id] = _projectViewModel.getSubZonesForZone(parentZoneId: zone.id);
    }
    return subZonesMap;
  }

  /// Sync state with ProjectViewModel
  void syncWithProjectViewModel() {
    final ConfigZonesState currentState = state;

    try {
      final List<Zone> zones = _projectViewModel.zones;
      final Map<String, List<SubZone>> subZonesMap = _buildSubZonesMap(zones);

      if (currentState is ZonesLoaded) {
        emit(
          currentState.copyWith(
            zones: zones,
            subZonesInZones: subZonesMap,
          ),
        );
      } else {
        emit(
          ZonesLoaded(
            zones: zones,
            subZonesInZones: subZonesMap,
          ),
        );
      }
    } catch (e) {
      emit(ZonesError(message: e.toString()));
    }
  }

  /// Refresh data from ProjectViewModel
  void refresh() => syncWithProjectViewModel();

  /// ==================== Zone Operations ====================

  /// Reorder zones
  void reorderZones(int oldIndex, int newIndex) {
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final List<Zone> zones = state.zones;
    if (oldIndex >= 0 && oldIndex < zones.length && adjustedNewIndex >= 0 && adjustedNewIndex < zones.length) {
      final String zoneToMove = zones[oldIndex].id;
      final String zoneAtNewIndex = zones[adjustedNewIndex].id;
      _projectViewModel.reorderZones(
        zoneIdToMove: zoneToMove,
        zoneIdAtNewIndex: zoneAtNewIndex,
      );
      _projectViewModel.setSelectedDevice(
        zoneToMove,
        SelectedItemType.zone,
      );
      syncWithProjectViewModel();
    }
  }

  /// Get sub-zones for a zone
  List<SubZone> getSubZonesForZone({required String parentZoneId}) {
    return _projectViewModel.getSubZonesForZone(parentZoneId: parentZoneId);
  }

  /// Get zone by ID
  Zone? getZoneById(String zoneId) {
    try {
      return state.zones.firstWhere((Zone zone) => zone.id == zoneId);
    } catch (_) {
      return null;
    }
  }

  /// Get zone index by ID
  int getZoneIndex(String zoneId) {
    return state.zones.indexWhere((Zone zone) => zone.id == zoneId);
  }

  /// ==================== Zone Source Operations ====================

  /// Get priority sources in zone
  List<String> getPrioritySourcesInZone({required String zoneId}) {
    return _projectViewModel.getPrioritySourcesInZone(zoneId: zoneId);
  }

  /// Get hardware by ID
  HardwareComponent? getHardware({required String hardwareId}) {
    return _projectViewModel.getHardware(hardwareId: hardwareId);
  }

  /// Get zone function for zone
  ZoneFunctions? getZoneFunctionForZone({required String zoneId}) {
    return _projectViewModel.getZoneFunctionForZone(zoneId: zoneId);
  }

  /// Remove source from zone
  void removeSourceFromZone({required String zoneId, required String sourceId}) {
    _projectViewModel.removeSourceFromZone(zoneId: zoneId, sourceId: sourceId);
    syncWithProjectViewModel();
  }

  /// Add priority source to zone
  void addPrioritySourceToZone({required String zoneId, required String sourceId, required int priority}) {
    _projectViewModel.addPrioritySourceToZone(zoneId: zoneId, sourceId: sourceId, priority: priority);
    syncWithProjectViewModel();
  }

  /// Remove priority source from zone
  void removePrioritySourceFromZone({required String zoneId, required String sourceId}) {
    _projectViewModel.removePrioritySourceFromZone(zoneId: zoneId, sourceId: sourceId);
    syncWithProjectViewModel();
  }

  /// Add function to zone
  void addFunctionToZone({required String zoneId, required ZoneFunctions function}) {
    _projectViewModel.addFunctionToZone(zoneId: zoneId, function: function);
    syncWithProjectViewModel();
  }

  /// Reorder priority sources in zone
  void reOrderPrioritySourcesInZone({required String zoneId, required List<String> newOrder}) {
    _projectViewModel.reOrderPrioritySourcesInZone(zoneId: zoneId, newOrder: newOrder);
    syncWithProjectViewModel();
  }

  /// Reorder subzone in zone
  void reOrderSubZoneInZone({required String parentId, required int oldIndex, required int newIndex}) {
    _projectViewModel.reOrderSubZoneInZone(parentId: parentId, oldIndex: oldIndex, newIndex: newIndex);
    syncWithProjectViewModel();
  }

  /// Set selected device
  void setSelectedDevice(String id, SelectedItemType type) {
    _projectViewModel.setSelectedDevice(id, type);
  }

  /// Get sources in zone
  List<Source> getSourcesInZone({required String zoneId}) {
    return _projectViewModel.getSourcesInZone(zoneId: zoneId);
  }

  /// Get source sets in zone
  List<SourceSet> getSourceSetsInZone({required String zoneId}) {
    return _projectViewModel.getSourceSetsInZone(zoneId: zoneId);
  }

  /// Update sources in zone
  void updateSourcesInZone({required String zoneId, required List<String> sourceIds}) {
    _projectViewModel.updateSourcesInZone(zoneId: zoneId, sourceIds: sourceIds);
    syncWithProjectViewModel();
  }

  /// Update source sets in zone
  void updateSourceSets({required String zoneId, required List<String> sourceSetIds}) {
    _projectViewModel.updateSourceSets(zoneId: zoneId, sourceSetIds: sourceSetIds);
    syncWithProjectViewModel();
  }

  /// Get source count in zone
  int getSourceCountInZone({required String zoneId}) {
    return _projectViewModel.getSourceCountInZone(zoneId: zoneId);
  }

  /// Get circuits in zone
  List<CircuitModel> getCircuitsInZone(String zoneId) {
    return _projectViewModel.getCircuitsInZone(zoneId);
  }

  /// ==================== SubZone Operations ====================

  /// Get circuits in sub zone
  List<CircuitModel> getCircuitsInSubZone({required String subZoneId}) {
    return _projectViewModel.getCircuitsInSubZone(subZoneId: subZoneId);
  }

  /// Get hardware for circuit
  List<HardwareComponent> getHardwareForCircuit({required String circuitId}) {
    return _projectViewModel.getHardwareForCircuit(circuitId: circuitId);
  }

  /// Get selected device
  SelectedItem? get selectedDevice => _projectViewModel.selectedDevice;
}
