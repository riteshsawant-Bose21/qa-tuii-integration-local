
part of 'controller_zone_view_model.dart';

@immutable
sealed class VirtualControllerState {}

final class VirtualZonesInitial extends VirtualControllerState {}

final class VirtualZonesLoaded extends VirtualControllerState {
  final List<WallZone> zones;

  VirtualZonesLoaded({
    required this.zones,
  });

  VirtualZonesLoaded copyWith({
    List<WallZone>? zones,
    int? currentZoneIndex,
    int? currentSourceIndex,
  }) {
    return VirtualZonesLoaded(
      zones: zones ?? this.zones
    );
  }
}

final class MuteUpdated extends VirtualControllerState {
  final bool isMuted;

  MuteUpdated({
    required this.isMuted,
  });

  MuteUpdated copyWith({
    bool? isMuted,
  }) {
    return MuteUpdated(
        isMuted: isMuted ?? this.isMuted
    );
  }
}

final class GainUpdated extends VirtualControllerState {
  final WallSubZone zoneSourceModel;
  final bool fromServer;

  GainUpdated({
    required this.zoneSourceModel,
    required this.fromServer,
  });

  GainUpdated copyWith({
    WallSubZone? zoneSourceModel,
    bool? fromServer,
  }) {
    return GainUpdated(
        zoneSourceModel: zoneSourceModel ?? this.zoneSourceModel,
        fromServer: fromServer ?? this.fromServer
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

final class VirtualZoneSelected extends VirtualControllerState {
  final WallZone zone;
  final WallSubZone subZone;
  final int currentSourceIndex;
  final int zoneIndex;
  final int currentSubzoneIndex;
  final String gainID;

  VirtualZoneSelected({
    required this.zone,
    required this.subZone,
    required this.zoneIndex,
    required this.currentSourceIndex,
    required this.currentSubzoneIndex,
    required this.gainID,
  });

  VirtualZoneSelected copyWith({
    WallZone? zone,
    WallSubZone? subZone,
    int? zoneIndex,
    int? currentSubzoneIndex,
    int? currentSourceIndex,
    String? gainID,
  }) {
    return VirtualZoneSelected(
      zone: zone ?? this.zone,
      subZone: subZone ?? this.subZone,
      zoneIndex: zoneIndex ?? this.zoneIndex,
      currentSubzoneIndex: currentSubzoneIndex ?? this.currentSubzoneIndex,
      currentSourceIndex: currentSourceIndex ?? this.currentSourceIndex,
      gainID: gainID ?? this.gainID,
    );
  }
}