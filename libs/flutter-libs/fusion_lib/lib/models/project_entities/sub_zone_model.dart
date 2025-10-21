import 'package:fusion_lib/fusion_lib.dart';

class SubZone {
  final String id;
  final String name;

  SubZone({
    String? id,
    required this.name,
  }) : id = id ?? "SUBZONE${FusionUtils.shortStringUUID()}";

  SubZone copyWith({
    String? id,
    String? name,
  }) {
    return SubZone(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
  };

  factory SubZone.fromJson(Map<String, dynamic> json) => SubZone(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}
