import 'dart:math';

import 'package:fusion_lib/models/fusion_models.dart';

import '../../fusion_utils/fusion_utilities.dart';

class SourceSet {
  final String id;
  final String name;
  final Map<String, double> sourceMixLevels;

  SourceSet({
    String? id,
    required this.name,
    Map<String, double>? sourceMixLevels,
  }) : id = id ?? "SET${FusionUtils.shortStringUUID()}",
       sourceMixLevels = sourceMixLevels ?? <String, double>{};

  SourceSet copyWith({
    String? id,
    String? name,
    Map<String, double>? sourceMixLevels,
  }) {
    return SourceSet(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceMixLevels: sourceMixLevels ?? this.sourceMixLevels,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'sourceMixLevels': sourceMixLevels.map((String key, double value) => MapEntry<String, dynamic>(key, value)),
  };

  factory SourceSet.fromJson(Map<String, dynamic> json) {
    return SourceSet(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceMixLevels:
          (json['sourceMixLevels'] as Map<String, dynamic>?)?.map((String key, dynamic value) => MapEntry<String, double>(key, (value as num).toDouble())) ??
          <String, double>{},
    );
  }
}
