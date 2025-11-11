import 'dart:math';

import 'package:fusion_lib/models/fusion_models.dart';

import '../../fusion_utils/fusion_utilities.dart';

class SourceSet {
  final String id;
  final String name;

  SourceSet({
    String? id,
    required this.name,
    Map<String, double>? sourceMixLevels,
  }) : id = id ?? "SET${FusionUtils.shortStringUUID()}";

  SourceSet copyWith({
    String? id,
    String? name,
    Map<String, double>? sourceMixLevels,
  }) {
    return SourceSet(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
  };

  factory SourceSet.fromJson(Map<String, dynamic> json) {
    return SourceSet(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
