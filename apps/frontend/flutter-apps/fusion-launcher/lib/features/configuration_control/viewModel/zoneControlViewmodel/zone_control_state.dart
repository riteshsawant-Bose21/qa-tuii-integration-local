import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// State for the Zone Control tab panel.
sealed class ZoneControlState extends Equatable {
  const ZoneControlState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet.
class ZoneControlInitial extends ZoneControlState {
  const ZoneControlInitial();
}

/// Loading state - fetching data.
class ZoneControlLoading extends ZoneControlState {
  const ZoneControlLoading();
}

/// Loaded state - zones and sub-zones successfully loaded.
class ZoneControlLoaded extends ZoneControlState {
  /// All zones from the project.
  final List<Zone> zones;

  /// Sub-zones grouped by parent zone ID.
  final Map<String, List<SubZone>> subZonesInZones;

  /// Zone IDs that are assigned/selected.
  final Set<String> selectedZoneIds;

  /// Currently active/focused zone ID.
  final String? selectedZoneId;

  /// Sub-zone IDs that are assigned/selected.
  final Set<String> selectedSubZoneIds;

  /// Currently active/focused sub-zone ID.
  final String? activeSubZoneId;

  /// The controller ID this state belongs to.
  final String? controllerId;

  /// Whether the controller is Pro type (multi-select) or LT (single-select).
  final bool isProController;

  const ZoneControlLoaded({
    required this.zones,
    required this.subZonesInZones,
    this.selectedZoneIds = const <String>{},
    this.selectedZoneId,
    this.selectedSubZoneIds = const <String>{},
    this.activeSubZoneId,
    this.controllerId,
    this.isProController = false,
  });

  /// Get sub-zones for a specific zone.
  List<SubZone> getSubZonesForZone(String zoneId) => subZonesInZones[zoneId] ?? const <SubZone>[];

  /// Check if a zone is selected.
  bool isZoneSelected(String zoneId) => selectedZoneIds.contains(zoneId);

  /// Check if a sub-zone is selected.
  bool isSubZoneSelected(String subZoneId) => selectedSubZoneIds.contains(subZoneId);

  ZoneControlLoaded copyWith({
    List<Zone>? zones,
    Map<String, List<SubZone>>? subZonesInZones,
    Set<String>? selectedZoneIds,
    Object? selectedZoneId = _sentinel,
    Set<String>? selectedSubZoneIds,
    Object? activeSubZoneId = _sentinel,
    Object? controllerId = _sentinel,
    bool? isProController,
  }) {
    return ZoneControlLoaded(
      zones: zones ?? this.zones,
      subZonesInZones: subZonesInZones ?? this.subZonesInZones,
      selectedZoneIds: selectedZoneIds ?? this.selectedZoneIds,
      selectedZoneId: identical(selectedZoneId, _sentinel) ? this.selectedZoneId : selectedZoneId as String?,
      selectedSubZoneIds: selectedSubZoneIds ?? this.selectedSubZoneIds,
      activeSubZoneId: identical(activeSubZoneId, _sentinel) ? this.activeSubZoneId : activeSubZoneId as String?,
      controllerId: identical(controllerId, _sentinel) ? this.controllerId : controllerId as String?,
      isProController: isProController ?? this.isProController,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    zones,
    subZonesInZones,
    selectedZoneIds,
    selectedZoneId,
    selectedSubZoneIds,
    activeSubZoneId,
    controllerId,
    isProController,
  ];
}

/// Error state - failed to load data.
class ZoneControlError extends ZoneControlState {
  final String message;

  const ZoneControlError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}

/// Sentinel for nullable copyWith parameters.
const Object _sentinel = Object();
