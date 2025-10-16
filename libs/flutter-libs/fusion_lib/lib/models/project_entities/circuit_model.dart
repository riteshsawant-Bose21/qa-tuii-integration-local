import 'package:fusion_lib/fusion_lib.dart';

class CircuitModel {
  final String id;
  final String name;

  CircuitModel({
    String? id,
    required this.name,
    List<String>? listeningAreaIds,
  }) : id = id ?? FusionUtils.shortStringUUID();

  //copy with
  CircuitModel copyWith({
    String? id,
    String? name,
    String? zoneId,
    List<String>? listeningAreaIds,
  }) {
    return CircuitModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory CircuitModel.fromJson(Map<String, dynamic> json) {
    return CircuitModel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
