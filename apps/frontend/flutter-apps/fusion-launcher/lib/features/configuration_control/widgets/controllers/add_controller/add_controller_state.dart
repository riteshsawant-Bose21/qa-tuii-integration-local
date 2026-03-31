import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Enum for controller types
enum ControllerType {
  controlPalLT('Control Pal LT'),
  controlPalPro('Control Pal Pro'),
  virtualControlPalLT('Virtual Control Pal LT'),
  virtualControlPalPro('Virtual Control Pal Pro');

  const ControllerType(this.displayName);
  final String displayName;

  /// Check if this controller type supports multiple zone selection
  bool get supportsMultipleZones {
    return this == ControllerType.controlPalPro || this == ControllerType.virtualControlPalPro;
  }

  /// Check if this is a virtual controller
  bool get isVirtual {
    return this == ControllerType.virtualControlPalLT || this == ControllerType.virtualControlPalPro;
  }
}

/// Enum for location types
enum LocationType {
  zone('Zone'),
  equipmentLocation('Equipment Location');

  const LocationType(this.displayName);
  final String displayName;
}

/// State for the Add Controller dialog
class AddControllerState extends Equatable {
  final String name;
  final ControllerType? controllerType;
  final LocationType? locationType;
  final String? selectedZoneId;
  final String? selectedSubZoneId;
  final String? selectedEquipmentLocationId;
  final bool assignControl;
  final Set<String> selectedControlZoneIds;
  final bool isLoading;
  final String? errorMessage;

  const AddControllerState({
    this.name = 'Untitled Controller',
    this.controllerType,
    this.locationType,
    this.selectedZoneId,
    this.selectedSubZoneId,
    this.selectedEquipmentLocationId,
    this.assignControl = false,
    this.selectedControlZoneIds = const <String>{},
    this.isLoading = false,
    this.errorMessage,
  });

  AddControllerState copyWith({
    String? name,
    ControllerType? controllerType,
    LocationType? locationType,
    String? selectedZoneId,
    String? selectedSubZoneId,
    String? selectedEquipmentLocationId,
    bool? assignControl,
    Set<String>? selectedControlZoneIds,
    bool? isLoading,
    String? errorMessage,
    bool clearControllerType = false,
    bool clearLocationType = false,
    bool clearSelectedZoneId = false,
    bool clearSelectedSubZoneId = false,
    bool clearSelectedEquipmentLocationId = false,
    bool clearErrorMessage = false,
  }) {
    return AddControllerState(
      name: name ?? this.name,
      controllerType: clearControllerType ? null : (controllerType ?? this.controllerType),
      locationType: clearLocationType ? null : (locationType ?? this.locationType),
      selectedZoneId: clearSelectedZoneId ? null : (selectedZoneId ?? this.selectedZoneId),
      selectedSubZoneId: clearSelectedSubZoneId ? null : (selectedSubZoneId ?? this.selectedSubZoneId),
      selectedEquipmentLocationId: clearSelectedEquipmentLocationId ? null : (selectedEquipmentLocationId ?? this.selectedEquipmentLocationId),
      assignControl: assignControl ?? this.assignControl,
      selectedControlZoneIds: selectedControlZoneIds ?? this.selectedControlZoneIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Check if the form is valid for submission
  bool get isValid {
    if (name.trim().isEmpty) return false;
    if (controllerType == null) return false;
    if (locationType == null) return false;

    if (locationType == LocationType.zone && selectedZoneId == null) return false;
    if (locationType == LocationType.equipmentLocation && selectedEquipmentLocationId == null) return false;

    return true;
  }

  /// Get the display name for the selected zone
  String? getSelectedZoneName(List<Zone> zones) {
    if (selectedZoneId == null) return null;
    try {
      return zones.firstWhere((Zone z) => z.id == selectedZoneId).name;
    } catch (_) {
      return null;
    }
  }

  /// Get the display name for the selected equipment location
  String? getSelectedEquipmentLocationName(List<EquipLocation> equipLocations) {
    if (selectedEquipmentLocationId == null) return null;
    try {
      return equipLocations.firstWhere((EquipLocation e) => e.id == selectedEquipmentLocationId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => <Object?>[
    name,
    controllerType,
    locationType,
    selectedZoneId,
    selectedSubZoneId,
    selectedEquipmentLocationId,
    assignControl,
    selectedControlZoneIds,
    isLoading,
    errorMessage,
  ];
}
