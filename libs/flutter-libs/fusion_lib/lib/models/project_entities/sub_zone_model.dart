import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

class SubZone {
  final String id;
  final String name;
  final Offset? wiringPos;

  SubZone({
    String? id,
    required this.name,
    this.wiringPos,
  }) : id = id ?? "SUBZONE${FusionUtils.shortStringUUID()}";

  SubZone copyWith({
    String? id,
    String? name,
    Offset? wiringPos,
  }) {
    return SubZone(
      id: id ?? this.id,
      name: name ?? this.name,
      wiringPos: wiringPos ?? this.wiringPos,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
  };

  factory SubZone.fromJson(Map<String, dynamic> json) => SubZone(
    id: json['id'] as String,
    name: json['name'] as String,
    wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['dx'] as num).toDouble(), (json['wiringPos']['dy'] as num).toDouble()) : null,
  );
}
