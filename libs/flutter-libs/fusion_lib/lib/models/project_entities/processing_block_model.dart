import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ProcessingBlockModel {
  /// Input processing blocks
  /// "agc","gate","compressor","ducker", "tone_control","peq","gain"
  ///
  /// Zones processing blocks
  /// "gate", "compressor", "tone_control", "graphic_eq", "feedback_elimination", "peq", "delay", "gain"
  ///
  /// Mixes processing blocks
  /// "agc", "gate", "compressor", "ducker", "tone_control", "peq", "gain"
  ///
  /// Output processing blocks
  /// "peq", "gain", "delay", "limiter"

  static final List<ProcessingBlockModel> sourceBlocks = <ProcessingBlockModel>[
    ProcessingBlockModel(
      id: 'delay',
      name: 'Delay',
      algorithmId: "delay",
    ),
    ProcessingBlockModel(
      id: 'agc',
      name: 'AGC',
      algorithmId: "agc",
    ),
    ProcessingBlockModel(
      id: 'compressor',
      name: 'Compressor',
      algorithmId: "compressor",
    ),
    ProcessingBlockModel(
      id: 'limiter',
      name: 'Limiter',
      algorithmId: "limiter",
    ),
    ProcessingBlockModel(
      id: 'gate',
      name: 'Gate',
      algorithmId: "gate",
    ),
    ProcessingBlockModel(
      id: 'graphic_eq',
      name: 'Graphic EQ',
      algorithmId: "graphic_eq",
    ),
    ProcessingBlockModel(
      id: 'peq',
      name: 'PEQ',
      algorithmId: "peq",
    ),
    ProcessingBlockModel(
      id: 'tone_control',
      name: 'Tone Control',
      algorithmId: "tone_control",
    ),
    ProcessingBlockModel(
      id: 'gain',
      name: 'Gain',
      algorithmId: "gain",
    ),
  ];

  static final List<ProcessingBlockModel> zoneBlocks = <ProcessingBlockModel>[
    ProcessingBlockModel(
      id: 'delay',
      name: 'Delay',
      algorithmId: "delay",
    ),
    ProcessingBlockModel(
      id: 'agc',
      name: 'AGC',
      algorithmId: "agc",
    ),
    ProcessingBlockModel(
      id: 'compressor',
      name: 'Compressor',
      algorithmId: "compressor",
    ),
    ProcessingBlockModel(
      id: 'limiter',
      name: 'Limiter',
      algorithmId: "limiter",
    ),
    ProcessingBlockModel(
      id: 'graphic_eq',
      name: 'Graphic EQ',
      algorithmId: "graphic_eq",
    ),
    ProcessingBlockModel(
      id: 'peq',
      name: 'PEQ',
      algorithmId: "peq",
    ),
    ProcessingBlockModel(
      id: 'tone_control',
      name: 'Tone Control',
      algorithmId: "tone_control",
    ),
    ProcessingBlockModel(
      id: 'gain',
      name: 'Gain',
      algorithmId: "gain",
    ),
  ];

  static final List<ProcessingBlockModel> mixBlocks = <ProcessingBlockModel>[
    ProcessingBlockModel(
      id: 'agc',
      name: 'AGC',
      algorithmId: "agc",
    ),
    ProcessingBlockModel(
      id: 'gate',
      name: 'Gate',
      algorithmId: "gate",
    ),
    ProcessingBlockModel(
      id: 'compressor',
      name: 'Compressor',
      algorithmId: "compressor",
    ),
    ProcessingBlockModel(
      id: 'ducker',
      name: 'Ducker',
      algorithmId: "ducker",
    ),
    ProcessingBlockModel(
      id: 'tone_control',
      name: 'Tone Control',
      algorithmId: "tone_control",
    ),
    ProcessingBlockModel(
      id: 'peq',
      name: 'PEQ',
      algorithmId: "peq",
    ),
    ProcessingBlockModel(
      id: 'gain',
      name: 'Gain',
      algorithmId: "gain",
    ),
  ];

  static final List<ProcessingBlockModel> circuitBlocks = <ProcessingBlockModel>[
    ProcessingBlockModel(
      id: 'delay',
      name: 'Delay',
      algorithmId: "delay",
    ),
    ProcessingBlockModel(
      id: 'compressor',
      name: 'Compressor',
      algorithmId: "compressor",
    ),
    ProcessingBlockModel(
      id: 'limiter',
      name: 'Limiter',
      algorithmId: "limiter",
    ),
    ProcessingBlockModel(
      id: 'graphic_eq',
      name: 'Graphic EQ',
      algorithmId: "graphic_eq",
    ),
    ProcessingBlockModel(
      id: 'peq',
      name: 'PEQ',
      algorithmId: "peq",
    ),
    ProcessingBlockModel(
      id: 'tone_control',
      name: 'Tone Control',
      algorithmId: "tone_control",
    ),
    ProcessingBlockModel(
      id: 'feedback_suppression',
      name: 'Feedback Suppression',
      algorithmId: "feedback_suppression",
    ),
    ProcessingBlockModel(
      id: 'gain',
      name: 'Gain',
      algorithmId: "gain",
    ),
  ];

  final String name;
  final String id;
  final String algorithmId;
  List<PropertySetting> properties;

  ProcessingBlockModel({
    required this.name,
    String? id,
    required this.algorithmId,
    List<PropertySetting>? properties,
  }) : properties = properties ?? <PropertySetting>[],
       id = id ?? "${algorithmId.toUpperCase().replaceAll('_', '')}${FusionUtils.shortStringUUID()}";

  IconData get icon {
    return _iconNameMap[algorithmId] ?? Icons.memory;
  }

  String get iconAsset {
    return "packages/fusion_lib/lib/${_algoIconMap[algorithmId] ?? 'assets/icons/processing_blocks/pb_1.png'}";
  }

  ProcessingBlockModel copyWith({String? name, String? id, String? algorithmId, List<PropertySetting>? properties}) {
    return ProcessingBlockModel(
      name: name ?? this.name,
      id: id ?? this.id,
      algorithmId: algorithmId ?? this.algorithmId,
      properties: properties ?? this.properties,
    );
  }

  ProcessingBlockModel updateProperties(List<PropertySetting> newProperties) {
    properties = newProperties;
    return this;
  }

  ProcessingBlockModel updateProperty(PropertySetting newProperty) {
    final int index = properties.indexWhere((PropertySetting p) => p.name == newProperty.name && p.dimension == newProperty.dimension);
    if (index != -1) {
      properties[index] = newProperty;
    } else {
      properties.add(newProperty);
    }
    return this;
  }

  ProcessingBlockModel clone() {
    return ProcessingBlockModel(
      name: name,
      algorithmId: algorithmId,
      properties: properties,
    );
  }

  ProcessingBlockModel copyProperties({required ProcessingBlockModel model}) {
    return ProcessingBlockModel(
      id: id,
      name: name,
      algorithmId: algorithmId,
      properties: model.properties,
    );
  }

  factory ProcessingBlockModel.fromJson(Map<String, dynamic> json) {
    return ProcessingBlockModel(
      name: json['name'] as String,
      id: json['id'] as String,
      algorithmId: json['algorithmId'] as String,
      properties: (json['properties'] != null && json['properties'] is List<dynamic>)
          ? (json['properties'] as List<dynamic>).map((dynamic e) => PropertySetting.fromJson(e as Map<String, dynamic>)).toList()
          : <PropertySetting>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'name': name, 'id': id, 'algorithmId': algorithmId, 'properties': properties.map((PropertySetting e) => e.toJson()).toList()};
  }

  /// Lookup table for JSON “iconName” (e.g. algorithmId) → const IconData
  static const Map<String, IconData> _iconNameMap = <String, IconData>{
    'gain': Icons.volume_up,
    'peq': Icons.equalizer,
    'compressor': Icons.compress,
    'ducker': Icons.volume_down,
    'agc': Icons.auto_fix_high,
    'gate': Icons.fence,
    'tone_control': Icons.tune,
    'graphic_eq': Icons.equalizer,
    'delay': Icons.timer,
    'limiter': Icons.stop,
  };

  /// Lookup table for JSON “iconName” (e.g. algorithmId) → const IconData
  static const Map<String, String> _algoIconMap = <String, String>{
    'gain': 'assets/icons/processing_blocks/pb_1.png',
    'peq': 'assets/icons/processing_blocks/pb_2.png',
    'compressor': 'assets/icons/processing_blocks/pb_3.png',
    'ducker': 'assets/icons/processing_blocks/pb_4.png',
    'agc': 'assets/icons/processing_blocks/pb_5.png',
    'gate': 'assets/icons/processing_blocks/pb_1.png',
    'tone_control': 'assets/icons/processing_blocks/pb_2.png',
    'graphic_eq': 'assets/icons/processing_blocks/pb_3.png',
    'delay': 'assets/icons/processing_blocks/pb_4.png',
    'limiter': 'assets/icons/processing_blocks/pb_5.png',
  };
}
