
part of 'controller_zone_view_model.dart';

@immutable
sealed class VirtualControllerState {}

final class ZonesInitial extends VirtualControllerState {}

final class ZonesLoaded extends VirtualControllerState {
  final List<WallZone> zones;

  ZonesLoaded({
    required this.zones,
  });

  ZonesLoaded copyWith({
    List<WallZone>? zones,
    int? currentZoneIndex,
    int? currentSourceIndex,
  }) {
    return ZonesLoaded(
      zones: zones ?? this.zones
    );
  }
}

final class GainUpdated extends VirtualControllerState {
  final WallSubZone zoneSourceModel;

  GainUpdated({
    required this.zoneSourceModel,
  });

  GainUpdated copyWith({
    WallSubZone? zoneSourceModel,
  }) {
    return GainUpdated(
        zoneSourceModel: zoneSourceModel ?? this.zoneSourceModel
    );
  }
}

final class SourceSelected extends VirtualControllerState {
  final WallZoneSource source;

  SourceSelected({
    required this.source,
  });

  SourceSelected copyWith({
    WallZoneSource? source,
  }) {
    return SourceSelected(
        source: source ?? this.source
    );
  }
}

final class ZoneSelected extends VirtualControllerState {
  final WallZone zone;
  final int currentSourceIndex;
  final int zoneIndex;
  final int currentSubzoneIndex;

  ZoneSelected({
    required this.zone,
    required this.zoneIndex,
    required this.currentSourceIndex,
    required this.currentSubzoneIndex,
  });

  ZoneSelected copyWith({
    WallZone? zone,
    int? zoneIndex,
    int? currentSubzoneIndex,
    int? currentSourceIndex,
  }) {
    return ZoneSelected(
      zone: zone ?? this.zone,
      zoneIndex: zoneIndex ?? this.zoneIndex,
      currentSubzoneIndex: currentSubzoneIndex ?? this.currentSubzoneIndex,
      currentSourceIndex: currentSourceIndex ?? this.currentSourceIndex,
    );
  }
}