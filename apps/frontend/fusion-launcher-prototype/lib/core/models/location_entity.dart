import 'package:uuid/uuid.dart';

class LocationEntity {
  String id;
  String? listeningAreaId;
  String? floorId;
  String? zoneId;

  LocationEntity({
    this.listeningAreaId,
    this.floorId,
    this.zoneId,
    String? id,
  }) : id = id ?? const Uuid().v4();

  LocationEntity copyWith({
    String? listeningAreaId,
    String? floorId,
    String? zoneId,
  }) {
    return LocationEntity(
      listeningAreaId: listeningAreaId == "" ? null : (listeningAreaId ?? this.listeningAreaId),
      floorId: floorId == "" ? null : (floorId ?? this.floorId),
      zoneId: zoneId == "" ? null : (zoneId ?? this.zoneId),
    );
  }

  //clear floor and listening area
  LocationEntity clearFloorAndListeningArea() {
    return LocationEntity(
      listeningAreaId: null,
      floorId: null,
      zoneId: zoneId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationEntity) return false;
    return listeningAreaId == other.listeningAreaId && floorId == other.floorId && zoneId == other.zoneId;
  }

  @override
  int get hashCode => listeningAreaId.hashCode ^ floorId.hashCode ^ zoneId.hashCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'listeningAreaId': listeningAreaId,
      'floorId': floorId,
      'zoneId': zoneId,
    };
  }

  factory LocationEntity.fromJson(Map<String, dynamic> json) {
    return LocationEntity(
      listeningAreaId: json['listeningAreaId'] as String?,
      floorId: json['floorId'] as String?,
      zoneId: json['zoneId'] as String?,
    );
  }
}
