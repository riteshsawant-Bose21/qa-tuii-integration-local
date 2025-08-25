import 'dart:math';

import 'package:fusion_lib/models/fusion_models.dart';

class Mix {
  final String id;
  final String name;
  final List<String> sourceIds;
  final Map<String, double> sourceMixLevels;
  final List<ProcessingBlockEntity> processingBlocks;

  Mix({
    String? id,
    required this.name,
    List<String>? sourceIds,
    Map<String, double>? sourceMixLevels,
    List<ProcessingBlockEntity>? processingBlocks,
  }) : id = id ?? getShortId(),
       processingBlocks = processingBlocks ?? <ProcessingBlockEntity>[],
       sourceMixLevels = sourceMixLevels ?? <String, double>{},
       sourceIds = sourceIds ?? <String>[];

  //generate a short unique ID with timestamp
  static String getShortId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}';
  }

  Mix copyWith({
    String? id,
    String? name,
    List<String>? sourceIds,
    Map<String, double>? sourceMixLevels,
    List<ProcessingBlockEntity>? processingBlocks,
  }) {
    return Mix(
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
    'processingBlocks': processingBlocks.map((ProcessingBlockEntity pb) => pb.toJson()).toList(),
  };

  factory Mix.fromJson(Map<String, dynamic> json) {
    print("Mix.fromJson: $json");
    return Mix(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceIds: (json['sourceIds'] as List<dynamic>?)?.map((dynamic e) => e as String).toList() ?? <String>[],
      sourceMixLevels:
          (json['sourceMixLevels'] as Map<String, dynamic>?)?.map((String key, dynamic value) => MapEntry<String, double>(key, (value as num).toDouble())) ??
          <String, double>{},
      processingBlocks:
          (json['processingBlocks'] as List<dynamic>?)?.map((dynamic e) => ProcessingBlockEntity.fromJson(e as Map<String, dynamic>)).toList() ??
          <ProcessingBlockEntity>[],
    );
  }
}
