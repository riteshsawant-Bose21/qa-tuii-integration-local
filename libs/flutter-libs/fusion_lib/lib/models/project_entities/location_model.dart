import 'package:uuid/uuid.dart';

class LocationModel {
  String id;
  String? listeningAreaId;
  String? floorId;
  String? zoneId;

  LocationModel({this.listeningAreaId, this.floorId, this.zoneId, String? id}) : id = id ?? const Uuid().v4();

  LocationModel copyWith({String? listeningAreaId, String? floorId, String? zoneId}) {
    return LocationModel(
      listeningAreaId: listeningAreaId == "" ? null : (listeningAreaId ?? this.listeningAreaId),
      floorId: floorId == "" ? null : (floorId ?? this.floorId),
      zoneId: zoneId == "" ? null : (zoneId ?? this.zoneId),
    );
  }

  //clear floor and listening area
  LocationModel clearFloorAndListeningArea() {
    return LocationModel(listeningAreaId: null, floorId: null, zoneId: zoneId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationModel) return false;
    return listeningAreaId == other.listeningAreaId && floorId == other.floorId && zoneId == other.zoneId;
  }

  @override
  int get hashCode => listeningAreaId.hashCode ^ floorId.hashCode ^ zoneId.hashCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'listeningAreaId': listeningAreaId, 'floorId': floorId, 'zoneId': zoneId};
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(listeningAreaId: json['listeningAreaId'] as String?, floorId: json['floorId'] as String?, zoneId: json['zoneId'] as String?);
  }
}
