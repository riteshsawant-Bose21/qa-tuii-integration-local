import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import 'add_controller_state.dart';

/// Cubit for managing Add / Edit Controller dialog state
class AddControllerCubit extends Cubit<AddControllerState> {
  final ProjectViewModel projectViewModel;

  AddControllerCubit({required this.projectViewModel}) : super(const AddControllerAddState());

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
    final String? editControllerId = state.editControllerId;

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

    // In edit mode: immediately persist using batch update
    if (editControllerId != null) {
      projectViewModel.setAssignedZonesForController(
        controllerId: editControllerId,
        zoneIds: controlZones,
        autoSave: true,
      );
    }
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
    final String? editControllerId = state.editControllerId;

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

    // In edit mode: immediately persist using batch update
    if (editControllerId != null) {
      projectViewModel.setAssignedZonesForController(
        controllerId: editControllerId,
        zoneIds: currentSelection,
        autoSave: true,
      );
    }
  }

  /// Set control zones (used for batch updates like "Save" in zone selection popup)
  void setControlZones(Set<String> zoneIds) {
    final String? editControllerId = state.editControllerId;
    emit(state.copyWith(selectedControlZoneIds: zoneIds));

    // In edit mode: immediately persist using batch update
    if (editControllerId != null) {
      projectViewModel.setAssignedZonesForController(
        controllerId: editControllerId,
        zoneIds: zoneIds,
        autoSave: true,
      );
    }
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

  /// Add the controller to the project.
  /// Returns the new controller's ID on success, or `null` on failure.
  Future<String?> addController() async {
    if (!state.isValid) {
      emit(state.copyWith(errorMessage: 'Please fill in all required fields'));
      return null;
    }

    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      // Create the controller based on type
      final FusionController controller = _createController();

      // Add controller to project
      projectViewModel.addHardware(hardware: controller);

      // Persist all zone assignments selected in "Assign Control" using batch update
      if (state.assignControl && state.selectedControlZoneIds.isNotEmpty) {
        projectViewModel.setAssignedZonesForController(
          controllerId: controller.id,
          zoneIds: state.selectedControlZoneIds,
          autoSave: false,
        );
      }

      // If location is equipment location, associate controller
      if (state.locationType == LocationType.equipmentLocation && state.selectedEquipmentLocationId != null) {
        projectViewModel.addHardwareToEquipLocation(
          hardwareId: controller.id,
          equipLocationId: state.selectedEquipmentLocationId!,
        );
      }

      emit(state.copyWith(isLoading: false));
      return controller.id;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to add controller: $e',
        ),
      );
      return null;
    }
  }

  /// Create a FusionController based on current state
  FusionController _createController() {
    final String assetImagePath = _getAssetImagePath();
    final double price = _getPrice();

    // Set locationEntity based on location type
    LocationModel? locationEntity;
    if (state.locationType == LocationType.zone) {
      // Get listening area for the zone/subzone
      String? listeningAreaId;

      if (state.selectedSubZoneId != null) {
        // Get listening areas for subzone
        final List<ListeningArea> subZoneAreas = projectViewModel.getListeningAreasInSubZone(subZoneId: state.selectedSubZoneId!);
        if (subZoneAreas.isNotEmpty) {
          listeningAreaId = subZoneAreas.first.id;
        }
      } else if (state.selectedZoneId != null) {
        // Get listening areas for zone
        final List<ListeningArea> zoneAreas = projectViewModel.getListeningAreasForZone(zoneId: state.selectedZoneId!);
        if (zoneAreas.isNotEmpty) {
          listeningAreaId = zoneAreas.first.id;
        }
      }

      if (listeningAreaId != null) {
        locationEntity = LocationModel(listeningAreaId: listeningAreaId);
      }
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

  /// Reset the form to initial add-mode state
  void reset() {
    emit(const AddControllerAddState());
  }

  /// Pre-populate the form state from an existing [FusionController] for editing.
  void initForEdit(FusionController controller) {
    // Map sku back to ControllerType
    ControllerType? controllerType;
    for (final ControllerType t in ControllerType.values) {
      if (t.displayName == controller.sku) {
        controllerType = t;
        break;
      }
    }

    // Determine location type and IDs
    LocationType? locationType;
    String? selectedZoneId;
    String? selectedSubZoneId;
    String? selectedEquipmentLocationId;

    if (controller.locationEntity.listeningAreaId != null) {
      locationType = LocationType.zone;
      final String areaId = controller.locationEntity.listeningAreaId!;

      final Zone? zone = projectViewModel.getZonesForListeningArea(areaId: areaId);
      if (zone != null) {
        selectedZoneId = zone.id;
      } else {
        final SubZone? subZone = projectViewModel.getSubZoneForListeningArea(areaId: areaId);
        if (subZone != null) {
          selectedSubZoneId = subZone.id;
          final Zone? parentZone = projectViewModel.getZoneForSubZone(subZoneId: subZone.id);
          if (parentZone != null) selectedZoneId = parentZone.id;
        }
      }
    } else {
      final EquipLocation? equipLocation = projectViewModel.getEquipLocationForHardware(hardwareId: controller.id);
      if (equipLocation != null) {
        locationType = LocationType.equipmentLocation;
        selectedEquipmentLocationId = equipLocation.id;
      }
    }

    // Determine assigned control zones
    final Set<String> assignedZoneIds = projectViewModel.getAssignedZoneIds(controller.id);
    final bool assignControl = assignedZoneIds.isNotEmpty;

    emit(
      AddControllerEditState(
        editControllerId: controller.id,
        name: controller.name,
        controllerType: controllerType,
        locationType: locationType,
        selectedZoneId: selectedZoneId,
        selectedSubZoneId: selectedSubZoneId,
        selectedEquipmentLocationId: selectedEquipmentLocationId,
        assignControl: assignControl,
        selectedControlZoneIds: assignedZoneIds,
      ),
    );
  }

  /// Update the existing controller in the project.
  /// Returns the controller's ID on success, or `null` on failure.
  Future<String?> updateController() async {
    if (!state.isValid) {
      emit(state.copyWith(errorMessage: 'Please fill in all required fields'));
      return null;
    }

    final String? controllerId = state.editControllerId;
    if (controllerId == null) return null;

    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final FusionController? existing = projectViewModel.getControllerById(controllerId);
      if (existing == null) {
        emit(state.copyWith(isLoading: false, errorMessage: 'Controller not found'));
        return null;
      }

      final String assetImagePath = _getAssetImagePath();
      final double price = _getPrice();

      // Resolve new locationEntity
      LocationModel locationEntity = LocationModel();
      if (state.locationType == LocationType.zone) {
        String? listeningAreaId;
        if (state.selectedSubZoneId != null) {
          final List<ListeningArea> subZoneAreas = projectViewModel.getListeningAreasInSubZone(subZoneId: state.selectedSubZoneId!);
          if (subZoneAreas.isNotEmpty) listeningAreaId = subZoneAreas.first.id;
        } else if (state.selectedZoneId != null) {
          final List<ListeningArea> zoneAreas = projectViewModel.getListeningAreasForZone(zoneId: state.selectedZoneId!);
          if (zoneAreas.isNotEmpty) listeningAreaId = zoneAreas.first.id;
        }
        if (listeningAreaId != null) {
          locationEntity = LocationModel(listeningAreaId: listeningAreaId);
        }
      }

      final FusionController updated = existing.copyWith(
        name: state.name.trim().isEmpty ? 'Untitled Controller' : state.name.trim(),
        assetImagePath: assetImagePath,
        locationEntity: locationEntity,
        price: price,
        sku: state.controllerType?.displayName ?? 'Controller',
      );

      projectViewModel.updateHardware(hardware: updated);

      // Update assigned control zones using batch update (single operation)
      if (state.assignControl && state.selectedControlZoneIds.isNotEmpty) {
        projectViewModel.setAssignedZonesForController(
          controllerId: controllerId,
          zoneIds: state.selectedControlZoneIds,
          autoSave: false,
        );
      } else {
        // Clear all zone assignments if assign control is disabled
        projectViewModel.setAssignedZonesForController(
          controllerId: controllerId,
          zoneIds: <String>{},
          autoSave: false,
        );
      }

      // Update equipment location association
      if (state.locationType == LocationType.equipmentLocation && state.selectedEquipmentLocationId != null) {
        projectViewModel.addHardwareToEquipLocation(
          hardwareId: controllerId,
          equipLocationId: state.selectedEquipmentLocationId!,
        );
      } else {
        // If location is now zone-based, remove from any equipment location
        final EquipLocation? currentEquipLoc = projectViewModel.getEquipLocationForHardware(hardwareId: controllerId);
        if (currentEquipLoc != null) {
          projectViewModel.removeHardwareFromEquipLocation(
            hardwareId: controllerId,
            equipLocationId: currentEquipLoc.id,
            autoSave: false,
          );
        }
      }

      emit(state.copyWith(isLoading: false));
      return controllerId;
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to update controller: $e'));
      return null;
    }
  }
}
