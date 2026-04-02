import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import 'configuration_control_state.dart';

/// ViewModel/Cubit for the Configuration Control feature
class ConfigurationControlViewmodel extends Cubit<ConfigurationControlState> {
  final ProjectViewModel projectViewModel;
  late final StreamSubscription<ProjectViewModelState> _projectViewModelSubscription;

  ConfigurationControlViewmodel({
    required this.projectViewModel,
  }) : super(const ConfigControlInitial()) {
    _loadData();
    // Listen to all ProjectViewModel changes and sync automatically
    _projectViewModelSubscription = projectViewModel.stream.listen((_) {
      syncWithProjectViewModel();
    });
  }

  @override
  Future<void> close() {
    _projectViewModelSubscription.cancel();
    return super.close();
  }

  /// Get location name for a controller (same pattern as device location)
  String getControllerLocation(FusionController controller) {
    if (controller.locationEntity.listeningAreaId != null) {
      final String listeningAreaId = controller.locationEntity.listeningAreaId!;

      // Try to get zone for this listening area
      final Zone? zone = projectViewModel.getZonesForListeningArea(areaId: listeningAreaId);
      if (zone != null) return zone.name;

      // Try to get subzone for this listening area
      final SubZone? subZone = projectViewModel.getSubZoneForListeningArea(areaId: listeningAreaId);
      if (subZone != null) {
        final Zone? parentZone = projectViewModel.getZoneForSubZone(subZoneId: subZone.id);
        return parentZone != null ? "${parentZone.name} > ${subZone.name}" : subZone.name;
      }
    }

    // Check equipment location
    final EquipLocation? equipLocation = projectViewModel.getEquipLocationForHardware(hardwareId: controller.id);
    return equipLocation?.name ?? '--';
  }

  /// Get zone for a controller (for color display)
  Zone? getZoneForController(FusionController controller) {
    if (controller.locationEntity.listeningAreaId != null) {
      final String listeningAreaId = controller.locationEntity.listeningAreaId!;

      // Try to get zone for this listening area
      final Zone? zone = projectViewModel.getZonesForListeningArea(areaId: listeningAreaId);
      if (zone != null) return zone;

      // Try to get subzone and return parent zone
      final SubZone? subZone = projectViewModel.getSubZoneForListeningArea(areaId: listeningAreaId);
      if (subZone != null) {
        return projectViewModel.getZoneForSubZone(subZoneId: subZone.id);
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
      final FusionController firstController = controllers.first;
      final ({Set<String> selectedZoneIds, String? selectedZoneId, Set<String> selectedSubZoneIds, String? activeSubZoneId}) selection =
          _buildZoneSelectionForController(firstController);

      emit(
        ConfigControlLoaded(
          controllers: controllers,
          zones: zones,
          subZonesInZones: subZonesInZones,
          selectedControllerId: firstController.id,
          selectedZoneIds: selection.selectedZoneIds,
          selectedZoneId: selection.selectedZoneId,
          selectedSubZoneIds: selection.selectedSubZoneIds,
          activeSubZoneId: selection.activeSubZoneId,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Failed to load configuration control data: $e');
      emit(ConfigControlError(message: 'Failed to load data: $e'));
    }
  }

  /// Build zone selection state from a controller's assignedZoneIds.
  /// Splits IDs into zone IDs vs subzone IDs by checking all known subzones.
  ({Set<String> selectedZoneIds, String? selectedZoneId, Set<String> selectedSubZoneIds, String? activeSubZoneId}) _buildZoneSelectionForController(
    FusionController controller,
  ) {
    final Set<String> assigned = controller.assignedZoneIds;

    // Collect all known subzone IDs for look-up
    final List<SubZone> allSubZones = projectViewModel.subZones;
    final Set<String> allSubZoneIds = allSubZones.map((SubZone s) => s.id).toSet();

    final Set<String> zoneIds = <String>{};
    final Set<String> subZoneIds = <String>{};

    for (final String id in assigned) {
      if (allSubZoneIds.contains(id)) {
        subZoneIds.add(id);
      } else {
        zoneIds.add(id);
      }
    }

    return (
      selectedZoneIds: zoneIds,
      selectedZoneId: zoneIds.isNotEmpty ? zoneIds.first : null,
      selectedSubZoneIds: subZoneIds,
      activeSubZoneId: subZoneIds.isNotEmpty ? subZoneIds.first : null,
    );
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
      selectedControllerId = controllers.first.id;
    }

    // Rebuild zone selection from the (possibly updated) controller's assignedZoneIds
    final FusionController? selectedController = controllers.where((FusionController c) => c.id == selectedControllerId).firstOrNull;
    final ({Set<String> selectedZoneIds, String? selectedZoneId, Set<String> selectedSubZoneIds, String? activeSubZoneId}) selection =
        selectedController != null
            ? _buildZoneSelectionForController(selectedController)
            : (selectedZoneIds: const <String>{}, selectedZoneId: null, selectedSubZoneIds: const <String>{}, activeSubZoneId: null);

    emit(
      currentState.copyWith(
        controllers: controllers,
        zones: zones,
        subZonesInZones: subZonesInZones,
        selectedControllerId: selectedControllerId,
        selectedZoneIds: selection.selectedZoneIds,
        selectedZoneId: selection.selectedZoneId,
        selectedSubZoneIds: selection.selectedSubZoneIds,
        activeSubZoneId: selection.activeSubZoneId,
      ),
    );
  }

  /// Select a controller — pre-populates zone selections from controller's assignedZoneIds
  void selectController(String controllerId) {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    final FusionController? controller = currentState.controllers.where((FusionController c) => c.id == controllerId).firstOrNull;

    if (controller == null) return;

    final ({Set<String> selectedZoneIds, String? selectedZoneId, Set<String> selectedSubZoneIds, String? activeSubZoneId}) selection =
        _buildZoneSelectionForController(controller);

    emit(
      currentState.copyWith(
        selectedControllerId: controllerId,
        selectedZoneIds: selection.selectedZoneIds,
        selectedZoneId: selection.selectedZoneId,
        selectedSubZoneIds: selection.selectedSubZoneIds,
        activeSubZoneId: selection.activeSubZoneId,
      ),
    );
  }

  /// Select a zone (LT radio — clears any active subzone so only one radio is selected)
  void selectZone(String zoneId) {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    emit(currentState.copyWith(selectedZoneId: zoneId, clearActiveSubZoneId: true));
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

  /// Select a subzone (LT radio — clears any active zone so only one radio is selected)
  void selectSubZone(String subZoneId) {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    emit(currentState.copyWith(activeSubZoneId: subZoneId, clearSelectedZoneId: true));
  }

  /// Toggle subzone selection (checkbox)
  void toggleSubZoneSelection(String subZoneId) {
    if (state is! ConfigControlLoaded) return;

    final ConfigControlLoaded currentState = state as ConfigControlLoaded;
    final Set<String> updatedSelection = Set<String>.from(currentState.selectedSubZoneIds);

    if (updatedSelection.contains(subZoneId)) {
      updatedSelection.remove(subZoneId);
    } else {
      updatedSelection.add(subZoneId);
    }

    emit(currentState.copyWith(selectedSubZoneIds: updatedSelection));
  }

  /// Check if a subzone is selected
  bool isSubZoneSelected(String subZoneId) {
    if (state is! ConfigControlLoaded) return false;
    return (state as ConfigControlLoaded).selectedSubZoneIds.contains(subZoneId);
  }
}
