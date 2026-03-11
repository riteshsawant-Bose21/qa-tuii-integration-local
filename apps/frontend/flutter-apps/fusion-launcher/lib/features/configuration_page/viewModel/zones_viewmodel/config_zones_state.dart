import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Base state class for the Zones feature
sealed class ConfigZonesState extends Equatable {
  const ConfigZonesState();

  /// Get zones list (empty for non-loaded states)
  List<Zone> get zones => <Zone>[];

  /// Get sub-zones map for each zone (empty for non-loaded states)
  Map<String, List<SubZone>> get subZonesInZones => <String, List<SubZone>>{};

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet
class ZonesInitial extends ConfigZonesState {
  const ZonesInitial();
}

/// Loading state - fetching zones
class ZonesLoading extends ConfigZonesState {
  const ZonesLoading();
}

/// Loaded state - zones successfully loaded
class ZonesLoaded extends ConfigZonesState {
  @override
  final List<Zone> zones;

  @override
  final Map<String, List<SubZone>> subZonesInZones;

  const ZonesLoaded({
    required this.zones,
    this.subZonesInZones = const <String, List<SubZone>>{},
  });

  /// Create a copy with updated values
  ZonesLoaded copyWith({
    List<Zone>? zones,
    Map<String, List<SubZone>>? subZonesInZones,
  }) {
    return ZonesLoaded(
      zones: zones ?? this.zones,
      subZonesInZones: subZonesInZones ?? this.subZonesInZones,
    );
  }

  @override
  List<Object?> get props => <Object?>[zones, subZonesInZones];
}

/// Error state - failed to load zones
class ZonesError extends ConfigZonesState {
  final String message;

  const ZonesError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
