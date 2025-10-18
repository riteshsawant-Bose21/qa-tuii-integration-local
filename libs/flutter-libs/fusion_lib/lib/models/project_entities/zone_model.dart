import 'dart:math';
import 'dart:ui';

import '../../fusion_utils/fusion_utilities.dart';
import 'processing_block_model.dart';

class Zone {
  final String id;
  final String name;
  final List<ProcessingBlockModel> processingBlocks;
  final int selectedMixIndex;
  final String zoneColor;

  Zone({
    String? id,
    required this.name,
    List<ProcessingBlockModel>? processingBlocks,
    String? zoneColor,
    this.selectedMixIndex = 0,
  }) : id = id ?? "ZONE${FusionUtils.shortStringUUID()}",
       processingBlocks = processingBlocks ?? <ProcessingBlockModel>[],
       zoneColor = zoneColor ?? getRandomColor();

  static String getShortId() {
    return 'zone${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
  }

  Color get color {
    return Color(int.parse(zoneColor.substring(1, 7), radix: 16) + 0xFF000000);
  }

  static const List<String> zoneColors = <String>[
    '#FFEB3B', // Yellow
    '#F44336', // Red
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#795548', // Brown
    '#E91E63', // Pink
    '#CDDC39', // Lime
    '#3F51B5', // Indigo
    '#009688', // Teal
  ];

  static getRandomColor() {
    final Random random = Random();
    return zoneColors[random.nextInt(zoneColors.length)];
  }

  Zone copyWith({
    String? id,
    String? name,
    List<ProcessingBlockModel>? processingBlocks,
    int? selectedMixIndex,
    String? zoneColor,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      processingBlocks: processingBlocks ?? this.processingBlocks,
      selectedMixIndex: selectedMixIndex ?? this.selectedMixIndex,
      zoneColor: zoneColor ?? this.zoneColor,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'processingBlocks': processingBlocks.map((ProcessingBlockModel pb) => pb.toJson()).toList(),
    'selectedMixIndex': selectedMixIndex,
    'zoneColor': zoneColor,
  };

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
    id: json['id'] as String,
    name: json['name'] as String,
    processingBlocks: (json['processingBlocks'] as List<dynamic>).map((dynamic e) => ProcessingBlockModel.fromJson(e as Map<String, dynamic>)).toList(),
    selectedMixIndex: json['selectedMixIndex'] as int? ?? 0,
    zoneColor: json['zoneColor'] as String? ?? getRandomColor(),
  );
}
