import 'dart:math';

import 'package:fusion_lib/fusion_lib.dart';

class SubZone {
  final String id;
  final String name;
  final List<ProcessingBlockModel> processingBlocks;
  final List<String> listeningAreasIds;
  final List<String> circuits;

  SubZone({
    String? id,
    required this.name,
    List<String>? listeningAreaIds,
    List<ProcessingBlockModel>? processingBlocks,
    this.circuits = const <String>[],
  }) : id = id ?? getShortId(),
       listeningAreasIds = listeningAreaIds ?? <String>[],
       processingBlocks = processingBlocks ?? <ProcessingBlockModel>[];

  static String getShortId() {
    return 'zone${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
  }

  SubZone copyWith({
    String? id,
    String? name,
    List<String>? listeningAreaIds,
    List<ProcessingBlockModel>? processingBlocks,
    List<String>? circuits,
  }) {
    return SubZone(
      id: id ?? this.id,
      name: name ?? this.name,
      listeningAreaIds: listeningAreaIds ?? listeningAreasIds,
      processingBlocks: processingBlocks ?? this.processingBlocks,
      circuits: circuits ?? this.circuits,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'listeningAreasId': listeningAreasIds,
    'processingBlocks': processingBlocks.map((ProcessingBlockModel pb) => pb.toJson()).toList(),
    'circuits': circuits,
  };

  factory SubZone.fromJson(Map<String, dynamic> json) => SubZone(
    id: json['id'] as String,
    name: json['name'] as String,
    listeningAreaIds: List<String>.from(json['listeningAreasId'] as List<dynamic>),
    processingBlocks: (json['processingBlocks'] as List<dynamic>).map((dynamic e) => ProcessingBlockModel.fromJson(e as Map<String, dynamic>)).toList(),
    circuits: List<String>.from(json['circuits'] as List<dynamic>? ?? <String>[]),
  );
}
