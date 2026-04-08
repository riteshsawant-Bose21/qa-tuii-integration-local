
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
  final Source source;

  SourceSelected({
    required this.source,
  });

  SourceSelected copyWith({
    Source? source,
  }) {
    return SourceSelected(
        source: source ?? this.source
    );
  }
}

final class ZoneSelected extends ControlPalZonesState {
  final ZoneModel zone;
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
    ZoneModel? zone,
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