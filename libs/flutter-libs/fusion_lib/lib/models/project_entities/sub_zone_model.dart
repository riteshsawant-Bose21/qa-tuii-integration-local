import 'dart:math';

import 'package:fusion_lib/fusion_lib.dart';

class SubZone {
  final String id;
  final String name;
  final List<ProcessingBlockModel> processingBlocks;

  SubZone({
    String? id,
    required this.name,
    List<ProcessingBlockModel>? processingBlocks,
  }) : id = id ?? "SUBZONE${FusionUtils.shortStringUUID()}",
       processingBlocks = processingBlocks ?? <ProcessingBlockModel>[];

  SubZone copyWith({
    String? id,
    String? name,
    List<ProcessingBlockModel>? processingBlocks,
  }) {
    return SubZone(
      id: id ?? this.id,
      name: name ?? this.name,
      processingBlocks: processingBlocks ?? this.processingBlocks,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'processingBlocks': processingBlocks.map((ProcessingBlockModel pb) => pb.toJson()).toList(),
  };

  factory SubZone.fromJson(Map<String, dynamic> json) => SubZone(
    id: json['id'] as String,
    name: json['name'] as String,
    processingBlocks: (json['processingBlocks'] as List<dynamic>).map((dynamic e) => ProcessingBlockModel.fromJson(e as Map<String, dynamic>)).toList(),
  );
}
