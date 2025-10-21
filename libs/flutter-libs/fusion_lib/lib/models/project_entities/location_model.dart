import 'package:fusion_lib/fusion_lib.dart';

class LocationModel {
  String id;
  String? listeningAreaId;
  String? floorId;

  LocationModel({
    this.listeningAreaId,
    this.floorId,
    String? id,
  }) : id = id ?? "LOCATION${FusionUtils.shortStringUUID()}";

  LocationModel copyWith({String? listeningAreaId, String? floorId, String? circuitId}) {
    return LocationModel(
      listeningAreaId: listeningAreaId == "" ? null : (listeningAreaId ?? this.listeningAreaId),
      floorId: floorId == "" ? null : (floorId ?? this.floorId),
    );
  }

  //clear floor and listening area
  LocationModel clearFloorAndListeningArea() {
    return LocationModel(
      listeningAreaId: null,
      floorId: null,
    );
  }

  //clear floor and listening area
  LocationModel clearListeningArea() {
    return LocationModel(
      listeningAreaId: null,
      floorId: floorId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationModel) return false;
    return listeningAreaId == other.listeningAreaId && floorId == other.floorId;
  }

  @override
  int get hashCode => listeningAreaId.hashCode ^ floorId.hashCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'listeningAreaId': listeningAreaId, 'floorId': floorId};
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      listeningAreaId: json['listeningAreaId'] as String?,
      floorId: json['floorId'] as String?,
    );
  }
}
