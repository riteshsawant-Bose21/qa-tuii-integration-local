import 'dart:math';

import 'package:fusion_lib/models/fusion_models.dart';

import '../../fusion_utils/fusion_utilities.dart';

class SourceSet {
  final String id;
  final String name;
  final bool isLinked;

  SourceSet({
    String? id,
    required this.name,
    this.isLinked = false,
  }) : id = id ?? "SET${FusionUtils.shortStringUUID()}";

  SourceSet copyWith({
    String? id,
    String? name,
    bool? isLinked,
  }) {
    return SourceSet(
      id: id ?? this.id,
      name: name ?? this.name,
      isLinked: isLinked ?? this.isLinked,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'isLinked': isLinked,
  };

  factory SourceSet.fromJson(Map<String, dynamic> json) {
    return SourceSet(
      id: json['id'] as String,
      name: json['name'] as String,
      isLinked: json['isLinked'] as bool,
    );
  }
}
