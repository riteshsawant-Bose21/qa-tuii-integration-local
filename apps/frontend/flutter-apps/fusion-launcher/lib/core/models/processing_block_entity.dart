import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/property_settings.dart';

class ProcessingBlockEntity {
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

  static final List<ProcessingBlockEntity> inputBlocks = <ProcessingBlockEntity>[
    ProcessingBlockEntity(
      id: 'gain',
      name: 'Gain',
      algorithmId: "gain",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'peq',
      name: 'PEQ',
      algorithmId: "peq",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
        PropertySetting(name: 'bands', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'compressor',
      name: 'Compressor',
      algorithmId: "compressor",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'ducker',
      name: 'Ducker',
      algorithmId: "ducker",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'agc',
      name: 'AGC',
      algorithmId: "agc",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'gate',
      name: 'Gate',
      algorithmId: "gate",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'tone_control',
      name: 'Tone Control',
      algorithmId: "tone_control",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
  ];

  static final List<ProcessingBlockEntity> zoneBlocks = <ProcessingBlockEntity>[
    ProcessingBlockEntity(
      id: 'gate',
      name: 'Gate',
      algorithmId: "gate",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'compressor',
      name: 'Compressor',
      algorithmId: "compressor",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'tone_control',
      name: 'Tone Control',
      algorithmId: "tone_control",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'graphic_eq',
      name: 'Graphic EQ',
      algorithmId: "graphic_eq",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    // ProcessingBlockEntity(
    //   id: 'feedback_elimination',
    //   name: 'Feedback Elimination',
    //   icon: Icons.hearing,
    //   algorithmId: "feedback_elimination",
    //   properties: <PropertySetting>[
    //     PropertySetting(name: 'channels', value: 1),
    //   ],
    // ),
    ProcessingBlockEntity(
      id: 'peq',
      name: 'PEQ',
      algorithmId: "peq",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
        PropertySetting(name: 'bands', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'delay',
      name: 'Delay',
      algorithmId: "delay",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
        PropertySetting(name: 'max_delay', value: 4800),
      ],
    ),
    ProcessingBlockEntity(
      id: 'gain',
      name: 'Gain',
      algorithmId: "gain",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
  ];

  static final List<ProcessingBlockEntity> mixBlocks = <ProcessingBlockEntity>[
    ProcessingBlockEntity(
      id: 'agc',
      name: 'AGC',
      algorithmId: "agc",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'gate',
      name: 'Gate',
      algorithmId: "gate",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'compressor',
      name: 'Compressor',
      algorithmId: "compressor",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'ducker',
      name: 'Ducker',
      algorithmId: "ducker",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'tone_control',
      name: 'Tone Control',
      algorithmId: "tone_control",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'peq',
      name: 'PEQ',
      algorithmId: "peq",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
        PropertySetting(name: 'bands', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'gain',
      name: 'Gain',
      algorithmId: "gain",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
  ];

  static final List<ProcessingBlockEntity> outputBlocks = <ProcessingBlockEntity>[
    ProcessingBlockEntity(
      id: 'peq',
      name: 'PEQ',
      algorithmId: "peq",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
        PropertySetting(name: 'bands', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'gain',
      name: 'Gain',
      algorithmId: "gain",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
      ],
    ),
    ProcessingBlockEntity(
      id: 'delay',
      name: 'Delay',
      algorithmId: "delay",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
        PropertySetting(name: 'max_delay', value: 4800),
      ],
    ),
    ProcessingBlockEntity(
      id: 'limiter',
      name: 'Limiter',
      algorithmId: "limiter",
      properties: <PropertySetting>[
        PropertySetting(name: 'channels', value: 1),
        PropertySetting(name: 'max_delay', value: 4800),
      ],
    ),
  ];

  final String name;
  final String id;
  final String algorithmId;
  List<PropertySetting> properties;

  ProcessingBlockEntity({
    required this.name,
    required this.id,
    required this.algorithmId,
    List<PropertySetting>? properties,
  }) : properties = properties ?? <PropertySetting>[];

  IconData get icon {
    return _iconNameMap[algorithmId] ?? Icons.memory;
  }

  copyWith({
    String? name,
    String? id,
    String? algorithmId,
    List<PropertySetting>? properties,
  }) {
    return ProcessingBlockEntity(
      name: name ?? this.name,
      id: id ?? this.id,
      algorithmId: algorithmId ?? this.algorithmId,
      properties: properties ?? this.properties,
    );
  }

  factory ProcessingBlockEntity.fromJson(Map<String, dynamic> json) {
    return ProcessingBlockEntity(
      name: json['name'] as String,
      id: json['id'] as String,
      algorithmId: json['algorithmId'] as String,
      properties:
          (json['properties'] != null && json['properties'] is List<dynamic>)
              ? (json['properties'] as List<dynamic>).map((dynamic e) => PropertySetting.fromJson(e as Map<String, dynamic>)).toList()
              : <PropertySetting>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'id': id,
      'algorithmId': algorithmId,
      'properties': properties.map((PropertySetting e) => e.toJson()).toList(),
    };
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
}
