import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import 'add_controller_state.dart';

/// Cubit for managing Add Controller dialog state
class AddControllerCubit extends Cubit<AddControllerState> {
  final ProjectViewModel projectViewModel;

  AddControllerCubit({required this.projectViewModel}) : super(const AddControllerState());

  /// Update controller name
  void updateName(String name) {
    emit(state.copyWith(name: name));
  }

  /// Update controller type
  void updateControllerType(ControllerType? type) {
    // Reset control zones when controller type changes
    Set<String> controlZones = <String>{};

    // If we have a selected zone and assign control is enabled,
    // auto-select "This Zone" for non-Pro controllers
    if (state.selectedZoneId != null && state.assignControl) {
      controlZones = <String>{state.selectedZoneId!};
    }

    emit(
      state.copyWith(
        controllerType: type,
        selectedControlZoneIds: controlZones,
      ),
    );
  }

  /// Update location type
  void updateLocationType(LocationType? type) {
    // Reset selections when location type changes
    emit(
      state.copyWith(
        locationType: type,
        clearSelectedZoneId: true,
        clearSelectedSubZoneId: true,
        clearSelectedEquipmentLocationId: true,
        selectedControlZoneIds: <String>{},
      ),
    );
  }

  /// Update selected zone and subzone
  void updateSelectedZone(String? zoneId, {String? subZoneId}) {
    Set<String> controlZones = state.selectedControlZoneIds;

    // Determine which ID to use for "This Zone" in control assignment
    final String? newThisZoneId = subZoneId ?? zoneId;
    final String? oldThisZoneId = state.selectedSubZoneId ?? state.selectedZoneId;

    // If assign control is enabled and zone selection changed,
    // update control zones accordingly
    if (newThisZoneId != null && state.assignControl) {
      if (state.controllerType?.supportsMultipleZones == true) {
        // For Pro controllers: replace old "This Zone" with new one, keep other selections
        controlZones = Set<String>.from(controlZones);
        if (oldThisZoneId != null) {
          controlZones.remove(oldThisZoneId);
        }
        controlZones.add(newThisZoneId);
      } else {
        // For LT controllers: only "This Zone" can be selected
        controlZones = <String>{newThisZoneId};
      }
    }

    emit(
      state.copyWith(
        selectedZoneId: zoneId,
        selectedSubZoneId: subZoneId,
        clearSelectedSubZoneId: subZoneId == null,
        selectedControlZoneIds: controlZones,
      ),
    );
  }

  /// Update selected equipment location
  void updateSelectedEquipmentLocation(String? equipLocationId) {
    emit(
      state.copyWith(
        selectedEquipmentLocationId: equipLocationId,
        selectedControlZoneIds: <String>{},
      ),
    );
  }

  /// Toggle assign control
  void toggleAssignControl(bool value) {
    Set<String> controlZones = <String>{};

    // If enabling assign control and we have a selected zone (for zone location),
    // auto-select "This Zone" (the selected zone/subzone)
    if (value && state.locationType == LocationType.zone) {
      final String? thisZoneId = state.selectedSubZoneId ?? state.selectedZoneId;
      if (thisZoneId != null) {
        controlZones = <String>{thisZoneId};
      }
    }

    emit(
      state.copyWith(
        assignControl: value,
        selectedControlZoneIds: controlZones,
      ),
    );
  }

  /// Get "This Zone" ID - the currently selected zone/subzone for location
  String? get thisZoneId => state.selectedSubZoneId ?? state.selectedZoneId;

  /// Check if a zone is "This Zone" (the one selected as location)
  bool isThisZone(String zoneId) {
    return zoneId == thisZoneId;
  }

  /// Check if the controller supports multiple zone selection
  bool get supportsMultipleZones => state.controllerType?.supportsMultipleZones ?? false;

  /// Toggle a zone in control zone selection
  void toggleControlZone(String zoneId) {
    final Set<String> currentSelection = Set<String>.from(state.selectedControlZoneIds);

    if (state.controllerType?.supportsMultipleZones == true) {
      /// Pro controllers: checkbox behavior - toggle the zone
      if (currentSelection.contains(zoneId)) {
        currentSelection.remove(zoneId);
      } else {
        currentSelection.add(zoneId);
      }
    } else {
      /// LT controllers: radio button behavior - single selection only
      /// User can select any zone, "This Zone" is just the default
      currentSelection.clear();
      currentSelection.add(zoneId);
    }

    emit(state.copyWith(selectedControlZoneIds: currentSelection));
  }

  /// Set control zones (used for batch updates like "Save" in zone selection popup)
  void setControlZones(Set<String> zoneIds) {
    emit(state.copyWith(selectedControlZoneIds: zoneIds));
  }

  /// Check if a zone is selected for control
  bool isZoneSelectedForControl(String zoneId) {
    return state.selectedControlZoneIds.contains(zoneId);
  }

  /// Get available zones from project
  List<Zone> get availableZones => projectViewModel.zones;

  /// Get available equipment locations from project
  List<EquipLocation> get availableEquipmentLocations => projectViewModel.equipLocations;

  /// Get subzones for a zone
  List<SubZone> getSubZonesForZone(String zoneId) {
    return projectViewModel.getSubZonesForZone(parentZoneId: zoneId);
  }

  /// Add the controller to the project
  Future<bool> addController() async {
    if (!state.isValid) {
      emit(state.copyWith(errorMessage: 'Please fill in all required fields'));
      return false;
    }

    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      // Create the controller based on type
      final FusionController controller = _createController();

      // Add controller to project
      projectViewModel.addHardware(hardware: controller);

      // If location is zone, associate controller with zone
      if (state.locationType == LocationType.zone && state.selectedZoneId != null) {
        // TODO: Add controller-zone association when API is available
      }

      // If location is equipment location, associate controller
      if (state.locationType == LocationType.equipmentLocation && state.selectedEquipmentLocationId != null) {
        projectViewModel.addHardwareToEquipLocation(
          hardwareId: controller.id,
          equipLocationId: state.selectedEquipmentLocationId!,
        );
      }

      emit(state.copyWith(isLoading: false));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to add controller: $e',
        ),
      );
      return false;
    }
  }

  /// Create a FusionController based on current state
  FusionController _createController() {
    final String assetImagePath = _getAssetImagePath();
    final double price = _getPrice();

    // Set locationEntity based on location type
    LocationModel? locationEntity;
    if (state.locationType == LocationType.zone) {
      // Use subzone ID if selected, otherwise use zone ID
      final String? listeningAreaId = state.selectedSubZoneId ?? state.selectedZoneId;
      locationEntity = LocationModel(listeningAreaId: listeningAreaId);
    }

    return FusionController(
      name: state.name.trim().isEmpty ? 'Untitled Controller' : state.name.trim(),
      assetImagePath: assetImagePath,
      locationEntity: locationEntity,
      price: price,
      sku: state.controllerType?.displayName ?? 'Controller',
      addedFromBuildingPage: false,
    );
  }

  String _getAssetImagePath() {
    switch (state.controllerType) {
      case ControllerType.controlPalLT:
      case ControllerType.virtualControlPalLT:
        return 'assets/images/controllers/control_pal.png';
      case ControllerType.controlPalPro:
      case ControllerType.virtualControlPalPro:
        return 'assets/images/controllers/control_pal_pro.png';
      default:
        return 'assets/images/controllers/control_pal.png';
    }
  }

  double _getPrice() {
    switch (state.controllerType) {
      case ControllerType.controlPalLT:
        return 199.99;
      case ControllerType.controlPalPro:
        return 299.99;
      case ControllerType.virtualControlPalLT:
      case ControllerType.virtualControlPalPro:
        return 0.0; // Virtual controllers are free
      default:
        return 0.0;
    }
  }

  /// Reset the form to initial state
  void reset() {
    emit(const AddControllerState());
  }
}
