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

  bool get supportsMultipleZones => this == ControllerType.controlPalPro || this == ControllerType.virtualControlPalPro;

  bool get isVirtual => this == ControllerType.virtualControlPalLT || this == ControllerType.virtualControlPalPro;
}

/// Enum for location types
enum LocationType {
  zone('Zone'),
  equipmentLocation('Equipment Location');

  const LocationType(this.displayName);
  final String displayName;
}

// ─── Sealed base ───────────────────────────────────────────────────────────────

/// Sealed base for the Add/Edit Controller dialog state.
///
/// All shared form fields live here.  Concrete subtypes are:
/// * [AddControllerAddState]  – dialog opened for a **new** controller.
/// * [AddControllerEditState] – dialog opened to **edit** an existing controller.
sealed class AddControllerState extends Equatable {
  const AddControllerState({
    required this.name,
    required this.controllerType,
    required this.locationType,
    required this.selectedZoneId,
    required this.selectedSubZoneId,
    required this.selectedEquipmentLocationId,
    required this.assignControl,
    required this.selectedControlZoneIds,
    required this.isLoading,
    required this.errorMessage,
  });

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

  // ── Mode discriminators ──────────────────────────────────────────────────

  bool get isEditMode;
  String? get editControllerId;

  // ── Shared validation & helpers ──────────────────────────────────────────

  bool get isValid {
    if (name.trim().isEmpty) return false;
    if (controllerType == null) return false;
    if (locationType == null) return false;
    if (locationType == LocationType.zone && selectedZoneId == null) return false;
    if (locationType == LocationType.equipmentLocation && selectedEquipmentLocationId == null) return false;
    return true;
  }

  String? getSelectedZoneName(List<Zone> zones) {
    if (selectedZoneId == null) return null;
    try {
      return zones.firstWhere((Zone z) => z.id == selectedZoneId).name;
    } catch (_) {
      return null;
    }
  }

  String? getSelectedEquipmentLocationName(List<EquipLocation> equipLocations) {
    if (selectedEquipmentLocationId == null) return null;
    try {
      return equipLocations.firstWhere((EquipLocation e) => e.id == selectedEquipmentLocationId).name;
    } catch (_) {
      return null;
    }
  }

  // ── Abstract copyWith (each subtype returns its own concrete type) ────────

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
  });
}

// ─── Add mode ──────────────────────────────────────────────────────────────────

/// State when the dialog is creating a **new** controller.
final class AddControllerAddState extends AddControllerState {
  const AddControllerAddState({
    super.name = 'Untitled Controller',
    super.controllerType,
    super.locationType,
    super.selectedZoneId,
    super.selectedSubZoneId,
    super.selectedEquipmentLocationId,
    super.assignControl = false,
    super.selectedControlZoneIds = const <String>{},
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  bool get isEditMode => false;

  @override
  String? get editControllerId => null;

  @override
  AddControllerAddState copyWith({
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
    return AddControllerAddState(
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

// ─── Edit mode ─────────────────────────────────────────────────────────────────

/// State when the dialog is editing an **existing** controller.
final class AddControllerEditState extends AddControllerState {
  const AddControllerEditState({
    required this.editControllerId,
    super.name = 'Untitled Controller',
    super.controllerType,
    super.locationType,
    super.selectedZoneId,
    super.selectedSubZoneId,
    super.selectedEquipmentLocationId,
    super.assignControl = false,
    super.selectedControlZoneIds = const <String>{},
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  final String editControllerId;

  @override
  bool get isEditMode => true;

  @override
  AddControllerEditState copyWith({
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
    return AddControllerEditState(
      editControllerId: editControllerId,
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

  @override
  List<Object?> get props => <Object?>[
    editControllerId,
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
