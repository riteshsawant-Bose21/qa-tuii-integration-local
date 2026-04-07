
part of 'controlpal_zone_view_model.dart';

@immutable
sealed class ControlPalZonesState {}

final class ZonesInitial extends ControlPalZonesState {}

final class ZonesLoaded extends ControlPalZonesState {
  final List<ZoneModel> zones;

  ZonesLoaded({
    required this.zones,
  });

  ZonesLoaded copyWith({
    List<ZoneModel>? zones,
    int? currentZoneIndex,
    int? currentSourceIndex,
  }) {
    return ZonesLoaded(
      zones: zones ?? this.zones
    );
  }
}

final class GainUpdated extends ControlPalZonesState {
  final ZoneSourceModel zoneSourceModel;

  GainUpdated({
    required this.zoneSourceModel,
  });

  GainUpdated copyWith({
    ZoneSourceModel? zoneSourceModel,
  }) {
    return GainUpdated(
        zoneSourceModel: zoneSourceModel ?? this.zoneSourceModel
    );
  }
}

final class SourceSelected extends ControlPalZonesState {
  final ZoneSourceModel zoneSourceModel;

  SourceSelected({
    required this.zoneSourceModel,
  });

  SourceSelected copyWith({
    ZoneSourceModel? zoneSourceModel,
  }) {
    return SourceSelected(
        zoneSourceModel: zoneSourceModel ?? this.zoneSourceModel
    );
  }
}

final class ZoneSelected extends ControlPalZonesState {
  final ZoneModel zone;
  final int currentSourceIndex;
  final int zoneIndex;

  ZoneSelected({
    required this.zone,
    required this.zoneIndex,
    required this.currentSourceIndex,
  });

  ZoneSelected copyWith({
    ZoneModel? zone,
    int? zoneIndex,
    int? currentSourceIndex,
  }) {
    return ZoneSelected(
      zone: zone ?? this.zone,
      zoneIndex: zoneIndex ?? this.zoneIndex,
      currentSourceIndex: currentSourceIndex ?? this.currentSourceIndex,
    );
  }
}