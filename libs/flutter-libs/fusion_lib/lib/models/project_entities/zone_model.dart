import 'dart:math';
import 'dart:ui';

import '../../fusion_utils/fusion_utilities.dart';

class Zone {
  final String id;
  final String name;
  final int selectedMixIndex;
  final String zoneColor;
  final Offset? wiringPos;

  Zone({
    String? id,
    required this.name,
    String? zoneColor,
    this.selectedMixIndex = 0,
    this.wiringPos,
  }) : id = id ?? "ZONE${FusionUtils.shortStringUUID()}",
       zoneColor = zoneColor ?? getRandomColor();

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
    int? selectedMixIndex,
    String? zoneColor,
    Offset? wiringPos,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      selectedMixIndex: selectedMixIndex ?? this.selectedMixIndex,
      zoneColor: zoneColor ?? this.zoneColor,
      wiringPos: wiringPos ?? this.wiringPos,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'selectedMixIndex': selectedMixIndex,
    'zoneColor': zoneColor,
    'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
  };

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
    id: json['id'] as String,
    name: json['name'] as String,
    selectedMixIndex: json['selectedMixIndex'] as int? ?? 0,
    zoneColor: json['zoneColor'] as String? ?? getRandomColor(),
    wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['dx'] as num).toDouble(), (json['wiringPos']['dy'] as num).toDouble()) : null,
  );
}
