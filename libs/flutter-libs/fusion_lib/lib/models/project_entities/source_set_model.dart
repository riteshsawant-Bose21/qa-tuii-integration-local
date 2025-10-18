import 'dart:math';

import 'package:fusion_lib/models/fusion_models.dart';

import '../../fusion_utils/fusion_utilities.dart';

class SourceSet {
  final String id;
  final String name;
  final List<String> sourceIds;
  final Map<String, double> sourceMixLevels;
  final List<ProcessingBlockModel> processingBlocks;

  SourceSet({String? id, required this.name, List<String>? sourceIds, Map<String, double>? sourceMixLevels, List<ProcessingBlockModel>? processingBlocks})
    : id = id ?? "SET${FusionUtils.shortStringUUID()}",
      processingBlocks = processingBlocks ?? <ProcessingBlockModel>[],
      sourceMixLevels = sourceMixLevels ?? <String, double>{},
      sourceIds = sourceIds ?? <String>[];

  SourceSet copyWith({String? id, String? name, List<String>? sourceIds, Map<String, double>? sourceMixLevels, List<ProcessingBlockModel>? processingBlocks}) {
    return SourceSet(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceIds: sourceIds ?? this.sourceIds,
      sourceMixLevels: sourceMixLevels ?? this.sourceMixLevels,
      processingBlocks: processingBlocks ?? this.processingBlocks,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'sourceIds': sourceIds,
    'sourceMixLevels': sourceMixLevels.map((String key, double value) => MapEntry<String, dynamic>(key, value)),
    'processingBlocks': processingBlocks.map((ProcessingBlockModel pb) => pb.toJson()).toList(),
  };

  factory SourceSet.fromJson(Map<String, dynamic> json) {
    print("Mix.fromJson: $json");
    return SourceSet(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceIds: (json['sourceIds'] as List<dynamic>?)?.map((dynamic e) => e as String).toList() ?? <String>[],
      sourceMixLevels:
          (json['sourceMixLevels'] as Map<String, dynamic>?)?.map((String key, dynamic value) => MapEntry<String, double>(key, (value as num).toDouble())) ??
          <String, double>{},
      processingBlocks:
          (json['processingBlocks'] as List<dynamic>?)?.map((dynamic e) => ProcessingBlockModel.fromJson(e as Map<String, dynamic>)).toList() ??
          <ProcessingBlockModel>[],
    );
  }
}
