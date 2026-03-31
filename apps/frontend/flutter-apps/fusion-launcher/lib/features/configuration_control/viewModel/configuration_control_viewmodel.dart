import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import 'configuration_control_state.dart';

/// ViewModel/Cubit for the Configuration Control feature
class ConfigurationControlViewmodel extends Cubit<ConfigurationControlState> {
  final ProjectViewModel projectViewModel;

  ConfigurationControlViewmodel({
    required this.projectViewModel,
  }) : super(const ConfigControlInitial()) {
    _loadData();
  }

  /// Get location name for a controller (same pattern as device location)
  String getControllerLocation(FusionController controller) {
    if (controller.locationEntity.listeningAreaId != null) {
      final String locationId = controller.locationEntity.listeningAreaId!;

      // Try to get zone by ID directly
      final Zone? zone = projectViewModel.getZone(zoneId: locationId);
      if (zone != null) return zone.name;

      // Try to get subzone by ID
      final SubZone? subZone = projectViewModel.getSubZone(subZoneId: locationId);
      if (subZone != null) {
        final Zone? parentZone = projectViewModel.getZoneForSubZone(subZoneId: subZone.id);
        return parentZone != null ? "${parentZone.name} > ${subZone.name}" : subZone.name;
      }

      // Fallback: Try the listening area lookup methods
      final Zone? zoneFromLA = projectViewModel.getZonesForListeningArea(areaId: locationId);
      if (zoneFromLA != null) return zoneFromLA.name;

      final SubZone? subZoneFromLA = projectViewModel.getSubZoneForListeningArea(areaId: locationId);
      if (subZoneFromLA != null) {
        final Zone? parentZone = projectViewModel.getZoneForSubZone(subZoneId: subZoneFromLA.id);
        return parentZone != null ? "${parentZone.name} > ${subZoneFromLA.name}" : subZoneFromLA.name;
      }
    }

    // Check equipment location
    final EquipLocation? equipLocation = projectViewModel.getEquipLocationForHardware(hardwareId: controller.id);
    return equipLocation?.name ?? '--';
  }

  /// Get zone for a controller (for color display)
  Zone? getZoneForController(FusionController controller) {
    if (controller.locationEntity.listeningAreaId != null) {
      final String locationId = controller.locationEntity.listeningAreaId!;

      // Try to get zone by ID directly
      final Zone? zone = projectViewModel.getZone(zoneId: locationId);
      if (zone != null) return zone;

      // Try to get subzone and return parent zone
      final SubZone? subZone = projectViewModel.getSubZone(subZoneId: locationId);
      if (subZone != null) {
        return projectViewModel.getZoneForSubZone(subZoneId: subZone.id);
      }

      // Fallback: Try the listening area lookup methods
      final Zone? zoneFromLA = projectViewModel.getZonesForListeningArea(areaId: locationId);
      if (zoneFromLA != null) return zoneFromLA;

      final SubZone? subZoneFromLA = projectViewModel.getSubZoneForListeningArea(areaId: locationId);
      if (subZoneFromLA != null) {
        return projectViewModel.getZoneForSubZone(subZoneId: subZoneFromLA.id);
      }
    }
    return null;
  }

  /// Load controllers and zones data
  void _loadData() {
    emit(const ConfigControlLoading());

    try {
      final List<FusionController> controllers = projectViewModel.fusionControllers;
      final List<Zone> zones = projectViewModel.zones;
      final List<SubZone> subZones = projectViewModel.subZones;

      // If no controllers, emit empty state
      if (controllers.isEmpty) {
        emit(const ConfigControlEmpty());
        return;
      }

      // Build subzones map for each zone
      final Map<String, List<SubZone>> subZonesInZones = _buildSubZonesMap(zones, subZones);

      // Select first controller by default
      final String? selectedControllerId = controllers.isNotEmpty ? controllers.first.id : null;

      emit(
        ConfigControlLoaded(
          controllers: controllers,
          zones: zones,
          subZonesInZones: subZonesInZones,
          selectedControllerId: selectedControllerId,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Failed to load configuration control data: $e');
      emit(ConfigControlError(message: 'Failed to load data: $e'));
    }
  }

  /// Build a map of zone IDs to their subzones
  Map<String, List<SubZone>> _buildSubZonesMap(List<Zone> zones, List<SubZone> allSubZones) {
    final Map<String, List<SubZone>> result = <String, List<SubZone>>{};

    for (final Zone zone in zones) {
      final List<SubZone> subZonesForZone = projectViewModel.getSubZonesForZone(parentZoneId: zone.id);
      result[zone.id] = subZonesForZone;
    }

    return result;
  }

  /// Refresh data from project view model
  void refresh() {
    _loadData();
  }

  /// Sync with project view model (called when project is updated externally)
  void syncWithProjectViewModel() {
    if (state is! ConfigControlLoaded) {
      _loadData();
      return;
    }

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    final List<FusionController> controllers = projectViewModel.fusionControllers;
    final List<Zone> zones = projectViewModel.zones;
    final List<SubZone> subZones = projectViewModel.subZones;

    if (controllers.isEmpty) {
      emit(const ConfigControlEmpty());
      return;
    }

    final Map<String, List<SubZone>> subZonesInZones = _buildSubZonesMap(zones, subZones);

    // Maintain current selection if still valid
    String? selectedControllerId = currentState.selectedControllerId;
    if (selectedControllerId != null && !controllers.any((FusionController c) => c.id == selectedControllerId)) {
      selectedControllerId = controllers.isNotEmpty ? controllers.first.id : null;
    }

    emit(
      currentState.copyWith(
        controllers: controllers,
        zones: zones,
        subZonesInZones: subZonesInZones,
        selectedControllerId: selectedControllerId,
      ),
    );
  }

  /// Select a controller
  void selectController(String controllerId) {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    emit(currentState.copyWith(selectedControllerId: controllerId));
  }

  /// Select a zone
  void selectZone(String zoneId) {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    emit(currentState.copyWith(selectedZoneId: zoneId));
  }

  /// Toggle zone selection (checkbox)
  void toggleZoneSelection(String zoneId) {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    final Set<String> updatedSelection = Set<String>.from(currentState.selectedZoneIds);

    if (updatedSelection.contains(zoneId)) {
      updatedSelection.remove(zoneId);
    } else {
      updatedSelection.add(zoneId);
    }

    emit(currentState.copyWith(selectedZoneIds: updatedSelection));
  }

  /// Check if a zone is selected
  bool isZoneSelected(String zoneId) {
    if (state is! ConfigControlLoaded) return false;
    return (state as ConfigControlLoaded).selectedZoneIds.contains(zoneId);
  }

  /// Change the current tab
  void changeTab(ConfigControlTab tab) {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    emit(currentState.copyWith(currentTab: tab));
  }

  /// Update search query
  void updateSearchQuery(String query) {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    emit(currentState.copyWith(searchQuery: query));
  }

  /// Clear search query
  void clearSearch() {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    emit(currentState.copyWith(searchQuery: ''));
  }

  /// Add a new controller to the project
  void addController(FusionController controller) {
    projectViewModel.addHardware(hardware: controller);
    refresh();
  }

  /// Delete a controller from the project
  void deleteController(String controllerId) {
    projectViewModel.removeHardware(hardwareId: controllerId);

    if (state is ConfigControlLoaded) {
      final ConfigControlLoaded currentState = state as ConfigControlLoaded;
      if (currentState.selectedControllerId == controllerId) {
        final List<FusionController> remainingControllers = currentState.controllers.where((FusionController c) => c.id != controllerId).toList();

        if (remainingControllers.isEmpty) {
          emit(const ConfigControlEmpty());
        } else {
          emit(
            currentState.copyWith(
              controllers: remainingControllers,
              selectedControllerId: remainingControllers.first.id,
            ),
          );
        }
      }
    }

    refresh();
  }

  /// Get zones for a specific controller
  List<Zone> getZonesForController(String controllerId) {
    if (state is! ConfigControlLoaded) return <Zone>[];
    return (state as ConfigControlLoaded).zones;
  }

  /// Get subzones for a specific zone
  List<SubZone> getSubZonesForZone(String zoneId) {
    if (state is! ConfigControlLoaded) return <SubZone>[];
    return (state as ConfigControlLoaded).subZonesInZones[zoneId] ?? <SubZone>[];
  }
}
